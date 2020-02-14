public class Tardis.Widgets.SettingToggler : Gtk.Grid {

    public Gtk.Switch toggler_switch;

    public SettingToggler (string name, string description, GLib.Settings settings, string setting_name) {
            var toggler_switch_label = new Gtk.Label (name);
            toggler_switch_label.halign = Gtk.Align.START;
            toggler_switch_label.vexpand = true;

            toggler_switch = new Gtk.Switch ();
            toggler_switch.valign = Gtk.Align.START;
            toggler_switch.halign = Gtk.Align.END;
            toggler_switch.hexpand = true;
            settings.bind (setting_name, toggler_switch, "active", GLib.SettingsBindFlags.DEFAULT);

            var toggler_switch_description = new Gtk.Label
                ("<small>%s</small>".printf (description));
            toggler_switch_description.max_width_chars = 30;
            toggler_switch_description.use_markup = true;
            toggler_switch_description.wrap = true;
            toggler_switch_description.xalign = 0;
            toggler_switch_description.get_style_context ().add_class (Gtk.STYLE_CLASS_DIM_LABEL);

            var toggler_switch_revealer = new Gtk.Revealer ();
            toggler_switch_revealer.add (toggler_switch_description);

            toggler_switch.bind_property (
                "active",
                toggler_switch_revealer,
                "reveal-child",
                GLib.BindingFlags.SYNC_CREATE
            );

            column_spacing = 6;
            attach (toggler_switch_label, 0, 0, 1, 1);
            attach (toggler_switch_revealer, 0, 2);
            attach (toggler_switch, 2, 0, 1, 1);
    }
}
