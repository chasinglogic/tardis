public class Tardis.Widgets.BackupMessage : Gtk.Box {
    public Gtk.Image icon;
    public Gtk.Label title_label;
    public Gtk.Label subtitle_label;
    public Gtk.Grid content;


    public BackupMessage (string title, string subtitle, string icon_name) {
        orientation = Gtk.Orientation.VERTICAL;

        icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon (icon_name);
        icon.pixel_size = 64;

        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

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

        content = new Gtk.Grid ();
        content.expand = true;
        content.margin = 12;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.valign = Gtk.Align.CENTER;
        content.add (icon);
        content.add (title_label);
        content.add (subtitle_label);

        add (content);
    }
}
