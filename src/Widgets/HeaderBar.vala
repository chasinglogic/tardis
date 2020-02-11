public class Tardis.Widgets.HeaderBar : Gtk.HeaderBar {
    public Gtk.Label title;
    public Gtk.MenuButton menu_button;
    public Gtk.Popover backup_settings_popover;

    // TODO: add restore button
    // TODO: add new drive button
    public HeaderBar(Tardis.Settings settings,
                     Tardis.Widgets.BackupStatus status) {
        show_close_button = true;

        var backup_data = new Tardis.Widgets.SettingToggler (
            _("Backup Data"),
            _("Indicates backups should include all non-hidden directories. It is recommended to leave this setting on.")
        );
        backup_data.toggler_switch.active = settings.backup_data;
        backup_data.toggler_switch.toggled.connect (() => {
            settings.backup_data = backup_data.toggler_switch.active;
            status.get_backup_status.begin ();
        });

        var backup_configuration = new Tardis.Widgets.SettingToggler (
            _("Backup Configuration"),
            _("Indicates backups should include hidden directories. This is recommended for most users however, can sometimes cause issues when restoring backups.")
        );
        backup_configuration.toggler_switch.active = settings.backup_configuration;
        backup_configuration.toggler_switch.toggled.connect (() => {
            settings.backup_configuration = backup_configuration.toggler_switch.active;
            status.get_backup_status.begin ();
        });

        var automatic_backups = new Tardis.Widgets.SettingToggler (
            _("Automatically Backup"),
            _("""When backup targets are available and application is running
automatically start a backup without prompting. While convenient
this can cause issues when you want to restore from a drive. This
settings is only recommended for advanced users.""")
        );
        automatic_backups.toggler_switch.active = settings.automatic_backups;
        automatic_backups.toggler_switch.toggled.connect (() => {
            settings.automatic_backups = automatic_backups.toggler_switch.active;
        });


        menu_button = new Gtk.MenuButton ();
        menu_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        menu_button.tooltip_text = _("Backup Settings");

        var menu_grid = new Gtk.Grid ();
        menu_grid.margin_top = 12;
        menu_grid.margin_left = 24;
        menu_grid.margin_bottom = 12;
        menu_grid.row_spacing = 12;
        menu_grid.orientation = Gtk.Orientation.VERTICAL;
        menu_grid.width_request = 200;
        menu_grid.add(backup_data);
        menu_grid.add(new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add(backup_configuration);
        menu_grid.add(new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add(automatic_backups);
        menu_grid.show_all ();

        backup_settings_popover = new Gtk.Popover (null);
        backup_settings_popover.add (menu_grid);
        menu_button.popover = backup_settings_popover;

        title = new Gtk.Label("<b>Tardis</b>");
        title.use_markup = true;
        set_custom_title(title);
        pack_end (menu_button);
    }
}
