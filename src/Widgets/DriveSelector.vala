using Gee;

public class Tardis.Widgets.DriveSelector : Gtk.ComboBoxText {
    private HashMap<string, string> drive_map;

    public DriveSelector (Tardis.BackupTargetManager backup_target_manager, GLib.VolumeMonitor vm) {
        drive_map = new HashMap<string, string> ();

        var volumes = vm.get_volumes ();
        var backup_targets = backup_target_manager.get_target_ids ();

        foreach (Volume vol in volumes) {
            var name = vol.get_drive ().get_name ();
            var uuid = vol.get_uuid ();

            if (uuid == null) {
                continue;
            }

            if (Tardis.Utils.contains_str (backup_targets, uuid)) {
                continue;
            }

            drive_map.set (name, uuid);
            append_text (name);
        }
    }

    public new string get_active_text () {
        var name = base.get_active_text ();
        return drive_map.@get (name);
    }
}
