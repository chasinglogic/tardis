using Granite;

public class Tardis.Settings : Granite.Services.Settings {
    private static Settings? instance = null;
    private static string id = "com.github.chasinglogic.tardis";

    public bool compress_backups { get; set; }
    public bool create_snapshots { get; set; }
    public bool backup_automatically { get; set; }
    public int max_snapshots { get; set; }
    public string[] directories_to_backup { get; set; }
    public string[] backup_targets { get; set; }

    public int window_height { get; set; }
    public int window_width { get; set; }
    public bool window_maximized { get; set; }

    public bool first_run { get; set; }

    private Settings (string id) {
        base (id);
    }

    public static Settings get_instance () {
        if (instance == null) {
            instance = new Settings (id);
        }

        return instance;
    }
}
