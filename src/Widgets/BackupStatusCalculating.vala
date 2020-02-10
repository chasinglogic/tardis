public class Tardis.Widgets.BackupStatusCalculating : Gtk.Box {

    public static string title = "Checking if your backups are up to date.";
    public static string subtitle = "";

    public Granite.Widgets.Welcome text;
    public Gtk.Spinner spinner;

    public BackupStatusCalculating () {
        orientation = Gtk.Orientation.VERTICAL;

        text = new Granite.Widgets.Welcome (title, subtitle);
        this.pack_start (text);

        spinner = new Gtk.Spinner ();
        this.pack_start(spinner);
        spinner.start();
    }
}
