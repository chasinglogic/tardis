using Gtk;

public class Tardis.App : Gtk.Application {

    public static string id = "com.github.chasinglogic.tardis";
    public static int default_window_height = 600;
    public static int default_window_width = 850;

    // GLib settings accessor
    public GLib.Settings settings;
    public GLib.VolumeMonitor volume_monitor;

    public Tardis.Backups backups;
    public Tardis.Widgets.DriveManager drive_manager;

    // Custom Widgets
    public Tardis.Widgets.BackupStatus backup_status;
    public Tardis.Widgets.HeaderBar headerbar;

    // Main ApplicationWindow, is static so it can be referenced by
    // Dialogs.
    public static Gtk.ApplicationWindow window;

    // Widgets directly attached to the Application Window
    public Gtk.Stack main_stack;
    public Gtk.Stack status_stack;
    public Gtk.Label title;
    public Granite.Widgets.ModeButton view_mode;

    public int drive_manager_id;
    public int backup_status_id;

    public App () {
        Object (
            application_id: id,
            flags: ApplicationFlags.FLAGS_NONE
            );
    }

    public void set_backup_status(Gtk.Widget new_status) {
        status_stack.set_visible_child(new_status);
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

        main_stack = new Gtk.Stack ();
        main_stack.set_transition_type (Gtk.StackTransitionType.SLIDE_LEFT_RIGHT);

        status_stack = new Gtk.Stack ();
        main_stack.add (status_stack);

        drive_manager = new Tardis.Widgets.DriveManager (volume_monitor, settings);
        main_stack.add (drive_manager);

        backups = new Tardis.Backups (volume_monitor, settings);

        backup_status = new Tardis.Widgets.BackupStatus (this,
                                                         settings,
                                                         backups);

        backup_status.get_backup_status.begin ();

        view_mode = new Granite.Widgets.ModeButton ();
        view_mode.margin_end = view_mode.margin_start = 12;
        view_mode.margin_bottom = view_mode.margin_top = 7;
        backup_status_id = view_mode.append_text (_("Backups"));
        drive_manager_id = view_mode.append_text (C_("view", "Manage Drives"));
        view_mode.notify["selected"].connect (on_view_mode_changed);
        view_mode.selected = backup_status_id;

        // HeaderBar
        headerbar = new Tardis.Widgets.HeaderBar (settings, volume_monitor, backup_status, backups, view_mode);
        headerbar.drive_added.connect(() => drive_manager.reload_drive_list ());
        drive_manager.drive_removed.connect(() => headerbar.build_add_target_menu ());


        volume_monitor.volume_added.connect(() => {
            backup_status.get_backup_status.begin ();
            headerbar.build_add_target_menu ();
        });

        volume_monitor.volume_removed.connect(() => {
            backup_status.get_backup_status.begin ();
            headerbar.build_add_target_menu ();
        });


        window.set_titlebar (headerbar);
        window.add (main_stack);
        window.show_all ();
        window.size_allocate.connect (() => { on_resize (); });
    }

    public void on_view_mode_changed () {
        if (view_mode.selected == backup_status_id) {
            main_stack.set_visible_child (status_stack);
        } else if (view_mode.selected == drive_manager_id) {
            main_stack.set_visible_child (drive_manager);
        }
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
        var return_code = app.run (args);
        app.settings.set_boolean ("first-run", false);
        return return_code;
    }
}
