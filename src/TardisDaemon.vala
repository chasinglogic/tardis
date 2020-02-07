

[DBus (name = "com.github.chasinglogic.tardis")]
public class Tardis.Server : Object {
    private Tardis.Settings settings;

    public Server(Tardis.Settings settings) {
        this.settings = settings;
    }
}

public class Tardis.Daemon {

    private static void on_bus_acquired(DBusConnection conn) {
        try {
            var settings = Tardis.Settings.get_instance();
            conn.register_object("/com/github/chasinglogic/tardis", new
                                 Tardis.Server(settings));
        } catch (IOError e) {
            stderr.printf("Could not register service\n");
        }
    }

    public static void main(string[] args){
        Bus.own_name(BusType.SESSION, "com.github.chasinglogic.tardis",
                     BusNameOwnerFlags.NONE, on_bus_acquired,
                     () => {},
                     () => stderr.printf("Could not acquired name\n"));
        new MainLoop().run();
    }

}


