/*
* Copyright (c) 2020 Marco Betschart (http://chasinglogic.io)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Mathew Robinson <mathew@chasinglogic.io>
*/

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

        write_json_file (state_file, builder);
    }

    private void write_json_file (string filename, Json.Builder builder) {
        Json.Generator generator = new Json.Generator ();
        Json.Node root = builder.get_root ();
        generator.set_root (root);

        string targets_json = generator.to_data (null);

        try {
            FileUtils.set_contents (filename, targets_json, -1);
        } catch (GLib.FileError e) {
            save_error (e.message);
        }
    }

    private string get_on_disk_json_file (Mount mount) {
        var root = mount.get_root ().get_path ();
        return Path.build_filename (root, "Tardis", "target.json");
    }

    public async void add_volume (GLib.Volume volume) {
        var mount = yield Tardis.Utils.get_mount (volume);
        if (mount == null) {
            add_target (new Tardis.BackupTarget.from_volume (volume));
            return;
        }

        bool existing_backups = false;
        try {
            var backups_path = Tardis.Backups.get_backups_path (mount, false);
            if (FileUtils.test (backups_path, FileTest.EXISTS)) {
                existing_backups = true;
            }
        } catch (GLib.Error e) {
            // Nothing to do, probably means the backup path doesn't exist.
        }

        GLib.print("existing backups: %s\n", existing_backups ? "t" : "f");

        var target_json = get_on_disk_json_file (mount);
        BackupTarget target = null;
        if (FileUtils.test (target_json, FileTest.EXISTS)) {
            var parser = new Json.Parser ();
            try {
                parser.load_from_file (target_json);
                target = new BackupTarget.from_json ((Json.Object)
                                                     parser.get_root ());
            } catch (GLib.Error e) {
                target = new BackupTarget.from_volume (volume);
            }
        } else {
            target = new BackupTarget.from_volume (volume);
        }

        add_target (target, !existing_backups);
    }

    public void add_target (Tardis.BackupTarget target,
                            bool? should_backup = true) {
        targets.append (target);
        target_added (target, should_backup);
    }

    public async void restore_from (Tardis.BackupTarget target) {
        var mount = yield get_mount_for_target (target);
        if (mount == null) {
            backup_error (target, "Unable to mount drive, is it plugged in?");
            return;
        }

        try {
            restore_started (target);
            yield backups.restore (mount);
            restore_complete (target);
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

        var curtime = get_real_time ();
        target.last_backup_time = curtime;

        try {
            // Build a path like /path/to/drive/Tardis/target.json
            var on_disk_target_file = get_on_disk_json_file (mount);
            var builder = new Json.Builder ();
            target.build_json (builder);
            write_json_file (on_disk_target_file, builder);
        } catch (Error e) {
            backup_error (target, e.message);
            return -1;
        }

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
        var backups = get_backups ();
        foreach (BackupTarget target in targets) {
            yield do_backup (backups, target);
        }
    }

    public async Mount? get_mount_for_target (BackupTarget target) {
        var volume = vm.get_volume_for_uuid (target.id);
        if (volume == null) {
            return null;
        }

        return yield Tardis.Utils.get_mount (volume);
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
    }

    public signal void save_error (string err_msg);
    public signal void backup_error (BackupTarget target, string err_msg);

    public signal void target_removed (BackupTarget target);
    public signal void target_added (BackupTarget target, bool should_backup);

    public signal void backup_started (BackupTarget target);
    public signal void backup_complete (BackupTarget target);

    public signal void restore_started (BackupTarget target);
    public signal void restore_complete (BackupTarget target);
}
