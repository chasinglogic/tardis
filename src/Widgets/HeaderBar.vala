public class Tardis.Widgets.HeaderBar : Gtk.HeaderBar {
    private Gtk.MenuButton menu_button;
    private Gtk.Popover backup_settings_popover;
    private Gtk.Popover add_target_popover;
    private GLib.Settings settings;
    private GLib.VolumeMonitor vm;
    private Gtk.Box add_target_menu;
    private Gtk.MenuButton add_target_button;

    private Tardis.Backups backups;

    // TODO: add restore button
    // TODO: add new drive button
    public HeaderBar(GLib.Settings settings,
                     GLib.VolumeMonitor vm,
                     Tardis.Widgets.BackupStatus status,
                     Tardis.Backups backups,
                     Gtk.Widget mode_button) {
        this.vm = vm;
        this.backups = backups;
        this.settings = settings;
        show_close_button = true;
        set_custom_title(mode_button);

        var backup_data = new Tardis.Widgets.SettingToggler (
            // Add spaces to make switches line up
            _("Backup Data"),
            _("Indicates backups should include all non-hidden directories. It is recommended to leave this setting on."),
            settings,
            "backup-data"
        );
        var backup_data_model = new Gtk.ModelButton ();
        backup_data_model.get_child ().destroy ();
        backup_data_model.add (backup_data);
        backup_data_model.button_release_event.connect (() => {
                backup_data.toggler_switch.activate ();
                return Gdk.EVENT_STOP;
        });

        var backup_configuration = new Tardis.Widgets.SettingToggler (
            _("Backup Configuration"),
            _("Indicates backups should include hidden directories. This is " +
              "recommended for most users however, can sometimes cause issues " +
              "when restoring backups."),
            settings,
            "backup-configuration"
        );
        var backup_configuration_model = new Gtk.ModelButton ();
        backup_configuration_model.get_child ().destroy ();
        backup_configuration_model.add (backup_configuration);
        backup_configuration_model.button_release_event.connect (() => {
                backup_configuration.toggler_switch.activate ();
                return Gdk.EVENT_STOP;
        });

        var automatic_backups = new Tardis.Widgets.SettingToggler (
            _("Automatically Backup"),
            _("When backup targets are available and application is running" +
              "automatically start a backup without prompting. While convenient" +
              "this can cause issues when you want to restore from a drive. This" +
              "settings is only recommended for advanced users."),
            settings,
            "automatic-backups"
        );
        var automatic_backups_model = new Gtk.ModelButton ();
        automatic_backups_model.get_child ().destroy ();
        automatic_backups_model.add (automatic_backups);
        automatic_backups_model.button_release_event.connect (() => {
                automatic_backups.toggler_switch.activate ();
                return Gdk.EVENT_STOP;
        });

        menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.tooltip_text = _("Backup Settings");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_top = 12;
        menu_grid.margin_bottom = 12;
        menu_grid.row_spacing = 12;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.width_request = 200;
        menu_grid.add(backup_data_model);
        menu_grid.add(new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add(backup_configuration_model);
        menu_grid.add(new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add(automatic_backups_model);
        menu_grid.show_all ();

        backup_settings_popover = new Gtk.Popover (null);
        backup_settings_popover.add (menu_grid);
        menu_button.popover = backup_settings_popover;

        // var restore_button = new Gtk.Button ();
        // restore_button.image = new Gtk.Image.from_icon_name (
        //     "document-open-recent",
        //      Gtk.IconSize.LARGE_TOOLBAR
        // );
        // restore_button.tooltip_text = _("Restore from Backup");
        // restore_button.clicked.connect (() => {
        //     var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
        //         "Are you sure?",
        //         "",
        //         "applications-development",
        //         Gtk.ButtonsType.CLOSE
        //     );
        // });

        add_target_menu = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        add_target_menu.margin = 12;

        add_target_popover = new Gtk.Popover (null);
        add_target_popover.add (add_target_menu);

        add_target_button = new Gtk.MenuButton ();
        add_target_button.image = new Gtk.Image.from_icon_name (
            "drive-harddisk",
             Gtk.IconSize.LARGE_TOOLBAR
        );
        add_target_button.tooltip_text = _("Add Backup Drives");
        add_target_button.popover = add_target_popover;
        build_add_target_menu ();

        // pack_start(restore_button);
        pack_start(add_target_button);
        pack_end (menu_button);
    }

    public void build_add_target_menu () {
        var volumes = vm.get_volumes ();
        if (volumes.length() == 0) {
            add_target_button.set_popover (null);
            return;
        }

        // Remove everything first
        add_target_menu.@foreach ((child) => {
            add_target_menu.remove(child);
        });
        var new_drives = false;
        var backup_targets = settings.get_strv("backup-targets");

        foreach (Volume vol in volumes) {
            var name = vol.get_drive ().get_name ();
            var uuid = vol.get_uuid ();
            // Create a string of the form "0000-0000-0000%%%Some really
            // nice display name"
            var target = "%s%%%%%%%s".printf(uuid, name);

            // TODO handle this case
            if (uuid == null) {
                GLib.print("%s had a null uuid.\n", name);
                continue;
            }

            if (Tardis.Utils.contains_str(backup_targets, target)) {
                continue;
            }

            new_drives = true;

            var item_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var icon = new Gtk.Image.from_gicon (vol.get_icon (), Gtk.IconSize.SMALL_TOOLBAR);
            var label = new Gtk.Label (name);
            item_box.add(icon);
            item_box.add(label);

            var item_button = new Gtk.ModelButton ();
            item_button.tooltip_text = _("Make %s a backup drive.".printf(name));
            item_button.get_child ().destroy ();
            item_button.add (item_box);
            item_button.clicked.connect (() => {
                var old_targets = settings.get_strv("backup-targets");
                old_targets += target;
                settings.set_strv("backup-targets", old_targets);
                drive_added ();
                build_add_target_menu ();
            });

            add_target_menu.add (item_button);
        }

        add_target_menu.show_all ();
        if (new_drives) {
            add_target_button.set_popover (add_target_popover);
        } else {
            add_target_button.set_popover (null);
        }
    }

    public signal void drive_added ();
}
