public class Tardis.Widgets.BackupSafe : Tardis.Widgets.BackupStatus {

    public static string default_title = "You're backups are up to date!";
    public static string default_subtitle = "Your data is safe.";

    public Granite.Widgets.Welcome text;

    public BackupSafe() {
        text = new Granite.Widgets.Welcome(default_title, default_subtitle);
        this.pack_start(text);

        // TODO(chasinglogic): Add green checkmark or other easily
        // identifiable success / safe symbol.
    }
}