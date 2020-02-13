public class Tardis.Widgets.MainView : Gtk.Box {
    public Gtk.Grid content;
    public Gtk.Grid drive_window_content;
    public Gtk.ScrolledWindow drive_window;
    private Tardis.BackupTargetManager target_manager;

    public MainView (Gtk.Widget message_area, Tardis.BackupTargetManager target_manager, GLib.Settings settings) {
        this.target_manager = target_manager;

        orientation = Gtk.Orientation.VERTICAL;

        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        get_style_context ().add_class (Granite.STYLE_CLASS_WELCOME);

        content = new Gtk.Grid ();
        content.expand = true;
        content.margin = 12;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.valign = Gtk.Align.CENTER;
        content.add (message_area);

        var separator = new Gtk.Separator(Gtk.Orientation.HORIZONTAL);
        content.add (separator);

        drive_window = new Gtk.ScrolledWindow (null, null);
        drive_window.margin = 12;
        var half_height = settings.get_int("window-width") / 2;
        var half_width = settings.get_int("window-width") / 2;
        drive_window.max_content_width = half_width;
        drive_window.min_content_width = half_width;
        drive_window.max_content_height = half_height;
        drive_window.min_content_height = half_height;

        drive_window_content = new Gtk.Grid ();
        drive_window_content.expand = true;
        drive_window_content.margin = 12;
        drive_window_content.orientation = Gtk.Orientation.VERTICAL;

        list_targets ();

        drive_window.add(drive_window_content);
        content.add (drive_window);
        add (content);
    }

    public signal void drive_removed (BackupTarget target);
    public signal void restore_from (BackupTarget target);

    public void list_targets () {
        drive_window_content.@foreach((child) => child.destroy ());

        foreach (BackupTarget target in target_manager.get_targets ()) {
            var drive_status = new Tardis.Widgets.DriveStatus (target);
            drive_status.drive_removed.connect ((target) => drive_removed(target));
            drive_status.restore_from.connect ((target) => restore_from(target));
            drive_window_content.add (drive_status);
        }

        drive_window_content.show_all ();
    }

    public void set_status (string id, DriveStatusType status) {
        drive_window_content.@foreach((child) => {
            var status_widget = (Tardis.Widgets.DriveStatus) child;
            if (status_widget.target.id == id) {
                status_widget.set_status (status);
            }
        });
    }
}
