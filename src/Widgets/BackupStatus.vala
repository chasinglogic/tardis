using GLib;

public class Tardis.Widgets.BackupStatus  {
    private Tardis.App app;
    private GLib.Settings settings;
    private Tardis.BackupTargetManager backups;

    private GLib.ThemedIcon notification_icon;

    private string out_of_date_msg;
    private string unsafe_msg;
    private string in_progress;

    public BackupStatus(Tardis.App app,
                        GLib.Settings settings, Tardis.BackupTargetManager backups) {
        this.app = app;
        this.settings = settings;
        this.backups = backups;
        notification_icon = new GLib.ThemedIcon ("com.github.chasinglogic.tardis");

        unsafe_msg = "A backup is needed and no backup drives are available.";
        out_of_date_msg = "We've detected some of your backups are out of date.";
        in_progress = "Backup in progress. Please don't unplug any storage devices.";
    }

    public void out_of_date () {
        app.warning_message (out_of_date_msg, null);
    }

    public void unsafe () {
        app.warning_message (unsafe_msg, null);
    }

    public async void get_backup_status() {
        app.main_view.set_all (DriveStatusType.IN_PROGRESS);

        var longer_than_24_hours = false;
        var differing_files = false;

        var backup_sources = backups.get_sources (true);
        foreach (Tardis.BackupTarget target in backups.get_targets ()) {
            if (target.out_of_date ()) {
                longer_than_24_hours = true;
                target_needs_backup (target);
                continue;
            }

            GLib.print("bs length: %d\n", target.last_backup_sources.length);
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
                backup_path = Tardis.Backups.get_backups_path(mount);
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
                    this.unsafe ();
                }
            } catch (GLib.Error e) {
                // TODO provide an API to show an error message info bar via
                // Application
                // app.set_backup_status (error);
                return;
            }
        }

        if ((longer_than_24_hours || differing_files) &&
            settings.get_boolean("automatic-backups")) {
            start_backup ();
        } else if (longer_than_24_hours || differing_files) {
            this.out_of_date ();
        }
    }

    public void start_backup () {
        var starting_backup = new GLib.Notification("Starting Backup!");
        starting_backup.set_icon (notification_icon);
        starting_backup.set_body("Please do not unplug any storage devices.");
        app.send_notification( "com.github.chasinglogic.tardis", starting_backup);

        // TODO be granular
        backups.backup_all.begin((obj, res) => {
            var stopping_backup = new Notification("Backup Complete!");
            stopping_backup.set_icon (notification_icon);
            stopping_backup.set_body("Your data is safe!");
            app.send_notification( "com.github.chasinglogic.tardis", stopping_backup);
        });
    }

    public signal void target_needs_backup (BackupTarget target);
    public signal void target_is_backed_up (BackupTarget target);
}
