public class Tardis.Views.DriveSelectionView : Gtk.Box {

    private Tardis.Settings settings;
    private GLib.VolumeMonitor volume_monitor;

    private Gtk.Label drives_label;
    private Gtk.ListBox drive_list;

    private bool is_drive(string target) {
        // TODO(chasinglogic): make this better at UUID detection and not assume uuid drive name
        return target.contains("-");
    }

    private void add_drive() {

    }

    private void redraw_drives() {
        drive_list = new Gtk.ListBox ();

        foreach (string target in settings.backup_targets) {
            Gtk.Image icon;
            if (is_drive(target)) {
                icon = new Gtk.Image.from_icon_name("drive-harddisk", Gtk.IconSize.LARGE_TOOLBAR);
            } else {
                icon = new Gtk.Image.from_icon_name("drive", Gtk.IconSize.LARGE_TOOLBAR);
            }
            
            var label = new Gtk.Label(null);
            label.use_markup = true;
            label.set_markup("<span size='medium'>" + target + "</span>");
            
            var drive_box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 6);
            drive_box.add(icon);
            drive_box.add(label);

            var row = new Gtk.ListBoxRow();
            row.selectable = true;
            row.add(drive_box);

            drive_list.add(row);
        }
    }

    public DriveSelectionView(GLib.VolumeMonitor volume_monitor, Tardis.Settings settings) {
        orientation = Gtk.Orientation.VERTICAL;
        spacing = 12;
        margin = 24;

        this.settings = settings;
        this.volume_monitor = volume_monitor;
        
        var drives_label = new Gtk.Label (null);
        drives_label.use_markup = true;
        drives_label.set_markup("<span size='large' weight='bold'>Backup Targets</span>");

        var drives_label_row = new Tardis.Widgets.Row(drives_label);
        add(drives_label_row);

        redraw_drives();

        var drive_window = new Gtk.ScrolledWindow(null, null);
        drive_window.min_content_width = 250;
        drive_window.min_content_height = 100;
        drive_window.add(drive_list);

        var add_drive_controls = new Gtk.Toolbar ();
        add_drive_controls.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);
        add_drive_controls.icon_size = Gtk.IconSize.SMALL_TOOLBAR;

        var add_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        add_button.tooltip_text = _("Add Backup Drive…");
        // add_button.clicked.connect (() => {});

        var remove_button = new Gtk.ToolButton (new Gtk.Image.from_icon_name ("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR), null);
        remove_button.tooltip_text = _("Remove Backup Drive…");
        remove_button.sensitive = false;
        // remove_button.clicked.connect (remove_button_cb);

        add_drive_controls.add(add_button);
        add_drive_controls.add(remove_button);

        var drive_window_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        drive_window_box.add(drive_window);
        drive_window_box.add(add_drive_controls);

        var drive_window_row = new Tardis.Widgets.Row(drive_window_box);

        add(drive_window_row);
    }
}