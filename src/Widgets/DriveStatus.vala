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

public enum DriveStatusType {
    SAFE,
    BACKUP_ERROR,
    NEEDS_BACKUP,
    IN_PROGRESS,
    ADD_BUTTON,
}

public class Tardis.Widgets.DriveStatus : Gtk.ListBoxRow {

    private Gtk.Button restore_button;
    private Gtk.Button remove_button;
    private Gtk.Grid button_grid;
    private Gtk.Image drive_icon;
    private Gtk.Image status_icon;
    private Gtk.Label button_title;
    private Gtk.Spinner in_progress;

    private DriveStatusType current_status;

    public BackupTarget target;

    private BackupTargetManager backup_target_manager;
    private GLib.VolumeMonitor vm;

    public DriveStatus.add_drive_button (
        BackupTargetManager backup_target_manager,
        GLib.VolumeMonitor vm
    ) {
        this.target = new BackupTarget(
            "add-button",
            "add-button",
            "",
            0
        );
        this.backup_target_manager = backup_target_manager;
        this.vm = vm;

        // Title label
        button_title = new Gtk.Label ("<span size='large'>Add a new backup target</span>");
		button_title.use_markup = true;
        button_title.halign = Gtk.Align.START;
		button_title.vexpand = true;
        button_title.valign = Gtk.Align.CENTER;

        // Drive icon
        drive_icon = new Gtk.Image.from_icon_name ("list-add", Gtk.IconSize.SMALL_TOOLBAR);
        drive_icon.set_pixel_size (48);
		button_title.vexpand = true;
        button_title.valign = Gtk.Align.CENTER;

        // Button contents wrapper
        button_grid = new Gtk.Grid ();
        button_grid.column_spacing = 12;
		button_grid.hexpand = true;

        button_grid.attach (button_title, 2, 0, 1, 1);
        button_grid.attach (drive_icon, 1, 0, 1, 2);

        var add_target_button = new Gtk.Button ();

		var button_style_context = add_target_button.get_style_context ();
		button_style_context.add_class (Gtk.STYLE_CLASS_FLAT);

		add_target_button.add (button_grid);
        add_target_button.tooltip_text = _("Add a new backup target");
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
					var volume = add_target_selector.get_volume ();
                    volume_added (volume);
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

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_box.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        content_box.margin_top = 6;
        content_box.margin_bottom = 6;
        content_box.hexpand = true;
        content_box.add (add_target_button);

        current_status = DriveStatusType.ADD_BUTTON;

		activatable = false;
        selectable = false;
        add (content_box);
    }

    public DriveStatus (Tardis.BackupTarget target) {
        this.target = target;

        // Title label
        button_title = new Gtk.Label (target.display_name);
        button_title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        button_title.halign = Gtk.Align.START;
        button_title.valign = Gtk.Align.END;

        // Drive icon
        drive_icon = new Gtk.Image.from_icon_name (target.icon_name, Gtk.IconSize.SMALL_TOOLBAR);
        drive_icon.set_pixel_size (48);

        // Button contents wrapper
        button_grid = new Gtk.Grid ();
        button_grid.column_spacing = 12;

        button_grid.attach (button_title, 2, 0, 1, 1);
        button_grid.attach (drive_icon, 1, 0, 1, 2);

        var action_grid = new Gtk.Grid ();
        action_grid.hexpand = true;
        action_grid.halign = Gtk.Align.END;
        action_grid.column_spacing = 6;
        action_grid.orientation = Gtk.Orientation.HORIZONTAL;

        remove_button = new Gtk.Button.from_icon_name ("user-trash");
        remove_button.vexpand = true;
        remove_button.valign = Gtk.Align.CENTER;
        remove_button.set_size_request (32, 32);
        remove_button.tooltip_text = _("Stop backing up to this hard drive.");
        remove_button.clicked.connect (() => {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("You are about to stop backing up to this drive"),
                _("This will not remove any existing backups on this drive but " +
                  "will prevent future backups from being stored there. If you " +
                  "would like to also delete the backups you can remove the " +
                  "Tardis folder from the drive after removal from Tardis."),
                  "emblem-important",
                  Gtk.ButtonsType.NONE
            );

            var really_remove = new Gtk.Button.with_label (_("Don't backup to this drive"));
            really_remove.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var nope = new Gtk.Button.with_label (_("Cancel"));

            dialog.add_action_widget (nope, 0);
            dialog.add_action_widget (really_remove, 1);

            dialog.response.connect ((response_id) => {
                if (response_id == 1) {
                    drive_removed (target);
                    dialog.destroy ();
                    this.destroy ();
                }

                dialog.destroy ();
            });

            dialog.show_all ();
        });

