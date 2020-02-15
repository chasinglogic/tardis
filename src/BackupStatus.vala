public class Tardis.BackupStatus {
    private Tardis.BackupTargetManager backups;

    public BackupStatus (Tardis.BackupTargetManager backups) {
        this.backups = backups;
    }

    public async void get_backup_status () {
        calculating ();

        var needs_backup = false;
        var safe_drive_found = false;

        var backup_sources = backups.get_sources (true);
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
