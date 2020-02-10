using Gtk;

public class Tardis.App : Gtk.Application {

    public static string id = "com.github.chasinglogic.tardis";
    public static GLib.ThemedIcon backup_in_progress_icon = new GLib.ThemedIcon ("emblem-synchronizing");
    public static GLib.ThemedIcon backup_completed_icon = new GLib.ThemedIcon ("emblem-synchronized");

    // GLib settings accessor
    public Tardis.Settings settings;
    public GLib.VolumeMonitor volume_monitor;

    // Custom Widgets
    public Tardis.Widgets.BackupStatus backup_status;

    // Main ApplicationWindow, is static so it can be referenced by
    // Dialogs.
    public static Gtk.ApplicationWindow window;

    // Widgets directly attached to the Application Window
    public Gtk.HeaderBar headerbar;
    public Gtk.Box header_box;

    public Gtk.Stack status_box;
    public Gtk.Label title;

    public Granite.Widgets.ModeButton mode_button;

    // Public References
    private int drives_view_id;
    private int status_view_id;

    public App () {
        Object (
            application_id: "com.github.chasinglogic.tardis",
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
            if (settings.window_height != height || settings.window_width != width) {
                settings.window_height = height;
                settings.window_width = width;
            }
        }

        settings.window_maximized = window.is_maximized;
    }

    protected override void activate () {
        settings = Tardis.Settings.get_instance ();
        // TODO (chasinglogic): Listen for drive connected and
        // disconnected signals to notify user of possible new backup
        // drives, and disconnect of known backup drives.
        volume_monitor = GLib.VolumeMonitor.@get ();
        // Construct the main window for our Application.
        window = new Gtk.ApplicationWindow (this);

        // HeaderBar
        headerbar = new Gtk.HeaderBar ();
        headerbar.show_close_button = true;

        title = new Gtk.Label("Tardis");

        headerbar.set_custom_title (title);

        window.set_titlebar (headerbar);

        if (settings.window_maximized) {
            window.maximize ();
        } else if (settings.first_run) {
			window.default_width = 800;
			window.default_height = 800;
			settings.window_width = 800;
			settings.window_height = 800;
		} else {
            window.default_width = settings.window_width;
            window.default_height = settings.window_height;
        }

        status_box = new Gtk.Stack ();
        backup_status = new Tardis.Widgets.BackupStatus (this,
                                                         volume_monitor,
                                                         settings);

        window.add (status_box);
        backup_status.get_backup_status.begin ();

        window.show_all ();


        window.size_allocate.connect (() => { on_resize (); });
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
        return app.run (args);
    }
}
