public enum DriveStatusType {
    SAFE,
    BACKUP_ERROR,
    NEEDS_BACKUP,
    IN_PROGRESS,
}

public class Tardis.Widgets.DriveStatus : Gtk.Box {
    public Gtk.Grid button_grid;
    public Gtk.Label button_title;
    public Gtk.Label button_description;
    public Gtk.Image drive_icon;
    public Gtk.Image status_icon;
    public Gtk.Spinner in_progress;

    private DriveStatusType last_status;

    public BackupTarget target;

    public DriveStatus (Tardis.BackupTarget target) {
        this.target = target;
        redraw ();
    }

    public signal void drive_removed (BackupTarget target);
    public signal void restore_from (BackupTarget target);

    public void redraw () {
        // Title label
        button_title = new Gtk.Label (target.display_name);
        button_title.get_style_context ().add_class (Granite.STYLE_CLASS_H3_LABEL);
        button_title.halign = Gtk.Align.START;
        button_title.valign = Gtk.Align.END;

        get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);

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

        var remove_button = new Gtk.Button.from_icon_name ("user-trash");
        remove_button.set_size_request(24, 24);
        remove_button.tooltip_text = "Stop backing up to this hard drive.";
        remove_button.clicked.connect (() => {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name(
                _("You are about to stop backing up to this drive"),
                _("This will not remove any existing backups on this drive but " +
                  "will prevent future backups from being stored there. If you " +
                  "would like to also delete the backups you can remove the " +
                  "Tardis folder from the drive after removal from Tardis."),
                  "emblem-important",
                  Gtk.ButtonsType.NONE
            );

            var really_remove = new Gtk.Button.with_label ("Don't backup to this drive");
            really_remove.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var nope = new Gtk.Button.with_label ("Cancel");

            dialog.add_action_widget(nope, 0);
            dialog.add_action_widget(really_remove, 1);

            dialog.response.connect((response_id) => {
                if (response_id == 1) {
                    drive_removed (target);
                    this.destroy ();
                }
                dialog.destroy ();
            });
            dialog.show_all ();
        });

        var restore_button = new Gtk.Button.from_icon_name ("edit-undo");
        restore_button.set_size_request(24, 24);
        restore_button.tooltip_text = "Restore your system from this backup drive.";
        restore_button.clicked.connect (() => {
            var dialog = new Granite.MessageDialog.with_image_from_icon_name(
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

            var really_restore = new Gtk.Button.with_label ("Restore from this backup");
            really_restore.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);

            var nope = new Gtk.Button.with_label ("Cancel");

            dialog.add_action_widget(nope, 0);
            dialog.add_action_widget(really_restore, 1);

            dialog.response.connect((response_id) => {
                if (response_id == 1) {
                    restore_from (target);
                }
                dialog.destroy ();
            });
            dialog.show_all ();
        });

        action_grid.attach (remove_button, 0, 0, 2, 2);
        action_grid.attach (restore_button, 2, 0, 2, 2);

        add (button_grid);
        add (action_grid);
        orientation = Gtk.Orientation.HORIZONTAL;
        hexpand = true;

        if (target.needs_backup ()) {
            set_status (DriveStatusType.NEEDS_BACKUP);
        } else {
            set_status (DriveStatusType.SAFE);
        }
    }

    public void set_status(DriveStatusType status) {
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
            in_progress.set_size_request(52, 52);
            button_grid.attach (in_progress, 0, 0, 1, 2);
            button_grid.show_all ();
            last_status = status;
            return;
        }

        string icon_name = "";

        // If we're going to anything other than SAFE from ERROR then remain in
        // the error state.
        if (
            last_status == DriveStatusType.BACKUP_ERROR &&
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

        last_status = status;

        status_icon = new Gtk.Image.from_icon_name (icon_name,
                                                    Gtk.IconSize.SMALL_TOOLBAR);
        status_icon.set_pixel_size (48);
        GLib.print("setting status to icon: %s\n", icon_name);

        button_grid.attach (status_icon, 0, 0, 1, 2);
        button_grid.show_all ();
    }
}


