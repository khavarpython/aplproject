#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Global widgets & state
GtkTextBuffer *source_buf;
GtkTextBuffer *output_buf;
GtkWidget *statusbar;
GtkWidget *run_btn;
GtkWidget *clear_btn;
GtkWidget *line_col_label;
guint statusbar_ctx;
GtkTextBuffer *ai_buf;
// CSS theme
static const char *APP_CSS =
    /* Window & overall background */
    "window {"
    "  background-color: #1a1b26;"
    "}"

    // Top toolbar
    "#toolbar {"
    "  background-color: #16161e;"
    "  border-bottom: 1px solid #2a2b3d;"
    "  padding: 6px 10px;"
    "}"

    // Title label in toolbar
    "#app-title {"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 13px;"
    "  font-weight: bold;"
    "  color: #7aa2f7;"
    "  letter-spacing: 2px;"
    "}"

    // Run button
    "#run-btn {"
    "  background-color: #7aa2f7;"
    "  color: #1a1b26;"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 12px;"
    "  font-weight: bold;"
    "  border-radius: 4px;"
    "  border: none;"
    "  padding: 5px 18px;"
    "  letter-spacing: 1px;"
    "}"
    "#run-btn:hover { background-color: #89b4fa; }"
    "#run-btn:active { background-color: #5a82d7; }"

    // Clear output button
    "#clear-btn {"
    "  background-color: transparent;"
    "  color: #565f89;"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 12px;"
    "  border-radius: 4px;"
    "  border: 1px solid #2a2b3d;"
    "  padding: 5px 14px;"
    "}"
    "#clear-btn:hover { color: #f7768e; border-color: #f7768e; }"

    // Pane labels
    "#pane-label {"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 10px;"
    "  color: #565f89;"
    "  letter-spacing: 2px;"
    "  padding: 4px 8px;"
    "  background-color: #16161e;"
    "  border-bottom: 1px solid #2a2b3d;"
    "}"

    // Code editor
    "#editor {"
    "  font-family: 'Iosevka', 'JetBrains Mono', 'Fira Code', monospace;"
    "  font-size: 14px;"
    "  color: #c0caf5;"
    "  background-color: #1a1b26;"
    "  caret-color: #7aa2f7;"
    "  padding: 10px;"
    "}"

    // Output view
    "#output {"
    "  font-family: 'Iosevka', 'JetBrains Mono', 'Fira Code', monospace;"
    "  font-size: 13px;"
    "  color: #9ece6a;"
    "  background-color: #16161e;"
    "  padding: 10px;"
    "}"

    // Separator
    "separator {"
    "  background-color: #2a2b3d;"
    "  min-height: 2px;"
    "}"

    // Scrolled windows – remove ugly default borders
    "scrolledwindow {"
    "  border: none;"
    "}"

    // Divider / paned handle
    "paned > separator {"
    "  background-color: #2a2b3d;"
    "  min-width: 3px;"
    "  min-height: 3px;"
    "}"

    // Status bar
    "#statusbar {"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 11px;"
    "  color: #565f89;"
    "  background-color: #16161e;"
    "  border-top: 1px solid #2a2b3d;"
    "  padding: 2px 8px;"
    "}"

    // Line/col indicator
    "#line-col {"
    "  font-family: 'Iosevka', 'JetBrains Mono', monospace;"
    "  font-size: 11px;"
    "  color: #565f89;"
    "  padding: 2px 10px;"
    "}";

// Helpers

static void append_output(const char *text)
{
    GtkTextIter end;
    gtk_text_buffer_get_end_iter(output_buf, &end);
    gtk_text_buffer_insert(output_buf, &end, text, -1);
}

static void set_status(const char *msg)
{
    gtk_statusbar_pop(GTK_STATUSBAR(statusbar), statusbar_ctx);
    gtk_statusbar_push(GTK_STATUSBAR(statusbar), statusbar_ctx, msg);
}

// Update Ln / Col display when cursor moves
static void update_cursor_pos(GtkTextBuffer *buf, gpointer data)
{
    GtkTextMark *mark = gtk_text_buffer_get_insert(buf);
    GtkTextIter iter;
    gtk_text_buffer_get_iter_at_mark(buf, &iter, mark);

    int line = gtk_text_iter_get_line(&iter) + 1;
    int col = gtk_text_iter_get_line_offset(&iter) + 1;

    char tmp[64];
    snprintf(tmp, sizeof(tmp), "Ln %d, Col %d", line, col);
    gtk_label_set_text(GTK_LABEL(line_col_label), tmp);
}

