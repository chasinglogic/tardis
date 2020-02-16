/*
* Copyright (c) 2020 Marco Betschart (http://chasinglogic.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Mathew Robinson <mathew@chasinglogic.io>
*/

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
