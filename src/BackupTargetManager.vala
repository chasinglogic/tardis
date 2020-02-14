using GLib;

public class Tardis.BackupTargetManager {
    private string state_file;

    private GLib.Settings settings;
    private Tardis.Backups backups;
    private GLib.VolumeMonitor vm;
    private Tardis.BackupTarget[] targets;

    public BackupTargetManager (GLib.Settings settings) throws GLib.FileError {
        this.settings = settings;
        vm = GLib.VolumeMonitor.@get ();
        targets = new BackupTarget[0];

        state_file = Path.build_filename(
            Environment.get_user_config_dir (),
            "Tardis",
            "targets.json"
            );

        if (!FileUtils.test(Path.get_dirname(state_file), FileTest.EXISTS)) {
            DirUtils.create(Path.get_dirname(state_file), 0755);
        }

        if (FileUtils.test(state_file, FileTest.EXISTS)) {
            var parser = new Json.Parser ();
            parser.load_from_file(state_file);
            var root = parser.get_root ().get_array ();
            if (root != null) {
                var real = (Json.Array) root;
                real.foreach_element((_arr, _idx, obj) => {
                    var t = new BackupTarget.from_json((Json.Object) obj.get_object ());
                    targets += t;
                });
            }
        }
    }


    public string[] get_target_ids () {
        string[] ids = new string[targets.length];

        foreach (BackupTarget target in targets) {
            ids += target.id;
        }

        return ids;
    }

    public BackupTarget[] get_targets () {
        return targets;
    }

    public void write_state () {
        Json.Builder builder = new Json.Builder ();
        builder.begin_array ();

        foreach (BackupTarget target in targets) {
            target.build_json(builder);
        }

        builder.end_array ();

        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        string targets_json = generator.to_data (null);

        FileUtils.set_contents(state_file, targets_json, -1);
    }

    public void add_volume(GLib.Volume volume) {
        add_target (new Tardis.BackupTarget.from_volume (volume));
    }

    public void add_target (Tardis.BackupTarget target) {
        targets += target;
        write_state ();
        target_added (target);
    }

    public async void restore_from(Tardis.BackupTarget target) {
        var mount = yield get_mount_for_target(target);
        // TODO inform user that drive couldn't be mounted for restore.
        if (mount == null) {
            return;
        }

        yield backups.restore (mount);
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

        var sources = backups.get_sources ();
        target.last_backup_sources = sources;

        var curtime = get_monotonic_time ();
        target.last_backup_time = curtime;

        backup_complete (target);
        return 0;
    }

    private Tardis.Backups get_backups () {
        return new Tardis.Backups(
            settings.get_boolean("backup-data"),
            settings.get_boolean("backup-configuration")
        );
    }

    public async void backup_target(Tardis.BackupTarget target) {
        var backups = get_backups ();
        yield do_backup (backups, target);
    }

    public string[] get_sources (bool? force_reload = false) {
        var backups = get_backups ();
        return backups.get_sources (force_reload);
    }

    public async void backup_all () {
        string[] currently_backing_up = new string[targets.length];
        var backups = get_backups ();

        foreach (BackupTarget target in targets) {
            // It's possible for multiple targets to point to the same mount and
            // other strange bad states get us here. So we prevent creating
            // multiple rsync processes to the same location by storing what
            // we've already began a backup to.
            if (Tardis.Utils.contains_str(currently_backing_up, target.id)) {
                continue;
            }

            currently_backing_up += target.id;
            yield do_backup (backups, target);
        }

        write_state ();
    }

    public async Mount? get_mount_for_target(BackupTarget target) {
        var volume = vm.get_volume_for_uuid(target.id);

        // TODO handle the case that backup_target could be a folder, we
        // don't support this in Views/Settings yet however.
        if (volume == null) {
            return null;
        }

        var mount = volume.get_mount ();

        // If it was null try to mount it
        if (mount == null) {
            yield volume.mount (MountMountFlags.NONE, null);
            mount = volume.get_mount ();
        }

        return mount;
    }

    public async Mount[] get_available_backup_drives() throws GLib.Error {
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

    public void remove_target(BackupTarget target_to_remove) {
        BackupTarget[] new_targets = new BackupTarget[targets.length - 1];
        BackupTarget? removed_target = null;
        foreach (BackupTarget target in targets) {
            if (target.id == target_to_remove.id) {
                removed_target = target;
                continue;
            }

            new_targets += target;
        }

        targets = new_targets;

        // If we actually removed something
        if (removed_target != null) {
            target_removed (removed_target);
            write_state ();
        }
    }

    public signal void backup_error (BackupTarget target, string err_msg);

    public signal void target_removed (BackupTarget target);
    public signal void target_added (BackupTarget target);

    public signal void backup_started (BackupTarget target);
    public signal void backup_complete (BackupTarget target);
}
