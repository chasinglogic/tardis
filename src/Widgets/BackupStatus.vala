using GLib;

public class Tardis.Widgets.BackupStatus  {
    private Tardis.App app;
    private GLib.Settings settings;
    private Tardis.Backups backups;

    public Tardis.Widgets.BackupMessage safe;
    public Tardis.Widgets.BackupMessage unsafe;
    public Tardis.Widgets.BackupMessage error;
    public Tardis.Widgets.BackupNeeded out_of_date;
    public Tardis.Widgets.BackupNeeded missing_files;
    public Tardis.Widgets.BackupInProgress in_progress;
    public Tardis.Widgets.BackupInProgress calculating;

    public BackupStatus(Tardis.App app,
                        GLib.Settings settings, Tardis.Backups backups) {
        this.app = app;
        this.settings = settings;
        this.backups = backups;

        safe = new Tardis.Widgets.BackupMessage ("Your backups are up to date.",
                                              "Your data is safe.",
                                              "process-completed");
        app.status_stack.add(safe);
        error = new Tardis.Widgets.BackupMessage ("An error has occurred while trying to load backup drives.",
                                                  "Please report this bug upstream.",
                                                  "process-stop");
        app.status_stack.add(error);
        unsafe = new Tardis.Widgets.BackupMessage ("A backup is needed and no backup drives are available.",
                                                   "You should plug in or add a new backup drive",
                                                   "process-stop");
        app.status_stack.add(unsafe);
        in_progress = new Tardis.Widgets.BackupInProgress ("Backing up your data...");
        app.status_stack.add(in_progress);
        calculating = new Tardis.Widgets.BackupInProgress ("Checking if your backups are up to date...");
        app.status_stack.add(calculating);

        out_of_date = new Tardis.Widgets.BackupNeeded (
            this,
            "You haven't backed up in over 24 hours"
        );
        app.status_stack.add(out_of_date);

        missing_files = new Tardis.Widgets.BackupNeeded (
            this,
            "We've detected that there are differing\nfiles between your system and backup."
        );
        app.status_stack.add(missing_files);

        settings.changed.connect((key) => {
            if (key == "backup-configuration" || key == "backup-data") {
                get_backup_status.begin ();
            }
        });
    }

    public async void get_backup_status() {
        app.set_backup_status(calculating);

        var longer_than_24_hours = false;
        var differing_files = false;
        var curtime = get_monotonic_time();

        // 86400 is 24 hours in seconds
        var 24_hours = 86400;

        var last_known_backup = settings.get_int64("last-backup");
        if (last_known_backup == 0 || (last_known_backup - curtime) > 24_hours) {
            longer_than_24_hours = true;
        } else {
            try {
                differing_files =
                    !Tardis.Utils.array_not_equal(backups.get_sources (true), settings.get_strv("last-backup-sources"));

            } catch (GLib.Error e) {
                GLib.print("Unable to load backup sources: %s\n", e.message);
            }
        }

        var backup_is_necessary = longer_than_24_hours || differing_files;
        Mount[] available_backup_drives;
        try {
            available_backup_drives = yield backups.get_available_backup_drives ();
        } catch (GLib.Error e) {
            GLib.print("Unexpected error: %s\n", e.message);
            app.set_backup_status (error);
            return;
        }

        if (backup_is_necessary && available_backup_drives.length == 0) {
            app.set_backup_status(unsafe);
            return;
        }

        // If we've already determined a backup is necessary then no reason to
        // scan available drives.
        if (!backup_is_necessary) {
            foreach (GLib.Mount mount in  available_backup_drives) {
                if (mount == null) {
                    continue;
                }

                var backup_path = Tardis.Backups.get_backups_path(mount);

                // This means we found a drive which is a backup target but has
                // never had a backup.
                if (backup_path == null) {
                    differing_files = true;
                    break;
                }

                var last_backup_tag = Tardis.Backups.get_backup_tag_file(mount);
                string content;
                try {
                    GLib.FileUtils.get_contents(last_backup_tag, out content);
                    int64 last_backup_time = int.parse(content);
                    if ((last_backup_time - curtime) > 24_hours) {
                        longer_than_24_hours = true;
                        break;
                    }
                } catch (GLib.FileError e) {
                    // TODO handle this error
                    continue;
                }
            }
        }

        if ((longer_than_24_hours || differing_files) &&
            settings.get_boolean("automatic-backups")) {
            start_backup ();
        } else if (longer_than_24_hours) {
            app.set_backup_status(out_of_date);
        } else if (differing_files) {
            app.set_backup_status(missing_files);
        } else {
            app.set_backup_status(safe);
        }

    }

    public void start_backup () {
        app.set_backup_status (in_progress);
        in_progress.spinner.start ();
        var starting_backup = new GLib.Notification("Starting Backup!");
        starting_backup.set_body("Please do not unplug any storage devices.");
        app.send_notification( "com.github.chasinglogic.tardis", starting_backup);

        backups.backup.begin((obj, res) => {
            var stopping_backup = new Notification("Backup Complete!");
            stopping_backup.set_body("Your data is safe!");
            app.send_notification( "com.github.chasinglogic.tardis", stopping_backup);

            app.set_backup_status(safe);
        });
    }
}



