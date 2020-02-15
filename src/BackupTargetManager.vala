using GLib;

public class Tardis.BackupTargetManager {
    private string state_file;

    private GLib.Settings settings;
    private GLib.VolumeMonitor vm;

    private Tardis.Backups backups;
    private List<Tardis.BackupTarget> targets;

    public BackupTargetManager (GLib.VolumeMonitor vm, GLib.Settings settings) {
        this.settings = settings;
        this.vm = vm;
        targets = new List<BackupTarget> ();

        state_file = Path.build_filename (
            Environment.get_user_config_dir (),
            "Tardis",
            "targets.json"
            );

        if (!FileUtils.test (Path.get_dirname (state_file), FileTest.EXISTS)) {
            DirUtils.create_with_parents (Path.get_dirname (state_file), 0755);
        }

        if (FileUtils.test (state_file, FileTest.EXISTS)) {
            var parser = new Json.Parser ();
            try {
                parser.load_from_file (state_file);
                var root = parser.get_root ().get_array ();
                if (root != null) {
                    var real = (Json.Array) root;
                    real.foreach_element ((_arr, _idx, obj) => {
                        var t = new BackupTarget.from_json ((Json.Object) obj.get_object ());
                        targets.append (t);
                    });
                }
            } catch (GLib.Error e) {
                GLib.print ("Failed to load state! %s\n", e.message);
            }
        }
    }


    public string[] get_target_ids () {
        string[] ids = new string[(int) targets.length ()];

        foreach (BackupTarget target in targets) {
            ids += target.id;
        }

        return ids;
    }

    public unowned List<BackupTarget> get_targets () {
        return targets;
    }

    public void write_state () {
        Json.Builder builder = new Json.Builder ();

        builder.begin_array ();
        foreach (BackupTarget target in targets) {
            target.build_json (builder);
        }
        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        string targets_json = generator.to_data (null);

        try {
            FileUtils.set_contents (state_file, targets_json, -1);
        } catch (GLib.FileError e) {
            save_error (e.message);
        }
    }

    public void add_volume (GLib.Volume volume) {
        add_target (new Tardis.BackupTarget.from_volume (volume));
    }

    public void add_target (Tardis.BackupTarget target) {
        targets.append (target);
        write_state ();
        target_added (target);
    }

    public async void restore_from (Tardis.BackupTarget target) {
        var mount = yield get_mount_for_target (target);
        if (mount == null) {
            backup_error (target, "Unable to mount drive");
            return;
        }

        try {
            yield backups.restore (mount);
        } catch (GLib.Error e) {
            backup_error (target, e.message);
        }
    }

    public async int do_backup (Tardis.Backups backups, Tardis.BackupTarget target) {
        var mount = yield get_mount_for_target (target);
        if (mount == null) {
            return 0;
        }

        backup_started (target);

        try {
            yield backups.backup (mount);
        } catch (Error e) {
            backup_error (target, e.message);
            return -1;
        }

        try {
            var sources = backups.get_sources ();
            target.last_backup_sources = sources;
        } catch (GLib.Error e) {
            backup_error (target, e.message);
            return -1;
        }

        var curtime = get_monotonic_time ();
        target.last_backup_time = curtime;

        backup_complete (target);
        return 0;
    }

    private Tardis.Backups get_backups () {
        return new Tardis.Backups (
            settings.get_boolean ("backup-data"),
            settings.get_boolean ("backup-configuration")
        );
    }

    public async void backup_target (Tardis.BackupTarget target) {
        var backups = get_backups ();
        yield do_backup (backups, target);
    }

    public string[] get_sources (bool? force_reload = false) {
        var backups = get_backups ();
        try {
            return backups.get_sources (force_reload);
        } catch (GLib.Error e) {
            save_error (e.message);
            return new string[0];
        }
    }

    public async void backup_all () {
        string[] currently_backing_up = new string[(int) targets.length ()];
        var backups = get_backups ();

        foreach (BackupTarget target in targets) {
            // It's possible for multiple targets to point to the same mount and
            // other strange bad states get us here. So we prevent creating
            // multiple rsync processes to the same location by storing what
            // we've already began a backup to.
            if (Tardis.Utils.contains_str (currently_backing_up, target.id)) {
                continue;
            }

            currently_backing_up += target.id;
            yield do_backup (backups, target);
        }

        write_state ();
    }

    public async Mount? get_mount_for_target (BackupTarget target) {
        var volume = vm.get_volume_for_uuid (target.id);
        if (volume == null) {
            return null;
        }

        var mount = volume.get_mount ();

        // If it was null try to mount it
        if (mount == null) {
            try {
                yield volume.mount (MountMountFlags.NONE, null);
            } catch (GLib.Error e) {
                backup_error (target, e.message);
                return null;
            }

            mount = volume.get_mount ();
        }

        return mount;
    }

    public async Mount[] get_available_backup_drives () throws GLib.Error {
        Mount[] results = {};

        foreach (BackupTarget target in targets) {
            var mount = yield get_mount_for_target (target);
            if (mount == null) {
                continue;
            }

            results += mount;
        }

        return results;
    }

    public void remove_target (BackupTarget target_to_remove) {
        targets.remove (target_to_remove);
        target_removed (target_to_remove);
        write_state ();
    }

    public signal void save_error (string err_msg);
    public signal void backup_error (BackupTarget target, string err_msg);

    public signal void target_removed (BackupTarget target);
    public signal void target_added (BackupTarget target);

    public signal void backup_started (BackupTarget target);
    public signal void backup_complete (BackupTarget target);
}
