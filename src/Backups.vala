using GLib;

// This does the actual logic of backing up
//
// TODO closing the app should reap rsync processes
public class Tardis.Backups {
    private string[] backup_sources;

    private bool backup_data;
    private bool backup_configuration;

    public Backups(bool backup_data, bool backup_configuration) {
        this.backup_data = backup_data;
        this.backup_configuration = backup_configuration;
        this.backup_sources = null;
    }

    public string[] get_sources (bool? force_reload = false) throws GLib.Error {
        if (backup_sources == null || backup_sources.length == 0 || force_reload) {
            load_sources ();
        }

        return backup_sources;
    }

    public void load_sources() throws GLib.Error {
        var home_dir = Environment.get_home_dir();
        var home_dir_listing = Dir.open(home_dir);
        backup_sources = {};
        string? name;
        while ((name = home_dir_listing.read_name()) != null) {
            string path = Path.build_filename(home_dir, name);
            if (path == null) {
                continue;
            }

            if (backup_data && name[0] != '.') {
                backup_sources += path;
            } else if (backup_configuration && name[0] == '.') {
                backup_sources += path;
            }
        }

        // Always backup flatpaks since they could store data in their
        // container. (For example the Zeal flatpak behaves this way)
        if (!backup_configuration) {
            backup_sources += Path.build_filename(home_dir, ".var");
        }

        // Always include our own state so when the user wants to restore they
        // get their backup drives back.
        if (!backup_configuration) {
            backup_sources +=
                Path.build_filename(Environment.get_user_config_dir (), "Tardis");
        }
    }

    public async bool restore(Mount mount) throws GLib.Error {
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

    public async bool backup(Mount mount) throws GLib.Error {
        var backup_path = get_backups_path(mount, true);

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

        foreach (string src in get_sources ()) {
            if (src != null) {
                argv += src;
            }
        }

        argv += backup_path;

        var subproc = new Subprocess.newv(argv, SubprocessFlags.NONE);
        return yield subproc.wait_async();
    }
}
