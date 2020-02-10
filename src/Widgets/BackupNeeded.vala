public class Tardis.Widgets.BackupNeeded : Gtk.Box {

    public static string title = "You haven't backed up in 24 hours.";
    public static string subtitle = "Press 'Start Backup' below to begin a backup.";

    public Granite.Widgets.Welcome text;
    public Granite.Widgets.WelcomeButton button;

    public BackupNeeded (Tardis.Widgets.BackupStatus status) {
        text = new Granite.Widgets.Welcome (title, subtitle);

        var icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("folder-download");
        icon.pixel_size = 24;
        int idx = text.append_with_image(icon, "Start Backup",
                                         "Backup to all available targets.");

        button = text.get_button_from_index(idx);
        button.clicked.connect(() => {
            status.start_backup ();
        });

        this.pack_start (text);
    }
}
