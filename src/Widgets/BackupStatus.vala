using GLib;

public class Tardis.Widgets.BackupStatus  {
    private VolumeMonitor vm;
    private Tardis.App app;
    private Tardis.Settings settings;
    private Tardis.Backups backups;
    private Gtk.Button backup_button;

    public Tardis.Widgets.BackupSafe safe;
    public Tardis.Widgets.BackupUnsafe unsafe;
    public Tardis.Widgets.BackupNeeded needed;
    public Tardis.Widgets.BackupInProgress in_progress;
    public Tardis.Widgets.BackupStatusCalculating calculating;

    public BackupStatus(Tardis.App app, VolumeMonitor vm,
                        Tardis.Settings settings) {
        this.app = app;
        this.vm = vm;
        this.settings = settings;
        this.backups = new Tardis.Backups (vm, settings);
        safe = new Tardis.Widgets.BackupSafe ();
        app.status_box.add(safe);
        unsafe = new Tardis.Widgets.BackupUnsafe ();
        app.status_box.add(unsafe);
        in_progress = new Tardis.Widgets.BackupInProgress ();
        app.status_box.add(in_progress);
        calculating = new Tardis.Widgets.BackupStatusCalculating ();
        app.status_box.add(calculating);

        needed = new Tardis.Widgets.BackupNeeded (this);
        app.status_box.add(needed);

    }

    public async void get_backup_status() {
        app.set_backup_status(calculating);

        var backup_is_necessary = false;
        var curtime = get_monotonic_time();
        // 86400 is 24 hours in seconds
        var 24_hours = 86400;

        if (settings.last_backup == 0 || (curtime - settings.last_backup) > 24_hours) {
            backup_is_necessary = true;
        } else {
            backup_is_necessary =
                !Tardis.Utils.array_not_equal(backups.get_sources (), settings.last_backup_sources);
        }

        var available_backup_drives = yield backups.get_available_backup_drives ();
        if (backup_is_necessary && available_backup_drives.length == 0) {
            app.set_backup_status(unsafe);
            return;
        }

        foreach (GLib.Mount mount in  available_backup_drives) {
            if (mount == null) {
                continue;
            }

            var backup_path = Tardis.Backups.get_backups_path(mount);

            // This means we found a drive which is a backup target but has
            // never had a backup.
            if (backup_path == null) {
                backup_is_necessary = true;
                break;
            }

            var last_backup_tag = Tardis.Backups.get_backup_tag_file(mount);
            string content;
            try {
                GLib.FileUtils.get_contents(last_backup_tag, out content);
                int64 last_backup_time = content.to_int();
                if ((curtime - last_backup_time) > 24_hours) {
                    backup_is_necessary = true;
                    break;
                }
            } catch (GLib.FileError e) {
                // TODO handle this error
                continue;
            }
        }

        if (backup_is_necessary) {
            if (settings.automatic_backups) {
                start_backup ();
            } else {
                app.set_backup_status(needed);
            }

            return;
        }

        app.set_backup_status(safe);
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



