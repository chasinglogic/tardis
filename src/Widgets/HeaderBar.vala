public class Tardis.Widgets.HeaderBar : Gtk.HeaderBar {
    private Gtk.MenuButton menu_button;
    private Gtk.Popover backup_settings_popover;
    private Gtk.Popover add_target_popover;
    private GLib.Settings settings;
    private GLib.VolumeMonitor vm;
    private Gtk.Box add_target_menu;
    private Gtk.MenuButton add_target_button;

    private Tardis.BackupTargetManager backup_target_manager;

    public HeaderBar (GLib.Settings settings,
                     GLib.VolumeMonitor vm,
                     Tardis.BackupTargetManager backup_target_manager) {

        this.vm = vm;
        this.settings = settings;
        this.backup_target_manager = backup_target_manager;

        show_close_button = true;

        var title = new Gtk.Label ("<b>Tardis</b>");
        title.use_markup = true;
        set_custom_title (title);

        var backup_data = new Tardis.Widgets.SettingToggler (
            // Add spaces to make switches line up
            _("Backup Data"),
            _("Indicates backups should include all non-hidden directories. " +
              "It is recommended to leave this setting on."),
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
        menu_grid.add (backup_data_model);
        menu_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add (backup_configuration_model);
        menu_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add (automatic_backups_model);
        menu_grid.show_all ();

        backup_settings_popover = new Gtk.Popover (null);
        backup_settings_popover.add (menu_grid);
        menu_button.popover = backup_settings_popover;

        var backup_button = new Gtk.Button ();
        backup_button.image = new Gtk.Image.from_icon_name (
            "folder-download",
             Gtk.IconSize.LARGE_TOOLBAR
        );
        backup_button.tooltip_text = _("Start a Backup");
        backup_button.clicked.connect (() => {
            backup_target_manager.backup_all.begin ();
        });

        add_target_menu = new Gtk.Box (Gtk.Orientation.VERTICAL, 6);
        add_target_menu.margin = 12;

        add_target_popover = new Gtk.Popover (null);
        add_target_popover.add (add_target_menu);

        add_target_button = new Gtk.MenuButton ();
        var add_target_image = new Gtk.Image.from_icon_name (
            "com.github.chasinglogic.tardis.add-backup-drive",
             Gtk.IconSize.LARGE_TOOLBAR
        );
        add_target_image.set_pixel_size (24);
        add_target_button.image = add_target_image;
        add_target_button.tooltip_text = _("Add Backup Drives");
        add_target_button.popover = add_target_popover;
        build_add_target_menu ();

        var info_button = new Gtk.Button ();
        info_button.image = new Gtk.Image.from_icon_name ("dialog-information",
                                                          Gtk.IconSize.LARGE_TOOLBAR);
        info_button.clicked.connect (() => {
            var dialog = new Gtk.Dialog ();
            dialog.set_transient_for (Tardis.App.window);

            var diag_box = dialog.get_content_area ();
            diag_box.orientation = Gtk.Orientation.VERTICAL;
            diag_box.margin = 12;

            var diag_title = new Gtk.Label (null);
            diag_title.use_markup = true;
            diag_title.margin = 6;
            diag_title.set_markup (
                "<b>%s v%s</b>\n".printf (_("Tardis"), Tardis.App.version) +
                _("A simple and powerful backup application."));

            var diag_body = new Gtk.Label (null);
            diag_body.margin = 6;
            diag_body.set_text (
                _("Tardis is brought to you by the work of these fine folks:\n" +
                  "\n    - Mathew Robinson (Lead Developer)" +
                  "\n    - Robert Green (UX Architect)" +
                  "\n    - Our open source contributors" +
                  "\n    - Anyone who has paid for this application" +
                  "\n\nBased on the awesome work of the Elementary OS team.")
            );

            diag_box.add (diag_title);
            diag_box.add (diag_body);

            dialog.show_all ();
        });

        pack_start (backup_button);
        pack_start (add_target_button);
        pack_end (info_button);
        pack_end (menu_button);
    }

    public void build_add_target_menu () {
        var volumes = vm.get_volumes ();
        if (volumes.length () == 0) {
            add_target_button.set_popover (null);
            return;
        }

        // Remove everything first
        add_target_menu.@foreach ((child) => {
            add_target_menu.remove (child);
        });
        var new_drives = false;
        var backup_targets = backup_target_manager.get_target_ids ();

        foreach (Volume vol in volumes) {
            var name = vol.get_drive ().get_name ();
            var uuid = vol.get_uuid ();

            // TODO handle this case
            if (uuid == null) {
                continue;
            }

            // TODO needs to be updated to handle objects
            if (Tardis.Utils.contains_str (backup_targets, uuid)) {
                continue;
            }

            new_drives = true;

            var item_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
            var icon = new Gtk.Image.from_gicon (vol.get_icon (), Gtk.IconSize.SMALL_TOOLBAR);
            var label = new Gtk.Label (name);
            item_box.add (icon);
            item_box.add (label);

            var item_button = new Gtk.ModelButton ();
            item_button.tooltip_text = _("Make %s a backup drive.".printf (name));
            item_button.get_child ().destroy ();
            item_button.add (item_box);
            item_button.clicked.connect (() => {
                backup_target_manager.add_volume (vol);
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
