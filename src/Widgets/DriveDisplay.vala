public class Tardis.Widgets.DriveDisplay : Gtk.Grid {
    private GLib.Settings settings;

    private Gtk.Label label;
    private Gtk.Image icon;

    private string drive_name;
    private string identifier;
    private string uuid;

    public DriveDisplay (GLib.VolumeMonitor volume_monitor, GLib.Settings settings, string target, Gtk.IconSize? size = Gtk.IconSize.LARGE_TOOLBAR) {
        this.settings = settings;

        identifier = target;

        var split = target.split("%%%");
        uuid = split[0];
        if (split.length > 1) {
            drive_name = split[1];
        } else {
            drive_name = uuid;
        }

        var volume = volume_monitor.get_volume_for_uuid (uuid);
        if (volume != null) {
            icon = new Gtk.Image.from_gicon (volume.get_icon (), size);
        } else {
            icon = new Gtk.Image.from_icon_name ("drive-removable-media", size);
        }

        icon.halign = Gtk.Align.START;

        label = new Gtk.Label (null);
        label.use_markup = true;
        label.halign = Gtk.Align.START;
        label.set_markup ("<b><span size='medium'>" + drive_name + "</span></b>");

        var remove_button = new Gtk.Button.from_icon_name ("user-trash");
        remove_button.halign = Gtk.Align.END;
        remove_button.clicked.connect(() => delete_this ());

        var content = new Gtk.Grid ();
        content.hexpand = true;
        content.halign = Gtk.Align.CENTER;
        content.valign = Gtk.Align.START;
        content.column_spacing = 12;
        content.row_spacing = 6;

        content.attach (icon, 0, 0, 1, 2);
        content.attach (label, 1, 0, 1, 1);
        content.attach (remove_button, 2, 0, 2, 2);

        hexpand = true;
        column_spacing = 6;
        orientation = Gtk.Orientation.HORIZONTAL;
        add(content);
    }

    public void delete_this () {
        string[] old_targets = settings.get_strv("backup-targets");
        string[] new_targets = Tardis.Utils.remove_from(old_targets, identifier);
        settings.set_strv("backup-targets", new_targets);
        deleted ();
        destroy ();
    }

    public signal void deleted ();
}
