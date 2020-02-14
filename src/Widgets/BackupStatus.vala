using GLib;

public class Tardis.Widgets.BackupStatus  {
    private Tardis.App app;
    private GLib.Settings settings;
    private Tardis.BackupTargetManager backups;

    private GLib.ThemedIcon notification_icon;

    private Gtk.Stack message_stack;
    private Tardis.Widgets.BackupMessage safe_msg;
    private Tardis.Widgets.BackupMessage unsafe_msg;
    private Tardis.Widgets.BackupMessage in_progress;
    private Tardis.Widgets.BackupMessage calculating;
    private Tardis.Widgets.BackupMessage out_of_date_msg;
    private Tardis.Widgets.BackupMessage missing_files_msg;

    public BackupStatus(Tardis.App app,
                        GLib.Settings settings, Tardis.BackupTargetManager backups) {
        this.app = app;
        this.settings = settings;
        this.backups = backups;
        notification_icon = new GLib.ThemedIcon ("com.github.chasinglogic.tardis");

        safe_msg = new Tardis.Widgets.BackupMessage (
            "Your backups are up to date.",
            "Your data is safe."
        );

        unsafe_msg = new Tardis.Widgets.BackupMessage (
            "A backup is needed and no backup drives are available.",
            "You should plug in or add a new backup drive"
        );

        out_of_date_msg = new Tardis.Widgets.BackupMessage (
            "You haven't backed up in over 24 hours.",
            "Press the 'Start Backup' button to backup to all available targets."
        );

        missing_files_msg = new Tardis.Widgets.BackupMessage (
            "We've detected that there are differing\nfiles between your system and backup.",
            ""
        );

        in_progress = new Tardis.Widgets.BackupMessage ("Backup in progress...", "Please don't unplug any storage devices.");
        calculating = new Tardis.Widgets.BackupMessage ("Checking if your backups are up to date...", "This may take a moment");

        message_stack = new Gtk.Stack ();
        message_stack.margin = 24;
        message_stack.add (safe_msg);
        message_stack.add (unsafe_msg);
        message_stack.add (out_of_date_msg);
        message_stack.add (missing_files_msg);
        message_stack.add(calculating);
        message_stack.add(in_progress);

    }

    public void missing_files () {
        message_stack.set_visible_child (missing_files_msg);
    }

    public void out_of_date () {
        message_stack.set_visible_child (out_of_date_msg);
    }

    public void safe () {
        message_stack.set_visible_child (safe_msg);
    }

    public void unsafe () {
        message_stack.set_visible_child (unsafe_msg);
    }

    public async void get_backup_status() {
        message_stack.set_visible_child(calculating);

        var longer_than_24_hours = false;
        var differing_files = false;

        var backup_sources = backups.get_sources (true);
        foreach (Tardis.BackupTarget target in backups.get_targets ()) {
            if (target.out_of_date ()) {
                longer_than_24_hours = true;
                continue;
            }

            GLib.print("bs length: %d\n", target.last_backup_sources.length);
            if (target.last_backup_sources.length != backup_sources.length) {
                target.tag_as_dirty ();
                differing_files = true;
                continue;
            }

            var mount = yield backups.get_mount_for_target (target);
            if (mount == null) {
                target.tag_as_clean ();
                continue;
            }

            var backup_path = Tardis.Backups.get_backups_path(mount);
            // This means we found a drive which is a backup target but has
            // never had a backup.
            if (backup_path == null) {
                target.tag_as_dirty ();
                differing_files = true;
                continue;
            }

            // Remove any differing files tags if we found none.
            target.tag_as_clean ();
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
        } else if (longer_than_24_hours) {
            this.out_of_date ();
        } else if (differing_files) {
            this.missing_files ();
        } else {
            this.safe ();
        }
    }

    public void start_backup () {
        message_stack.set_visible_child (in_progress);
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

            this.safe ();
        });
    }
}
