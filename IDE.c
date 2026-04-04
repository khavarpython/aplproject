#include <gtk/gtk.h>
#include <stdio.h>
#include <stdlib.h>

GtkTextBuffer *source_buf;
GtkTextBuffer *output_buf;

/* Append text to output */
void append_output(const char *text)
{
    GtkTextIter end;
    gtk_text_buffer_get_end_iter(output_buf, &end);
    gtk_text_buffer_insert(output_buf, &end, text, -1);
}

/* Run compiler using run.sh */
void run_code(GtkButton *btn, gpointer data)
{

    GtkTextIter start, end;
    gtk_text_buffer_get_bounds(source_buf, &start, &end);

    gchar *code = gtk_text_buffer_get_text(source_buf, &start, &end, FALSE);

    /* Save code to file */
    FILE *f = fopen("input.apl", "w");
    if (!f)
    {
        append_output("Error: Cannot write file\n");
        return;
    }

    fputs(code, f);
    fclose(f);
    g_free(code);

    /* Clear output */
    gtk_text_buffer_set_text(output_buf, "", -1);

    append_output("Running...\n\n");

    /* Run script */
    FILE *pipe = popen("./run.sh < input.apl", "r");

    if (!pipe)
    {
        append_output("Error running script\n");
        return;
    }

    char buffer[512];

    while (fgets(buffer, sizeof(buffer), pipe))
    {
        append_output(buffer);
    }

    pclose(pipe);
}

/* Build GUI */
void activate(GtkApplication *app, gpointer user_data)
{

    GtkWidget *window = gtk_application_window_new(app);
    gtk_window_set_title(GTK_WINDOW(window), "APL IDE");
    gtk_window_set_default_size(GTK_WINDOW(window), 900, 600);

    GtkWidget *vbox = gtk_box_new(GTK_ORIENTATION_VERTICAL, 5);
    gtk_container_add(GTK_CONTAINER(window), vbox);

    /* Editor */
    GtkWidget *editor = gtk_text_view_new();
    source_buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(editor));

    GtkWidget *scroll1 = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scroll1), editor);
    gtk_box_pack_start(GTK_BOX(vbox), scroll1, TRUE, TRUE, 0);

    /* Run button */
    GtkWidget *run_btn = gtk_button_new_with_label("Run");
    g_signal_connect(run_btn, "clicked", G_CALLBACK(run_code), NULL);
    gtk_box_pack_start(GTK_BOX(vbox), run_btn, FALSE, FALSE, 5);

    /* Output */
    GtkWidget *output = gtk_text_view_new();
    output_buf = gtk_text_view_get_buffer(GTK_TEXT_VIEW(output));
    gtk_text_view_set_editable(GTK_TEXT_VIEW(output), FALSE);

    GtkWidget *scroll2 = gtk_scrolled_window_new(NULL, NULL);
    gtk_container_add(GTK_CONTAINER(scroll2), output);
    gtk_box_pack_start(GTK_BOX(vbox), scroll2, TRUE, TRUE, 0);

    gtk_widget_show_all(window);
}

/* Main */
int main(int argc, char **argv)
{

    GtkApplication *app;
    int status;

    app = gtk_application_new("com.apl.ide", G_APPLICATION_FLAGS_NONE);
    g_signal_connect(app, "activate", G_CALLBACK(activate), NULL);

    status = g_application_run(G_APPLICATION(app), argc, argv);

    g_object_unref(app);
    return status;
}