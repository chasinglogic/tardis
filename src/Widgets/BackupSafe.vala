public class Tardis.Widgets.BackupSafe : Gtk.Box {

    public static string title = "You're backups are up to date!";
    public static string subtitle = "Your data is safe.";

    public Granite.Widgets.Welcome text;
    public Gtk.Image icon;

    public BackupSafe () {
        orientation = Gtk.Orientation.VERTICAL;

        text = new Granite.Widgets.Welcome (title, subtitle);
        this.pack_start (text);

        icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("process-completed");
        icon.pixel_size = 64;
        this.pack_start(icon);
    }
}
