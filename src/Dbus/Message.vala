using Json;

enum RequestType {
    RUN_BACKUPS,
    FORCE_RUN_BACKUPS,
    ADD_BACKUP_TARGET,
    ADD_BACKUP_FOLDER,
}

errordomain ParseError {
    UnrecognizedTypeString,
    InvalidMessage,
}

class Tardis.Dbus.Message {
    RequestType request_type { get; set; }
    string drive_id { get; set; }
    string folder_path { get; set; }

    private static RequestType request_type_from_string(string type_str) throws
        ParseError {
            if (type_str == "RUN_BACKUPS") {
                return RequestType.RUN_BACKUPS;
            } else if (type_str == "FORCE_RUN_BACKUPS") {
                return RequestType.FORCE_RUN_BACKUPS;
            } else if (type_str == "ADD_BACKUP_TARGET") {
                return RequestType.ADD_BACKUP_TARGET;
            } else if (type_str == "ADD_BACKUP_FOLDER") {
                return RequestType.ADD_BACKUP_FOLDER;
            } else {
                throw new ParseError.UnrecognizedTypeString (type_str);
            }
        }

    public string to_json() {
        var gen = new Generator();
        var root = new Json.Node(NodeType.OBJECT);
        var object = new Json.Object();
        root.set_object(object);
        gen.set_root(root);

        if (request_type == RequestType.ADD_BACKUP_TARGET) {
            object.set_string_member("request_type", "ADD_BACKUP_TARGET");
            object.set_string_member("drive_id", drive_id);
        } else if (request_type == RequestType.ADD_BACKUP_FOLDER) {
            object.set_string_member("request_type", "ADD_BACKUP_FOLDER");
            object.set_string_member("folder_path", folder_path);
        } else if (request_type == RequestType.RUN_BACKUPS) {
            object.set_string_member("request_type", "RUN_BACKUPS");
        } else if (request_type == RequestType.FORCE_RUN_BACKUPS) {
            object.set_string_member("request_type", "FORCE_RUN_BACKUPS");
        }

        size_t length;
        return gen.to_data(out length);
    }

    Message(string json_string) throws ParseError {
        var parser = new Json.Parser ();
        try {
            parser.load_from_data (json_string, -1);
        } catch (GLib.Error e) {
            throw new ParseError.InvalidMessage ("Invalid DBus message");
        }

        var root_obj = parser.get_root ().get_object ();

        request_type =
            Tardis.Dbus.Message.request_type_from_string (root_obj.get_string_member
                                                          ("type"));

        if (request_type == RequestType.ADD_BACKUP_TARGET) {
            drive_id = root_obj.get_string_member ("drive_id");
        }
    }
}
