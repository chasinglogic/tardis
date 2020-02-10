using Granite;

public class Tardis.Settings : Granite.Services.Settings {
    private static Settings? instance = null;

    public string[] backup_targets { get; set; }

    public int64 last_backup { get; set; }
    public string[] last_backup_sources { get; set; }

    public bool backup_data { get; set; }
    public bool backup_configuration { get; set; }
    // TODO add backup_applications and backup_appcenter_purchases

    public int window_height { get; set; }
    public int window_width { get; set; }
    public bool window_maximized { get; set; }

    public bool first_run { get; set; }
    public bool automatic_backups { get; set; }

    private Settings () {
        base ("com.github.chasinglogic.tardis");
    }

    public static Settings get_instance () {
        if (instance == null) {
            instance = new Settings ();
        }

        return instance;
    }
}
