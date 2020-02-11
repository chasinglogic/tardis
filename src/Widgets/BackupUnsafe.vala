public class Tardis.Widgets.BackupUnsafe : Gtk.Box {

    public static string title = "You haven't backed up in 24 hours and no backup drives are available.";
    public static string subtitle = "You should plug in or add a new backup drive.";

    public Granite.Widgets.Welcome text;
    public Gtk.Image icon;

    public BackupUnsafe () {
        orientation = Gtk.Orientation.VERTICAL;

        text = new Granite.Widgets.Welcome (title, subtitle);
        this.pack_start (text);

        icon = new Gtk.Image ();
        icon.gicon = new ThemedIcon ("process-stop");
        icon.pixel_size = 64;
        this.pack_start(icon);
    }
}
