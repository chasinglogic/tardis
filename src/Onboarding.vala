public class Tardis.Onboarding : Gtk.Window {
    public Onboarding (Tardis.App app) {
        var app_icon = new Gtk.Image.from_icon_name ("com.github.chasinglogic.tardis", Gtk.IconSize.LARGE_TOOLBAR);
        app_icon.set_pixel_size (48);

        var title_label = new Gtk.Label (_("Welcome to Tardis"));
        title_label.get_style_context ().add_class (Granite.STYLE_CLASS_H2_LABEL);
        title_label.halign = Gtk.Align.CENTER;

        var description_label = new Gtk.Label (
            _("At it's core Tardis manages backup targets. You can have " +
            "multiple backup targets in Tardis. But to start, let's " +
            "add a single drive. Plug in the storage device you " +
            "would like to store backups on and select it from the " +
            "drop down below. To ensure a successful backup to the " +
            "selected drive, make sure you have permissions to create " +
            "folders and files on the drive.")
            );
        description_label.halign = Gtk.Align.CENTER;
        description_label.justify = Gtk.Justification.CENTER;
        description_label.wrap = true;
        description_label.max_width_chars = 60;
        description_label.use_markup = true;

        var header_area = new Gtk.Grid ();
        header_area.column_spacing = 12;
        header_area.halign = Gtk.Align.CENTER;
        header_area.expand = true;
        header_area.row_spacing = 12;
        header_area.orientation = Gtk.Orientation.VERTICAL;
        header_area.add (app_icon);
        header_area.add (title_label);
        header_area.add (description_label);

        var add_backup_selector = new Tardis.Widgets.DriveSelector (app.target_manager, app.volume_monitor);

        // Finish setting up the onboarding chrome
        var finish_button = new Gtk.Button.with_label (_("Start Protecting My Data"));
        finish_button.get_style_context ().add_class (Gtk.STYLE_CLASS_SUGGESTED_ACTION);
        finish_button.clicked.connect (() => {
            app.target_manager.add_target (add_backup_selector.create_backup_target ());
            destroy ();
        });
        finish_button.grab_focus ();

        var action_area = new Gtk.ButtonBox (Gtk.Orientation.HORIZONTAL);
        action_area.margin_start = action_area.margin_end = 10;
        action_area.expand = true;
        action_area.spacing = 6;
        action_area.valign = Gtk.Align.END;
        action_area.layout_style = Gtk.ButtonBoxStyle.EDGE;
        action_area.add (finish_button);

        var grid = new Gtk.Grid ();
        grid.margin = 12;
        grid.orientation = Gtk.Orientation.VERTICAL;
        grid.add (header_area);
        grid.add (add_backup_selector);
        grid.add (action_area);

        var titlebar = new Gtk.HeaderBar ();
        titlebar.get_style_context ().add_class ("default-decoration");
        titlebar.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        titlebar.set_custom_title (new Gtk.Label (null));

        int width;
        int height;
        Tardis.App.window.get_size (out width, out height);

        default_height = height / 2;
        default_width = width / 2;

        get_style_context ().add_class ("rounded");
        set_titlebar (titlebar);
        add (grid);
    }

    public signal void target_created (Tardis.BackupTarget target);
}
