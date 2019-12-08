using Gtk;


public class Tardis.App : Gtk.Application {

	public static string ID = "com.github.chasinglogic.tardis";
	public static GLib.ThemedIcon BACKUP_IN_PROGRESS_ICON = new GLib.ThemedIcon("emblem-synchronizing");
	public static GLib.ThemedIcon BACKUP_IN_COMPLETED_ICON = new GLib.ThemedIcon("emblem-synchronized");

	// GLib settings accessor
	public Tardis.Settings settings;
	// Custom Widgets
	public Tardis.Widgets.BackupStatus backup_status;

	// Views
	public Tardis.Views.DriveSelectionView drive_select_view;

	// Widgets directly attached to the Application Window
	public Gtk.ApplicationWindow window;
	public Gtk.HeaderBar headerbar;
	public Gtk.Box header_box;

	public Gtk.Stack main_stack;
	public Granite.Widgets.ModeButton mode_button;

	// Public References
	private int drives_view_id;
	private int status_view_id;
	private int folders_view_id;
	
    public App () {
        Object (
            application_id: "com.github.chasinglogic.tardis",
            flags: ApplicationFlags.FLAGS_NONE
			);
    }

	public void on_view_mode_change() {
		if (mode_button.selected == drives_view_id) {
			main_stack.set_visible_child(drive_select_view);
		// } else if (mode_button.selected == folders_view_id) {
			// main_stack.set_visible_child(folders_select_view);
		} else {
			main_stack.set_visible_child(backup_status);
		}

	}

	// Store window size in gsettings when resized.
	public void on_resize() {
		if (!window.is_maximized) {
			int width;
			int height;
			window.get_size(out width, out height);
			if (settings.window_height != height || settings.window_width != width) {
				settings.window_height = height;
				settings.window_width = width;
			}
		}

		settings.window_maximized = window.is_maximized;
	}

	protected override void activate () {
		settings = Tardis.Settings.get_instance();
		// Construct the main window for our Application.
		window = new Gtk.ApplicationWindow (this);

		// HeaderBar
		headerbar = new Gtk.HeaderBar ();
		headerbar.show_close_button = true;

		mode_button = new Granite.Widgets.ModeButton();
		mode_button.margin_end = mode_button.margin_start = 12;
		mode_button.margin_bottom = mode_button.margin_top = 7;
		drives_view_id = mode_button.append_text("Drives");
		status_view_id = mode_button.append_text("Status");
		folders_view_id = mode_button.append_text("Folders");
		mode_button.halign = Gtk.Align.CENTER;
		mode_button.notify["selected"].connect(on_view_mode_change);
		mode_button.selected = drives_view_id;

		headerbar.set_custom_title(mode_button);

		window.set_titlebar (headerbar);

		if (settings.window_maximized) {
			window.maximize();
		} else {
			window.default_width = settings.window_width;
			window.default_height = settings.window_height;
		}

		main_stack = new Gtk.Stack();
		main_stack.transition_type = Gtk.StackTransitionType.SLIDE_LEFT_RIGHT;

		// TODO(chasinglogic): Write a get_backup_state function which
		// returns the right widget.
		backup_status = new Tardis.Widgets.BackupSafe(); 

		main_stack.add(backup_status);

		window.add(main_stack);

		window.show_all();

		on_view_mode_change();
		window.size_allocate.connect(() => { on_resize(); });
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
		return app.run (args);
    }
}