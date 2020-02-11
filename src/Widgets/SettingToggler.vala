public class Tardis.Widgets.SettingToggler : Gtk.Grid {

    public Gtk.CheckButton toggler_switch;

    public SettingToggler(string name, string description) {
        toggler_switch = new Gtk.CheckButton.with_label (name);
        toggler_switch.valign = Gtk.Align.START;
        toggler_switch.tooltip_text = description;

//         var toggler_description = new Gtk.Label (description);
//         toggler_description.max_width_chars = 25;
//         toggler_description.use_markup = true;
//         toggler_description.wrap = true;
//         toggler_description.xalign = 0;


        column_spacing = 1;
        row_spacing = 12;
        attach (toggler_switch, 0, 0);
        // attach (toggler_description, 0, 2, 2, 2);
    }
}
