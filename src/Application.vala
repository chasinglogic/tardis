using Gtk;

public class Tardis.App : Gtk.Application {

    public static string id = "com.github.chasinglogic.tardis";
    public static int default_window_height = 600;
    public static int default_window_width = 850;

    // GLib settings accessor
    public GLib.Settings settings;
    public GLib.VolumeMonitor volume_monitor;

    public Tardis.Backups backups;

    // Custom Widgets
    public Tardis.Widgets.BackupStatus backup_status;
    public Tardis.Widgets.HeaderBar headerbar;

    // Main ApplicationWindow, is static so it can be referenced by
    // Dialogs.
    public static Gtk.ApplicationWindow window;

    // Widgets directly attached to the Application Window
    public Gtk.Box header_box;
    public Gtk.Stack status_box;
    public Gtk.Label title;

    public App () {
        Object (
            application_id: id,
            flags: ApplicationFlags.FLAGS_NONE
            );
    }

    public void set_backup_status(Gtk.Widget new_status) {
        status_box.set_visible_child(new_status);
    }

    // Store window size in gsettings when resized.
    public void on_resize () {
        if (!window.is_maximized) {
            int width;
            int height;
            window.get_size (out width, out height);
            if (settings.get_int("window-height") != height || settings.get_int("window-width") != width) {
                settings.set_int("window-height", height);
                settings.set_int("window-width", width);
            }
        }

        settings.set_boolean("window-maximized", window.is_maximized);
    }

    protected override void activate () {
        settings = new GLib.Settings (id);

        // TODO (chasinglogic): Listen for drive connected and
        // disconnected signals to notify user of possible new backup
        // drives, and disconnect of known backup drives.
        volume_monitor = GLib.VolumeMonitor.@get ();

        // Construct the main window for our Application.
        window = new Gtk.ApplicationWindow (this);
        if (settings.get_boolean("first-run")) {
            settings.set_int("window-width", default_window_width);
            settings.set_int("window-height", default_window_height);
        }

        if (settings.get_boolean("window-maximized")) {
            window.maximize ();
        } else {
            window.default_width = settings.get_int("window-width");
            window.default_height = settings.get_int("window-height");
        }

        status_box = new Gtk.Stack ();

        backups = new Tardis.Backups (volume_monitor, settings);

        backup_status = new Tardis.Widgets.BackupStatus (this,
                                                         settings,
                                                         backups);

        window.add (status_box);
        backup_status.get_backup_status.begin ();

        volume_monitor.volume_added.connect(() => backup_status.get_backup_status.begin ());
        volume_monitor.volume_removed.connect(() => backup_status.get_backup_status.begin ());

        // HeaderBar
        headerbar = new Tardis.Widgets.HeaderBar (settings, backup_status, backups);
        window.set_titlebar (headerbar);

        window.show_all ();
        window.size_allocate.connect (() => { on_resize (); });
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
        var return_code = app.run (args);
        app.settings.set_boolean ("first-run", false);
        return return_code;
    }
}
