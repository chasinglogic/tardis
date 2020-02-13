public class Tardis.Widgets.BackupInProgress : Gtk.Box {
    public Gtk.Label title_label;
    public Gtk.Spinner spinner;
    public Gtk.Grid content;

    // TODO show per-target backup progress using spinners and process-completed
    // icons. Requires changes to Backups.vala to emit those signals

    public BackupInProgress (string title, bool? use_spinner = true) {
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        title_label = new Gtk.Label (title);
        title_label.justify = Gtk.Justification.CENTER;
        title_label.hexpand = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);

        content = new Gtk.Grid ();
        content.expand = true;
        content.row_spacing = 12;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.valign = Gtk.Align.CENTER;
        content.add (title_label);

        if (use_spinner) {
            spinner = new Gtk.Spinner ();
            spinner.set_size_request(64, 64);
            content.add (spinner);
        }

        add (content);
    }
}
