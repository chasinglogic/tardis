using Granite;

public class Tardis.Settings : Granite.Services.Settings {
	public bool compress_backups { get; set; }
	public bool create_snapshots { get; set; }
	public bool backup_automatically { get; set; }
	public int max_snapshots { get; set; }
	public string[] directories_to_backup { get; set; }

	public int window_height { get; set; }
	public int window_width { get; set; }
	public bool window_maximized { get; set; }

	public Settings(string id) {
		base (id);
		if (directories_to_backup.length == 0) {
			stdout.printf("Setting default backup directory\n");
			directories_to_backup = { GLib.Environment.get_variable("HOME") };
		}

		stdout.printf("he\n");
	}
}