public class Tardis.Widgets.HeaderBar : Gtk.HeaderBar {
    public Gtk.Label title_label;
    public Gtk.MenuButton menu_button;
    public Gtk.Popover backup_settings_popover;

    private Tardis.Backups backups;

    // TODO: add restore button
    // TODO: add new drive button
    public HeaderBar(GLib.Settings settings,
                     Tardis.Widgets.BackupStatus status,
                     Tardis.Backups backups) {

        this.backups = backups;
        show_close_button = true;

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

        title_label = new Gtk.Label("<b>Tardis</b>");
        title_label.use_markup = true;
        set_custom_title(title_label);

        var restore_button = new Gtk.MenuButton ();
        restore_button.image = new Gtk.Image.from_icon_name (
            "document-open-recent",
             Gtk.IconSize.LARGE_TOOLBAR
        );
        restore_button.tooltip_text = _("Restore from Backup");
        // restore_button.clicked.connect (() => {
        //     var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (
        //         "Are you sure?",
        //         "",
        //         "applications-development",
        //         Gtk.ButtonsType.CLOSE
        //     );
        // });

        var add_target_button = new Gtk.MenuButton ();
        // TODO: make a new icon that is drive-harddisk with a + sign
        add_target_button.image = new Gtk.Image.from_icon_name (
            "insert-object",
             Gtk.IconSize.LARGE_TOOLBAR
        );
        add_target_button.tooltip_text = _("Add a new Backup drive");

        pack_start(restore_button);
        pack_start(add_target_button);
        pack_end (menu_button);
    }
}
