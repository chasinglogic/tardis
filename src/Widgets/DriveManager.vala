public class Tardis.Widgets.DriveManager : Gtk.Grid {
    private GLib.VolumeMonitor volume_monitor;
    private GLib.Settings settings;

    public Gtk.Label title_label;
    public Gtk.Grid content;

    public DriveManager(GLib.VolumeMonitor volume_monitor, GLib.Settings settings) {
        this.volume_monitor = volume_monitor;
        this.settings = settings;

        orientation = Gtk.Orientation.VERTICAL;
        expand = true;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        title_label = new Gtk.Label ("<b>Backup Drives</b>");
        title_label.margin = 12;
        title_label.halign = Gtk.Align.CENTER;
        title_label.hexpand = true;
        title_label.use_markup = true;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);

        add (title_label);

        content = new Gtk.Grid ();
        content.orientation = Gtk.Orientation.VERTICAL;
        add (content);

        reload_drive_list ();
    }

    public void reload_drive_list () {
        content.@foreach ((child) => {
            content.remove (child);
        });

        foreach (string target in settings.get_strv("backup-targets")) {
            var display = new Tardis.Widgets.DriveDisplay (volume_monitor, settings, target);
            display.deleted.connect(() => drive_removed ());
            content.add (display);
        }

        content.show_all ();
    }

    public signal void drive_removed ();
}
