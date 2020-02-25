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

using Gtk;

public class Tardis.App : Gtk.Application {

    public static string id = "com.github.chasinglogic.tardis";
    public static string version = "1.2.0";

    public static int default_window_height = 512;
    public static int default_window_width = 700;

    public static string unsafe_msg = _("A backup is needed and no backup drives are available.");
    public static string out_of_date_msg = _("We've detected some of your backups are out of date.");
    public static string in_progress = _("Backup in progress. Please don't unplug any storage devices.");

    // Main ApplicationWindow, is static so it can be referenced by Dialogs.
    public static Gtk.ApplicationWindow window;

    // GLib settings accessor
    public GLib.Settings settings;
    // VolumeMonitor for interacting with drives
    public GLib.VolumeMonitor volume_monitor;

    // Main classes
    public Tardis.BackupTargetManager target_manager;
    public Tardis.BackupStatus backup_status;

    // Custom Widgets
    public Tardis.Widgets.HeaderBar headerbar;
    public Tardis.Widgets.MainView main_view;

    // Widgets directly attached to the Application Window
    public Gtk.InfoBar error_bar;
    public Gtk.Label error_msg_label;

    public Gtk.InfoBar warning_bar;
    public Gtk.Label warning_msg_label;

    public Gtk.InfoBar info_bar;
    public Gtk.Label info_msg_label;

    public App () {
        Object (
            application_id: id,
            flags: ApplicationFlags.FLAGS_NONE
            );
    }

    // Store window size in gsettings when resized.
    public void on_resize () {
        if (!window.is_maximized) {
            int width;
            int height;
            window.get_size (out width, out height);
            if (settings.get_int ("window-height") != height || settings.get_int ("window-width") != width) {
                settings.set_int ("window-height", height);
                settings.set_int ("window-width", width);
            }
        }

        settings.set_boolean ("window-maximized", window.is_maximized);
    }

