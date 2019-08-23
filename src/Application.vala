using Gtk;


public class Tardis.App : Gtk.Application {

	public static string APP_ID = "com.github.chasinglogic.tardis";
	public static GLib.ThemedIcon BACKUP_IN_PROGRESS_ICON = new GLib.ThemedIcon("emblem-synchronizing");
	public static GLib.ThemedIcon BACKUP_IN_COMPLETED_ICON = new GLib.ThemedIcon("emblem-synchronized");

	public Tardis.Settings settings;
	public Gtk.ApplicationWindow window;

	
    public App () {
        Object (
            application_id: "com.github.chasinglogic.tardis",
            flags: ApplicationFlags.FLAGS_NONE
			);
    }
	
	// Store window size in gsettings when resized.
    public void on_resize() {
		if (!window.is_maximized) {
			stdout.printf("Window isn't maximized\n");
			int width;
			int height;
			stdout.printf("Getting window size\n");
			window.get_size(out width, out height);
			stdout.printf("Window size: %d / %d\n", width, height);
			stdout.printf("Seetings window size: %d / %d\n", settings.window_width, settings.window_width);
			if (settings.window_height != height || settings.window_width != width) {
				settings.window_height = height;
				settings.window_width = width;
			}

			if (settings.window_maximized) {
				settings.window_maximized = false;
			}
			
		} else if (!settings.window_maximized) {
			settings.window_maximized = true;
		}
    }

    protected override void activate () {
		settings = new Tardis.Settings(APP_ID);
		// Construct the main window for our Application.
        window = new Gtk.ApplicationWindow (this);
		window.title = "Tardis";
		
		if (settings.window_maximized) {
			window.maximize();
		} else {
			window.default_width = settings.window_width;
			window.default_height = settings.window_height;
		}

		window.show_all();
		window.size_allocate.connect(() => { on_resize(); });
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
		return app.run (args);
    }
}