// Run action
static void run_code(GtkButton *btn, gpointer data)
{
    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(source_buf, &start, &end);
    gchar *code = gtk_text_buffer_get_text(source_buf, &start, &end, FALSE);

    // Save to temp file
    FILE *f = fopen("input.apl", "w");
    if (!f)
    {
        append_output("Error: Cannot write input.apl\n");
        set_status("Error: file write failed");
        g_free(code);
        return;
    }
    fputs(code, f);
    fclose(f);
    g_free(code);

    // Clear previous output
    gtk_text_buffer_set_text(output_buf, "", -1);
    set_status("Running…");

    append_output("▶  Running…\n");

    // Execute
    FILE *pipe = popen("./run.sh input.apl 2>&1", "r");
    if (!pipe)
    {
        append_output("Error: Could not launch run.sh\n");
        set_status("Error: popen failed");
        return;
    }
    char buf[512];
    gboolean in_ai = FALSE;
    while (fgets(buf, sizeof(buf), pipe))
    {
        if (strncmp(buf, "~~SPLIT~~", 9) == 0)
        {
            in_ai = TRUE;
            continue;
        }

        if (in_ai)
        {
            GtkTextIter iter;
            gtk_text_buffer_get_end_iter(ai_buf, &iter);
            gtk_text_buffer_insert(ai_buf, &iter, buf, -1);
        }
        else
        {
            append_output(buf);
        }
    }

    int exit_code = pclose(pipe);
    char status_msg[64];
    if (exit_code == 0)
    {
        append_output("\n✓  Done.");
        snprintf(status_msg, sizeof(status_msg), "Finished (exit 0)");
    }
    else
    {
        append_output("\n✗  Exited with errors.\n");
        snprintf(status_msg, sizeof(status_msg), "Exited (%d)", exit_code);
    }
    set_status(status_msg);
}

// Clear output

static void clear_output(GtkButton *btn, gpointer data)
{
    gtk_text_buffer_set_text(output_buf, "", -1);
    gtk_text_buffer_set_text(ai_buf, "", -1);
    set_status("Output cleared");
}

// Build GUI

