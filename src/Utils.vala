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

// Common business logic which does not directly change display properties.
public class Tardis.Utils {

    public static async Mount? get_mount (GLib.Volume volume) {
        var mount = volume.get_mount ();

        // If it was null try to mount it
        if (mount == null) {
            try {
                yield volume.mount (MountMountFlags.NONE, null);
            } catch (GLib.Error e) {
                return null;
            }

            mount = volume.get_mount ();
        }

        return mount;
    }

    public static bool array_not_equal (string[] arr1, string[] arr2) {
        if (arr1.length != arr2.length) {
            return false;
        }

        foreach (string element in arr1) {
            if (!Tardis.Utils.contains_str (arr2, element)) {
                return false;
            }
        }

        return true;
    }

    // Check if list contains target
    public static bool contains_str (string[] list, string target) {
        foreach (string element in list) {
            if (element == target) {
                return true;
            }
        }

        return false;
    }

    // Remove item from list
    public static string[] remove_from (string[] list, string item) {
        if (!contains_str (list, item)) {
            return list;
        }

        string[] new_list = new string[list.length - 1];
        foreach (string element in list) {
            if (element == item) {
                continue;
            }

            new_list += element;
        }

        return new_list;
    }
}
