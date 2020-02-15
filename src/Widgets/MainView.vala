public class Tardis.Widgets.MainView : Gtk.Box {
    private Gtk.Grid content;
    private Gtk.ListBox drive_window_content;
    private Gtk.ScrolledWindow drive_window;

    private Tardis.BackupTargetManager target_manager;

    public MainView (Tardis.BackupTargetManager target_manager) {
        this.target_manager = target_manager;

        var title_label = new Gtk.Label ("Backups");
        title_label.margin = 12;
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H1_LABEL);

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        drive_window_content = new Gtk.ListBox ();
        drive_window_content.expand = true;
        drive_window_content.margin = 12;
        // drive_window_content.orientation = Gtk.Orientation.VERTICAL;

        foreach (BackupTarget target in target_manager.get_targets ()) {
            add_target (target);
        }

        drive_window = new Gtk.ScrolledWindow (null, null);
        drive_window.add (drive_window_content);

        content = new Gtk.Grid ();
        content.expand = true;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.add (title_label);
        content.add (separator);
        content.add (drive_window);

        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        add (content);
    }

    public void add_target (BackupTarget target) {
        var drive_status = new Tardis.Widgets.DriveStatus (target);
        drive_status.drive_removed.connect ((target) => drive_removed (target));
        drive_status.restore_from.connect ((target) => restore_from (target));
        drive_window_content.add (drive_status);
        drive_window_content.show_all ();
    }

    public void set_all (DriveStatusType status) {
        drive_window_content.@foreach ((child) => {
            var status_widget = (Tardis.Widgets.DriveStatus) child;
            status_widget.set_status (status);
        });
    }

    public void set_status (string id, DriveStatusType status) {
        drive_window_content.@foreach ((child) => {
            var status_widget = (Tardis.Widgets.DriveStatus) child;
            if (status_widget.target.id == id) {
                status_widget.set_status (status);
            }
        });
    }

    public signal void drive_removed (BackupTarget target);
    public signal void restore_from (BackupTarget target);
}