static void activate(GtkApplication *app, gpointer user_data)
{

    // Apply CSS
    GtkCssProvider *css = gtk_css_provider_new();
    gtk_css_provider_load_from_data(css, APP_CSS, -1, NULL);
    gtk_style_context_add_provider_for_screen(
        gdk_screen_get_default(),
        GTK_STYLE_PROVIDER(css),
        GTK_STYLE_PROVIDER_PRIORITY_APPLICATION);

    // Window
    GtkWidget *window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "APL IDE");
    gtk_window_set_default_size(GTK_WINDOW(window), 1000, 680);

    GtkWidget *root_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);
    gtk_container_add(GTK_CONTAINER(window), root_vbox);

    // Toolbar
    GtkWidget *toolbar = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 8);
    gtk_widget_set_name(toolbar, "toolbar");
    gtk_box_pack_start(GTK_BOX(root_vbox), toolbar, FALSE, FALSE, 0);

    GtkWidget *title_lbl = gtk_label_new("APL IDE");
    gtk_widget_set_name(title_lbl, "app-title");
    gtk_box_pack_start(GTK_BOX(toolbar), title_lbl, FALSE, FALSE, 4);

    // Spacer
    GtkWidget *spacer = gtk_label_new("");
    gtk_box_pack_start(GTK_BOX(toolbar), spacer, TRUE, TRUE, 0);

    clear_btn = gtk_button_new_with_label("Clear Output");
    gtk_widget_set_name(clear_btn, "clear-btn");
    g_signal_connect(clear_btn, "clicked", G_CALLBACK(clear_output), NULL);
    gtk_box_pack_start(GTK_BOX(toolbar), clear_btn, FALSE, FALSE, 0);

    run_btn = gtk_button_new_with_label("▶  RUN");
    gtk_widget_set_name(run_btn, "run-btn");
    g_signal_connect(run_btn, "clicked", G_CALLBACK(run_code), NULL);
    gtk_box_pack_start(GTK_BOX(toolbar), run_btn, FALSE, FALSE, 0);

    // Vertical paned (editor on top, output on bottom)
    GtkWidget *paned = gtk_paned_new(GTK_ORIENTATION_VERTICAL);
    gtk_box_pack_start(GTK_BOX(root_vbox), paned, TRUE, TRUE, 0);

    // Editor pane
    GtkWidget *editor_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);

    GtkWidget *editor_label = gtk_label_new("EDITOR");
    gtk_widget_set_name(editor_label, "pane-label");
    gtk_label_set_xalign(GTK_LABEL(editor_label), 0.0);
    gtk_box_pack_start(GTK_BOX(editor_vbox), editor_label, FALSE, FALSE, 0);

    GtkWidget *editor = gtk_text_view_new();
    gtk_widget_set_name(editor, "editor");
    gtk_text_view_set_left_margin(GTK_TEXT_VIEW(editor), 8);
    gtk_text_view_set_right_margin(GTK_TEXT_VIEW(editor), 8);
    gtk_text_view_set_top_margin(GTK_TEXT_VIEW(editor), 8);
    gtk_text_view_set_bottom_margin(GTK_TEXT_VIEW(editor), 8);
    source_buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(editor));

    // Track cursor position
    g_signal_connect(source_buf, "mark-set",
                     G_CALLBACK(update_cursor_pos), NULL);

    GtkWidget *scroll1 = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll1),
                                   GTK_POLICY_AUTOMATIC,
                                   GTK_POLICY_AUTOMATIC);
    gtk_container_add(GTK_CONTAINER(scroll1), editor);
    gtk_box_pack_start(GTK_BOX(editor_vbox), scroll1, TRUE, TRUE, 0);

    gtk_paned_pack1(GTK_PANED(paned), editor_vbox, TRUE, FALSE);

    // Output pane
    GtkWidget *output_vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 0);

    GtkWidget *output_label = gtk_label_new("OUTPUT");
    gtk_widget_set_name(output_label, "pane-label");
    gtk_label_set_xalign(GTK_LABEL(output_label), 0.0);
    gtk_box_pack_start(GTK_BOX(output_vbox), output_label, FALSE, FALSE, 0);

    // Parser output
    GtkWidget *output = gtk_text_view_new();
    gtk_widget_set_name(output, "output");
    gtk_text_view_set_editable(GTK_TEXT_VIEW(output), FALSE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(output), FALSE);
    gtk_text_view_set_left_margin(GTK_TEXT_VIEW(output), 8);
    gtk_text_view_set_right_margin(GTK_TEXT_VIEW(output), 8);
    gtk_text_view_set_top_margin(GTK_TEXT_VIEW(output), 8);
    gtk_text_view_set_bottom_margin(GTK_TEXT_VIEW(output), 8);
    output_buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(output));

    GtkWidget *scroll2 = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll2),
                                   GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    gtk_container_add(GTK_CONTAINER(scroll2), output);
    gtk_box_pack_start(GTK_BOX(output_vbox), scroll2, TRUE, TRUE, 0);

    // Separator
    GtkWidget *hsep = gtk_separator_new(GTK_ORIENTATION_HORIZONTAL);
    gtk_box_pack_start(GTK_BOX(output_vbox), hsep, FALSE, FALSE, 0);

    // AI label
    GtkWidget *ai_label = gtk_label_new("AI");
    gtk_widget_set_name(ai_label, "pane-label");
    gtk_label_set_xalign(GTK_LABEL(ai_label), 0.0);
    gtk_box_pack_start(GTK_BOX(output_vbox), ai_label, FALSE, FALSE, 0);

    // AI output
    GtkWidget *ai_output = gtk_text_view_new();
    gtk_widget_set_name(ai_output, "output");
    gtk_text_view_set_editable(GTK_TEXT_VIEW(ai_output), FALSE);
    gtk_text_view_set_cursor_visible(GTK_TEXT_VIEW(ai_output), FALSE);
    gtk_text_view_set_left_margin(GTK_TEXT_VIEW(ai_output), 8);
    gtk_text_view_set_right_margin(GTK_TEXT_VIEW(ai_output), 8);
    gtk_text_view_set_top_margin(GTK_TEXT_VIEW(ai_output), 8);
    gtk_text_view_set_bottom_margin(GTK_TEXT_VIEW(ai_output), 8);
    ai_buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(ai_output));

    GtkWidget *scroll3 = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scroll3),
                                   GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    gtk_container_add(GTK_CONTAINER(scroll3), ai_output);
    gtk_box_pack_start(GTK_BOX(output_vbox), scroll3, TRUE, TRUE, 0);

    gtk_paned_pack2(GTK_PANED(paned), output_vbox, TRUE, FALSE);

    // Set initial divider position (60 / 40 split)
    gtk_paned_set_position(GTK_PANED(paned), 420);

    // Status bar
    GtkWidget *status_hbox = gtk_box_new(GTK_ORIENTATION_HORIZONTAL, 0);
    gtk_widget_set_name(status_hbox, "statusbar");
    gtk_box_pack_start(GTK_BOX(root_vbox), status_hbox, FALSE, FALSE, 0);

    statusbar = gtk_statusbar_new();
    gtk_widget_set_name(statusbar, "statusbar");
    gtk_widget_set_hexpand(statusbar, TRUE);
    statusbar_ctx = gtk_statusbar_get_context_id(GTK_STATUSBAR(statusbar), "main");
    gtk_box_pack_start(GTK_BOX(status_hbox), statusbar, TRUE, TRUE, 0);
    set_status("Ready");

    line_col_label = gtk_label_new("Ln 1, Col 1");
    gtk_widget_set_name(line_col_label, "line-col");
    gtk_box_pack_end(GTK_BOX(status_hbox), line_col_label, FALSE, FALSE, 0);

    gtk_widget_show_all(window);
}

// Main

int main(int argc, char **argv)
{
    GtkApplication *app =
        gtk_application_new("com.apl.ide", G_APPLICATION_FLAGS_NONE);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);
    int status = g_application_run(G_APPLICATION(app), argc, argv);
    g_object_unref(app);
    return status;
}
