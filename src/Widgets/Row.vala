
// Used as a Row in a single column box layout.
public class Tardis.Widgets.Row : Gtk.Box {

    public Row (Gtk.Widget widget, int row_spacing = 6) {
        spacing = row_spacing;
        orientation = Gtk.Orientation.HORIZONTAL;
        set_center_widget (widget);
    }

}
