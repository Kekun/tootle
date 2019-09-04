using Gtk;
using Granite;

namespace Tootle {

    public errordomain Oopsie {
        USER,
    	PARSING,
    	INSTANCE
    }

    public static Application app;
    public static Dialogs.MainWindow? window;
    public static Window window_dummy;

    public static Settings settings;
    public static Accounts accounts;
    public static Network network;
    public static ImageCache image_cache;
    public static Watchlist watchlist;

    public static bool start_hidden = false;

    public class Application : Granite.Application {

        // These are used for the GTK Inspector
        public Settings app_settings { get {return Tootle.settings; } }
        public Accounts app_accounts { get {return Tootle.accounts; } }
        public Network app_network { get {return Tootle.network; } }
        public ImageCache app_cache { get {return Tootle.image_cache; } }
        public Watchlist app_watchlist { get {return Tootle.watchlist; } }

        public abstract signal void refresh ();
        public abstract signal void toast (string title);
        public abstract signal void error (string title, string text);

        public const GLib.OptionEntry[] app_options = {
            { "hidden", 0, 0, OptionArg.NONE, ref start_hidden, "Do not show main window on start", null },
            { null }
        };

        public const GLib.ActionEntry[] app_entries = {
            {"compose-toot",    compose_toot_activated          },
            {"toggle-reveal",   on_sensitive_toggled            },
            {"back",            back_activated                  },
            {"refresh",         refresh_activated               },
            {"switch-timeline", switch_timeline_activated, "i"  }
        };

        construct {
            application_id = Build.DOMAIN;
            flags = ApplicationFlags.FLAGS_NONE;
            program_name = Build.NAME;
            build_version = Build.VERSION;
        }

        public string[] ACCEL_NEW_POST = {"<Ctrl>T"};
        public string[] ACCEL_TOGGLE_REVEAL = {"<Ctrl>S"};
        public string[] ACCEL_BACK = {"<Alt>BackSpace", "<Alt>Left"};
        public string[] ACCEL_REFRESH = {"<Ctrl>R", "F5"};
        public string[] ACCEL_TIMELINE_0 = {"<Alt>1"};
        public string[] ACCEL_TIMELINE_1 = {"<Alt>2"};
        public string[] ACCEL_TIMELINE_2 = {"<Alt>3"};
        public string[] ACCEL_TIMELINE_3 = {"<Alt>4"};

        public static int main (string[] args) {
            Gtk.init (ref args);

            try {
                var opt_context = new OptionContext ("- Options");
                opt_context.add_main_entries (app_options, null);
                opt_context.parse (ref args);
            }
            catch (GLib.OptionError e) {
                warning (e.message);
            }

            app = new Application ();
            return app.run (args);
        }

        protected override void startup () {
            base.startup ();
            Granite.Services.Logger.DisplayLevel = Granite.Services.LogLevel.INFO;

            settings = new Settings ();
            accounts = new Accounts ();
            network = new Network ();
            image_cache = new ImageCache ();
            watchlist = new Watchlist ();
            accounts.init ();

            app.error.connect (app.on_error);

            window_dummy = new Window ();
            add_window (window_dummy);

            set_accels_for_action ("app.compose-toot", ACCEL_NEW_POST);
            set_accels_for_action ("app.toggle-reveal", ACCEL_TOGGLE_REVEAL);
            set_accels_for_action ("app.back", ACCEL_BACK);
            set_accels_for_action ("app.refresh", ACCEL_REFRESH);
            set_accels_for_action ("app.switch-timeline(0)", ACCEL_TIMELINE_0);
            set_accels_for_action ("app.switch-timeline(1)", ACCEL_TIMELINE_1);
            set_accels_for_action ("app.switch-timeline(2)", ACCEL_TIMELINE_2);
            set_accels_for_action ("app.switch-timeline(3)", ACCEL_TIMELINE_3);
            add_action_entries (app_entries, this);
        }

        protected override void activate () {
            if (window != null) {
                window.present ();
                return;
            }

            if (start_hidden) {
                start_hidden = false;
                return;
            }

            debug ("Creating new window");
            window = new Dialogs.MainWindow (this);
            window.present ();
        }

        protected void on_error (string title, string msg){
            var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (title, msg, "dialog-warning");
            message_dialog.transient_for = window;
            message_dialog.run ();
            message_dialog.destroy ();
        }

        private void on_sensitive_toggled () {
            window.button_reveal.clicked ();
        }

        private void compose_toot_activated () {
            Dialogs.Compose.open ();
        }

        private void back_activated () {
            window.back ();
        }

        private void refresh_activated () {
            refresh ();
        }

        private void switch_timeline_activated (SimpleAction a, Variant? parameter) {
            int32 timeline_no = parameter.get_int32 ();
            window.switch_timeline (timeline_no);
        }

    }

}
