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

public class Tardis.Widgets.HeaderBar : Gtk.HeaderBar {
    private GLib.VolumeMonitor vm;

    private Gtk.Button add_target_button;

    private Gtk.MenuButton backup_settings_button;
    private Gtk.Popover backup_settings_popover;

    private Gtk.Dialog? info_dialog = null;

    private Tardis.BackupTargetManager backup_target_manager;

    public HeaderBar (GLib.VolumeMonitor vm,
                      Tardis.BackupTargetManager backup_target_manager,
                      GLib.Settings settings) {

        this.vm = vm;
        this.backup_target_manager = backup_target_manager;

        var title = new Gtk.Label ("<b>" + _("Tardis") + "</b>");
        title.use_markup = true;

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
            _("When backup targets are available and application is running " +
              "automatically start a backup without prompting. While convenient " +
              "this can cause issues when you want to restore from a drive. This " +
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

        backup_settings_button = new Gtk.MenuButton ();
        backup_settings_button.image = new Gtk.Image.from_icon_name ("open-menu", Gtk.IconSize.LARGE_TOOLBAR);
        backup_settings_button.tooltip_text = _("Backup Settings");

        var info_label = new Gtk.Label ("About Tardis");
        var info_icon = new Gtk.Image.from_icon_name (
            "dialog-information-symbolic",
            Gtk.IconSize.SMALL_TOOLBAR
            );
        var info_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 6);
        info_box.add (info_icon);
        info_box.add (info_label);

        var info_button_model = new Gtk.ModelButton ();
        info_button_model.get_child ().destroy ();
        info_button_model.add (info_box);
        info_button_model.clicked.connect (() => {
                info_dialog = new Gtk.Dialog ();
                info_dialog.set_transient_for (Tardis.App.window);

                var diag_box = info_dialog.get_content_area ();
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
                      "\n\nBased on the awesome work of the elementary OS team.")
                    );

                diag_box.add (diag_title);
                diag_box.add (diag_body);

                info_dialog.show_all ();
            });

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
        menu_grid.add (new Gtk.Separator (Gtk.Orientation.HORIZONTAL));
        menu_grid.add (info_button_model);
        menu_grid.show_all ();

        backup_settings_popover = new Gtk.Popover (null);
        backup_settings_popover.add (menu_grid);
        backup_settings_button.popover = backup_settings_popover;

        var backup_button = new Gtk.Button ();
        backup_button.image = new Gtk.Image.from_icon_name (
            "view-refresh",
            Gtk.IconSize.LARGE_TOOLBAR
            );
        backup_button.tooltip_text = _("Start a Backup");
        backup_button.clicked.connect (() => {
                backup_target_manager.backup_all.begin ();
            });

        add_target_button = new Gtk.Button ();
        var add_target_image = new Gtk.Image.from_icon_name (
            "com.github.chasinglogic.tardis.add-backup-drive",
            Gtk.IconSize.LARGE_TOOLBAR
            );
        add_target_image.set_pixel_size (24);
        add_target_button.image = add_target_image;
        add_target_button.tooltip_text = _("Add Backup Drives");
        add_target_button.clicked.connect (() => {
                var add_target_dlg = new Gtk.Dialog ();
                add_target_dlg.set_default_size (200, 100);
                add_target_dlg.set_transient_for (Tardis.App.window);

                var add_target_box = add_target_dlg.get_content_area ();
                add_target_box.margin = 12;

                var add_target_selector = new Tardis.Widgets.DriveSelector (backup_target_manager, vm);
                add_target_selector.margin = 12;

                var add_target_msg = new Gtk.Label (
                    _("To ensure a successful backup to the selected drive, " +
                      "make sure you have permissions to create folders " +
                      "and files on the drive. Additionally, if the drive " +
                      "is encrypted make sure that's already mounted via " +
                      "the Files app.")
                    );
                add_target_msg.margin = 12;
                add_target_msg.wrap = true;
                add_target_msg.max_width_chars = 20;

                add_target_box.add (add_target_selector);
                add_target_box.add (add_target_msg);

                add_target_dlg.response.connect ((id) => {
                        if (id == 1) {
                            volume_added (add_target_selector.get_volume ());
                        }

                        add_target_dlg.destroy ();
                    });

                var confirm_button = new Gtk.Button.with_label (_("Backup to this Drive"));
                confirm_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);

                var cancel_button = new Gtk.Button.with_label (_("Cancel"));

                add_target_dlg.add_action_widget (cancel_button, 0);
                add_target_dlg.add_action_widget (confirm_button, 1);

                add_target_dlg.show_all ();
            });

        show_close_button = true;
        set_custom_title (title);
        pack_start (backup_button);
        // pack_start (add_target_button);
        pack_end (backup_settings_button);
    }

    public signal void volume_added (GLib.Volume volume);
}
