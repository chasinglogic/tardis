/*
* Copyright (c) 2020 Mathew Robinson (http://chasinglogic.io)
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

public class Tardis.Widgets.MainView : Gtk.Box {
    private Gtk.Grid content;
    private Gtk.ListBox drive_window_content;
    private Gtk.ScrolledWindow drive_window;
    private int num_targets;

    private Tardis.BackupTargetManager target_manager;

    public MainView (Tardis.BackupTargetManager target_manager, GLib.VolumeMonitor vm) {
        this.target_manager = target_manager;
        this.num_targets = 0;

        var separator = new Gtk.Separator (Gtk.Orientation.HORIZONTAL);

        drive_window_content = new Gtk.ListBox ();
        drive_window_content.expand = true;
        drive_window_content.margin = 12;

        foreach (BackupTarget target in target_manager.get_targets ()) {
            add_target (target);
        }

        var add_button = new DriveStatus.add_drive_button (target_manager, vm);
        add_button.volume_added.connect ((volume) => volume_added (volume));
        drive_window_content.add (add_button);

        drive_window = new Gtk.ScrolledWindow (null, null);
        drive_window.add (drive_window_content);

        content = new Gtk.Grid ();
        content.expand = true;
        content.orientation = Gtk.Orientation.VERTICAL;
        content.add (separator);
        content.add (drive_window);

        orientation = Gtk.Orientation.VERTICAL;
        get_style_context ().add_class (Gtk.STYLE_CLASS_VIEW);
        add (content);
    }

    public void add_target (BackupTarget target) {
        var drive_status = new Tardis.Widgets.DriveStatus (target);
        drive_status.drive_removed.connect ((target) => drive_removed (target));
        drive_status.restore_from.connect ((target) => restore_from (target));
        num_targets += 1;
        drive_window_content.insert (drive_status, num_targets - 1);
        drive_window_content.show_all ();
    }

    public void set_all (DriveStatusType status) {
        drive_window_content.@foreach ((child) => {
            var status_widget = (Tardis.Widgets.DriveStatus) child;
            status_widget.set_status (status);
        });
    }

    public void set_status (string id, DriveStatusType status) {
        drive_window_content.@foreach ((child) => {
            var status_widget = (Tardis.Widgets.DriveStatus) child;
            if (status_widget.target.id == id) {
                status_widget.set_status (status);
            }
        });
    }

    public signal void volume_added (GLib.Volume volume);
    public signal void drive_removed (BackupTarget target);
    public signal void restore_from (BackupTarget target);
}
