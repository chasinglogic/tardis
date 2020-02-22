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

public class Tardis.BackupTarget : GLib.Object {
    public string id;
    public string display_name;
    public string icon_name;
    public int64 last_backup_time;

    public BackupTarget (
        string id,
        string display_name,
        string icon_name,
        int64 last_backup_time
    ) {
        this.id = id;
        this.display_name = display_name;
        this.icon_name = icon_name;
        this.last_backup_time = last_backup_time;
    }

    public BackupTarget.from_json (Json.Object obj) {
        this.id = obj.get_string_member ("id");
        this.display_name = obj.get_string_member ("display_name");
        this.icon_name = obj.get_string_member ("icon_name");
        this.last_backup_time = obj.get_int_member ("last_backup_time");
    }

    public BackupTarget.from_volume (GLib.Volume volume) {
        this.last_backup_time = 0;
        this.display_name = Utils.display_name (volume);

        // Try to get icon name
        var icon = new Gtk.Image.from_gicon (volume.get_icon (), Gtk.IconSize.SMALL_TOOLBAR);
        string gicon_name;
        icon.get_icon_name (out gicon_name, null);
        if (gicon_name != null) {
            icon_name = gicon_name;
        } else {
            icon_name = "drive-removable-media";
        }

        // Try to get a unique id
        var uuid = volume.get_uuid ();
        if (uuid != null) {
            id = uuid;
        } else {
            id = display_name;
        }
    }

    public void build_json (Json.Builder builder) {
        builder.begin_object ();

        builder.set_member_name ("id");
        builder.add_string_value (id);

        builder.set_member_name ("display_name");
        builder.add_string_value (display_name);

        builder.set_member_name ("icon_name");
        builder.add_string_value (icon_name);

        builder.set_member_name ("last_backup_time");
        builder.add_int_value (last_backup_time);

        builder.end_object ();
    }

    public bool out_of_date () {
        var curtime = GLib.get_real_time ();
        return (last_backup_time == 0) ||
            (curtime - last_backup_time) > GLib.TimeSpan.DAY;
    }
}
