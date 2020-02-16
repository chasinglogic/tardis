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

public class Tardis.BackupStatus {
    private Tardis.BackupTargetManager backups;

    public BackupStatus (Tardis.BackupTargetManager backups) {
        this.backups = backups;
    }

    public async void get_backup_status () {
        calculating ();

        var needs_backup = false;
        var safe_drive_found = false;

        foreach (Tardis.BackupTarget target in backups.get_targets ()) {
            if (target.out_of_date ()) {
                needs_backup = true;
                target_needs_backup (target);
                continue;
            }

            var mount = yield backups.get_mount_for_target (target);
            if (mount != null) {
                string? backup_path = null;
                try {
                    backup_path = Tardis.Backups.get_backups_path (mount);
                } catch (GLib.Error e) {
                    // Because create_if_not_found is false here we never will
                    // encounter this code path. This is here to silence a false
                    // compiler warning.
                }

                // This means we found a drive which is a backup target but has
                // never had a backup.
                if (backup_path == null) {
                    target_needs_backup (target);
                    needs_backup = true;
                    continue;
                }
            }

            // Remove any differing files tags if we found none.
            target_is_backed_up (target);
            safe_drive_found = true;
        }

        if (needs_backup && !safe_drive_found) {
            try {
                var available_backup_drives = yield backups.get_available_backup_drives ();
                if (available_backup_drives.length == 0) {
                    unsafe (null);
                }
            } catch (GLib.Error e) {
                unsafe (e.message);
                return;
            }
        }

        if (needs_backup) {
            out_of_date ();
        }
    }

    public signal void calculating ();
    public signal void unsafe (string? message);
    public signal void out_of_date ();

    public signal void target_needs_backup (BackupTarget target);
    public signal void target_is_backed_up (BackupTarget target);
}