        restore_button = new Gtk.Button.from_icon_name ("edit-undo");
        restore_button.vexpand = true;
        restore_button.valign = Gtk.Align.CENTER;
        restore_button.set_size_request (32, 32);
        restore_button.tooltip_text = _("Restore your system from this backup drive.");
        restore_button.clicked.connect (() => {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name (
                _("You are about to restore your system from this drive"),
                _("This will not remove any new files on your system which " +
                  "aren't in the backup. However, it will overwrite any " +
                  "files on your system which exist in the backup. Note " +
                  "that while a restore is running your system may " +
                  "behave in unexpected ways until it is complete. " +
                  "It's best to not use your computer while a restore " +
                  "is in progress."),
                  "emblem-important",
                  Gtk.ButtonsType.NONE
            );

            var really_restore = new Gtk.Button.with_label (_("Restore from this backup"));
            really_restore.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var nope = new Gtk.Button.with_label (_("Cancel"));

            dialog.add_action_widget (nope, 0);
            dialog.add_action_widget (really_restore, 1);

            dialog.response.connect ((response_id) => {
                if (response_id == 1) {
                    restore_from (target);
                }
                dialog.destroy ();
            });
            dialog.show_all ();
        });

        action_grid.attach (remove_button, 0, 0, 2, 2);
        action_grid.attach (restore_button, 2, 0, 2, 2);

        set_status (DriveStatusType.SAFE);

        var content_box = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        content_box.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        content_box.margin_top = 6;
        content_box.margin_bottom = 6;
        content_box.hexpand = true;
        content_box.add (button_grid);
        content_box.add (action_grid);

        selectable = false;
        add (content_box);
    }

    public void set_status (DriveStatusType status) {
        if (current_status == DriveStatusType.ADD_BUTTON) {
            return;
        }

        if (in_progress != null) {
            in_progress.destroy ();
        }

        if (status_icon != null) {
            status_icon.destroy ();
        }

        if (status == DriveStatusType.IN_PROGRESS) {
            in_progress = new Gtk.Spinner ();
            in_progress.start ();
            // Spinners are weirdly a little smaller than images so we set it's
            // size request to be a little bigger than 48.
            in_progress.set_size_request (52, 52);
            button_grid.attach (in_progress, 0, 0, 1, 2);

            restore_button.set_sensitive (false);
            remove_button.set_sensitive (false);

            button_grid.show_all ();
            current_status = status;
            return;
        }

        string icon_name = "";
        restore_button.set_sensitive (true);
        remove_button.set_sensitive (true);

        // If we're going to anything other than SAFE from ERROR then remain in
        // the error state.
        if (
            current_status == DriveStatusType.BACKUP_ERROR &&
            status != DriveStatusType.SAFE
        ) {
            icon_name = "process-stop";
        } else {
            switch (status) {
                case DriveStatusType.NEEDS_BACKUP:
                    icon_name = "dialog-warning";
                    break;
                case DriveStatusType.BACKUP_ERROR:
                    icon_name = "process-stop";
                    break;
                case DriveStatusType.SAFE:
                    icon_name = "process-completed";
                    break;
            }
        }

        current_status = status;

        status_icon = new Gtk.Image.from_icon_name (icon_name,
                                                    Gtk.IconSize.SMALL_TOOLBAR);
        status_icon.set_pixel_size (48);

        button_grid.attach (status_icon, 0, 0, 1, 2);
        button_grid.show_all ();
    }

    public signal void volume_added (GLib.Volume volume);
    public signal void drive_removed (BackupTarget target);
    public signal void restore_from (BackupTarget target);
}
