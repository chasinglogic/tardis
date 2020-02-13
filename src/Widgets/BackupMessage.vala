public class Tardis.Widgets.BackupMessage : Gtk.Box {
    private Gtk.Label title_label;
    private Gtk.Label subtitle_label;

    public BackupMessage (string title, string subtitle) {
        title_label = new Gtk.Label (title);
        title_label.justify = Gtk.Justification.CENTER;
        title_label.hexpand = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);

        subtitle_label = new Gtk.Label (subtitle);
        subtitle_label.justify = Gtk.Justification.CENTER;
        subtitle_label.hexpand = true;
        subtitle_label.wrap = true;
        subtitle_label.wrap_mode = Pango.WrapMode.WORD;

        var subtitle_label_context = subtitle_label.get_style_context ();
        subtitle_label_context.add_class (Gtk.STYLE_CLASS_DIM_LABEL);
        subtitle_label_context.add_class (Granite.STYLE_CLASS_H2_LABEL);

        orientation = Gtk.Orientation.VERTICAL;
        add (title_label);
        add (subtitle_label);
    }
}
