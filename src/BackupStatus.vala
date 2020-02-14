public class Tardis.BackupStatus {
    private Tardis.BackupTargetManager backups;

    public BackupStatus (Tardis.BackupTargetManager backups) {
        this.backups = backups;
    }

    public async void get_backup_status () {
        calculating ();

        var longer_than_24_hours = false;
        var differing_files = false;

        var backup_sources = backups.get_sources (true);
        foreach (Tardis.BackupTarget target in backups.get_targets ()) {
            if (target.out_of_date ()) {
                longer_than_24_hours = true;
                target_needs_backup (target);
                continue;
            }

            if (target.last_backup_sources.length != backup_sources.length) {
                target_needs_backup (target);
                differing_files = true;
                continue;
            }

            var mount = yield backups.get_mount_for_target (target);
            if (mount == null) {
                target_is_backed_up (target);
                continue;
            }

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
                differing_files = true;
                continue;
            }

            // Remove any differing files tags if we found none.
            target_is_backed_up (target);
        }

        if (longer_than_24_hours || differing_files) {
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

        if (longer_than_24_hours || differing_files) {
            out_of_date ();
        }
    }

    public signal void calculating ();
    public signal void unsafe (string? message);
    public signal void out_of_date ();

    public signal void target_needs_backup (BackupTarget target);
    public signal void target_is_backed_up (BackupTarget target);
}
