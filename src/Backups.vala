using GLib;

// This does the actual logic of backing up
//
// TODO closing the app should reap rsync processes
public class Tardis.Backups {
    private string[] backup_sources;
    private Tardis.Settings settings;
    private VolumeMonitor vm;

    public Backups(VolumeMonitor vm, Tardis.Settings settings) {
        this.settings = settings;
        this.vm = vm;
        this.backup_sources = null;
    }

    public string[] get_sources (bool? force_reload = false) throws GLib.Error {
        if (backup_sources.length == 0 || force_reload) {
            load_sources ();
        }

        return backup_sources;
    }

    public void load_sources() throws GLib.FileError {
        var home_dir = Environment.get_home_dir();
        var home_dir_listing = Dir.open(home_dir);
        backup_sources = {};
        string? name;
        while ((name = home_dir_listing.read_name()) != null) {
            string path = Path.build_filename(home_dir, name);
            if (path == null) {
                continue;
            }

            if (settings.backup_data && name[0] != '.') {
                backup_sources += path;
            } else if (settings.backup_configuration && name[0] == '.') {
                backup_sources += path;
            }
        }

        // Always backup flatpaks since they could store data in their
        // container. (For example the Zeal flatpak behaves this way)
        if (!settings.backup_configuration) {
            backup_sources += Path.build_filename(home_dir, ".var");
        }
    }

    public async Mount[] get_available_backup_drives() {
        Mount[] results = {};

        foreach (string target in settings.backup_targets) {
            var volume = vm.get_volume_for_uuid(target);

            // TODO handle the case that backup_target could be a folder, we
            // don't support this in Views/Settings yet however.
            if (volume == null) {
                continue;
            }

            var mount = volume.get_mount();
            if (mount == null) {
                yield volume.mount(MountMountFlags.NONE, null);
                mount = volume.get_mount();

                // TODO error here instead of silently skipping
                if (mount == null) {
                    continue;
                }
            }

            results += mount;
        }

        return results;
    }

    public async bool restore(Mount mount) throws GLib.FileError {
        var backup_path = get_backups_path(mount);
        if (backup_path == null) {
            return false;
        }

        string[] argv = {"rsync", "-a"};
        if (Environment.get_variable("TARDIS_DEBUG") == "1") {
            argv += "-v";
        }

        var slash_home = Path.get_dirname (Environment.get_home_dir ());
        argv += backup_path;
        argv += slash_home;

        var subproc = new Subprocess.newv(argv, SubprocessFlags.NONE);
        return yield subproc.wait_async();
    }

    public async int backup() throws GLib.FileError {
        if (backup_sources == null || backup_sources.length == 0) {
            load_sources();
        }

        var curtime = get_monotonic_time();
        settings.last_backup = curtime;
        settings.last_backup_sources = backup_sources;

        string[] currently_backing_up = {};

        var mounts = yield get_available_backup_drives();
        foreach (Mount mount in mounts) {
            var backup_path = get_backups_path(mount, true);
            var backup_tag_file = get_backup_tag_file(mount);

            // It's possible for multiple targets to point to the same mount and
            // other strange bad states get us here. So we prevent creating
            // multiple rsync processes to the same location by storing what
            // we've already began a backup to.
            if (Tardis.Utils.contains_str(currently_backing_up, backup_path)) {
                continue;
            }

            currently_backing_up += backup_path;

            // TODO handle rsync errors
            yield do_backup(backup_path);
        }

        return 0;
    }

    public static string get_backup_tag_file(Mount mount) {
        return Path.build_filename(
            mount.get_root ().get_path (),
            "Tardis",
            "." + Environment.get_user_name()
            + "_last_backup");
    }

    public static string? get_backups_path(Mount mount,
                                          bool? create_if_not_found = false) {
        var root = mount.get_root().get_path();
        var backup_root = Path.build_filename(root, "Tardis", "Backups");
        try {
            Dir.open(backup_root);
        } catch(GLib.FileError e) {
            if (create_if_not_found) {
                DirUtils.create(backup_root, 0755);
            } else {
                return null;
            }
        }

        var backup_path = Path.build_filename(backup_root,
                                              Environment.get_user_name());

        return backup_path;
    }

    private async bool do_backup(string backup_path) {
        // See 'man rsync' for more detail.
        string[] argv = {
            "rsync",
            // Use the -a flag so we do the following:
            //   - recursively backup
            //   - copy symlinks as symlinks
            //   - preserve permissions and modification times
            //   - preserve group and owner
            //   - preserve special files
            "-a",
            // Use the --delete flag so we clean up files from the backup that the
            // user has removed.
            "--delete",
            // Ignore the trashed files
            "--exclude", ".local/share/Trash",
            // Ignore the cache files of various programs. These are usually not
            // resilient to version changes in the program that created them and
            // should be temporary / contain no meaningful data anyway.
            "--exclude", ".cache",
        };

        if (Environment.get_variable("TARDIS_DEBUG") == "1") {
            // Use the -v flag for debugging if run from the command line.
            argv += "-v";
        }

        foreach (string src in backup_sources) {
            if (src != null) {
                argv += src;
            }
        }

        argv += backup_path;

        var subproc = new Subprocess.newv(argv, SubprocessFlags.NONE);
        return yield subproc.wait_async();
    }
}