    protected override void activate () {
        settings = new GLib.Settings (id);
        volume_monitor = GLib.VolumeMonitor.@get ();

        target_manager = new Tardis.BackupTargetManager (volume_monitor, settings);
        backup_status = new Tardis.BackupStatus (target_manager);
        main_view = new Tardis.Widgets.MainView (target_manager, volume_monitor);
        headerbar = new Tardis.Widgets.HeaderBar (volume_monitor, target_manager, settings);

        error_msg_label = new Gtk.Label (null);
        error_msg_label.use_markup = true;

        error_bar = new Gtk.InfoBar ();
        error_bar.show_close_button = true;
        error_bar.message_type = Gtk.MessageType.ERROR;
        error_bar.revealed = false;
        error_bar.get_content_area ().add (error_msg_label);

        warning_msg_label = new Gtk.Label (null);
        warning_msg_label.use_markup = true;

        warning_bar = new Gtk.InfoBar ();
        warning_bar.message_type = Gtk.MessageType.WARNING;
        warning_bar.revealed = false;
        warning_bar.show_close_button = true;
        warning_bar.get_content_area ().add (warning_msg_label);

        info_msg_label = new Gtk.Label (null);
        info_msg_label.use_markup = true;

        info_bar = new Gtk.InfoBar ();
        info_bar.show_close_button = false;
        info_bar.message_type = Gtk.MessageType.INFO;
        info_bar.revealed = false;
        info_bar.get_content_area ().add (info_msg_label);

        var window_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        window_box.add (info_bar);
        window_box.add (warning_bar);
        window_box.add (error_bar);
        window_box.add (main_view);

        // Construct the main window for our Application.
        window = new Gtk.ApplicationWindow (this);
        if (settings.get_boolean ("first-run")) {
            settings.set_int ("window-width", default_window_width);
            settings.set_int ("window-height", default_window_height);
        }

        if (settings.get_boolean ("window-maximized")) {
            window.maximize ();
        } else {
            window.default_width = settings.get_int ("window-width");
            window.default_height = settings.get_int ("window-height");
        }

        window.set_titlebar (headerbar);
        window.add (window_box);
        window.show_all ();
        window.size_allocate.connect (() => { on_resize (); });

        // Cross the Signals
        backup_status.target_is_backed_up.connect ((target) => {
            main_view.set_status (target.id, DriveStatusType.SAFE);
        });

        backup_status.target_needs_backup.connect ((target) => {
            main_view.set_status (target.id, DriveStatusType.NEEDS_BACKUP);
        });

        backup_status.out_of_date.connect (() => {
            if (settings.get_boolean ("automatic-backups")) {
                target_manager.backup_all.begin ();
            } else {
                warning_message (out_of_date_msg, null);
            }
        });

        backup_status.unsafe.connect ((msg) => {
            if (msg != null) {
                error_message (msg);
            } else {
                error_message (unsafe_msg);
            }
        });

        backup_status.calculating.connect (() => {
            main_view.set_all (DriveStatusType.IN_PROGRESS);
        });

        main_view.volume_added.connect ((volume) => {
                target_manager.add_volume.begin (volume);
        });

        main_view.drive_removed.connect ((target) => {
            target_manager.remove_target (target);
        });

        main_view.restore_from.connect ((target) => {
            target_manager.restore_from.begin (target);
        });

        target_manager.target_added.connect ((target, start_backup) => {
            backup_status.get_backup_status.begin ();
            main_view.add_target (target);
            if (start_backup) {
                target_manager.backup_all.begin ();
            }
        });

        target_manager.backup_started.connect ((target) => {
            hide_warning ();
            if (!info_bar.revealed) {
                info_message (_("Backup in progress. Please do not unplug any storage devices."));
            }

            var notification = new Notification (_("Backup started!"));
            var icon = new GLib.ThemedIcon (id);
            notification.set_icon (icon);
            notification.set_body (_("Backing up to:") + " %s".printf (target.display_name));
            this.send_notification (id, notification);

            main_view.set_status (target.id, DriveStatusType.IN_PROGRESS);
        });

        target_manager.backup_complete.connect ((target) => {
            main_view.set_status (target.id, DriveStatusType.SAFE);

            if (info_bar.revealed) {
                info_bar.hide ();
            }

            var notification = new Notification (_("Backup complete!"));
            var icon = new GLib.ThemedIcon (id);
            notification.set_icon (icon);
            notification.set_body (_("%s is now up to date.").printf (target.display_name));

            this.send_notification (id, notification);
        });

        target_manager.restore_started.connect ((target) => {
            main_view.set_status (target.id, DriveStatusType.IN_PROGRESS);

            if (info_bar.revealed) {
                info_message (
                    "Restore in progress. Please do not unplug any storage devices. " +
                    "Your system may behave strangely until the restore is complete.");
            }

            var notification = new Notification (_("Restore started!"));
            var icon = new GLib.ThemedIcon (id);
            notification.set_icon (icon);
            notification.set_body (_("Restoring your system from: %s").printf (target.display_name));

            this.send_notification (id, notification);
        });

        target_manager.restore_complete.connect ((target) => {
            main_view.set_status (target.id, DriveStatusType.SAFE);

            if (info_bar.revealed) {
                info_bar.hide ();
            }

            var notification = new Notification (_("Restore complete!"));
            var icon = new GLib.ThemedIcon (id);
            notification.set_icon (icon);
            notification.set_body (_("Your system data now matches: %s").printf (target.display_name));

            this.send_notification (id, notification);
        });

        target_manager.backup_error.connect ((target, err_msg) => {
            main_view.set_status (target.id, DriveStatusType.BACKUP_ERROR);
            this.error_message (err_msg);
        });

        target_manager.save_error.connect ((err_msg) => {
            this.error_message (err_msg);
        });

        settings.changed.connect ((key) => {
            if (key == "backup-configuration" || key == "backup-data") {
                backup_status.get_backup_status.begin ();
            }
        });

        volume_monitor.volume_added.connect (() => {
            error_bar.hide ();
        });

        if (settings.get_boolean ("first-run")) {
            var onboarding = new Onboarding (this);
            onboarding.show_all ();
        } else {
            backup_status.get_backup_status.begin ();
        }
    }

    public void error_message (string msg) {
        if (warning_bar.revealed) {
            warning_bar.hide ();
        }

        error_msg_label.set_markup ("<b>%s</b>".printf (msg));
        error_bar.revealed = true;
        error_bar.response.connect ((_id) => error_bar.hide ());
    }

    public void warning_message (string msg, Gtk.Widget? action) {
        if (error_bar.revealed) {
            return;
        }

        warning_msg_label.set_markup ("<b>%s</b>".printf (msg));
        warning_bar.revealed = true;
        warning_bar.response.connect ((_id) => warning_bar.hide ());
    }

    public void hide_warning () {
        warning_bar.hide ();
    }

    public void info_message (string msg) {
        info_msg_label.set_markup ("<b>%s</b>".printf (msg));
        info_bar.revealed = true;
        info_bar.response.connect ((_id) => info_bar.hide ());
    }

    public static int main (string[] args) {
        var app = new Tardis.App ();
        var return_code = app.run (args);
        app.settings.set_boolean ("first-run", false);
        app.target_manager.write_state ();
        return return_code;
    }
}
