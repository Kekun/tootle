using Gtk;

public class Tootle.Views.Search : Views.Base {

    private string query = "";
    private Entry entry;

    construct {
        content.margin_bottom = 6;

        entry = new Entry ();
        entry.placeholder_text = _("Search");
        entry.secondary_icon_name = "system-search-symbolic";
        entry.width_chars = 25;
        entry.text = query;
        entry.valign = Align.CENTER;
        entry.show ();
        window.header.pack_start (entry);

        destroy.connect (() => entry.destroy ());
        entry.activate.connect (() => request ());
        entry.icon_press.connect (() => request ());
    }

    public Search () {
        entry.grab_focus_without_selecting ();
    }

    private void append_account (API.Account acc) {
        var widget = new Widgets.Account (acc);
        content.pack_start (widget, false, false, 0);
    }

    private void append_status (API.Status status) {
        var widget = new Widgets.Status (status);
        widget.button_press_event.connect (widget.on_avatar_clicked);
        content.pack_start (widget, false, false, 0);
    }

    private void append_header (string name) {
        var widget = new Label (name);
        widget.get_style_context ().add_class ("h4");
        widget.halign = Align.START;
        widget.margin = 6;
        widget.margin_bottom = 0;
        widget.show ();
        content.pack_start (widget, false, false, 0);
    }

    private void append_hashtag (string name) {
        var text = "<a href=\"%s/tags/%s\">#%s</a>".printf (accounts.active.instance, Soup.URI.encode (name, null), name);
        var widget = new Widgets.RichLabel (text);
        widget.use_markup = true;
        widget.halign = Align.START;
        widget.margin = 6;
        widget.margin_bottom = 0;
        widget.show ();
        content.pack_start (widget, false, false, 0);
    }

    private void request () {
        query = entry.text;
        if (query == "") {
            clear ();
            return;
        }
        window.reopen_view (this.stack_pos);

        new Request.GET ("api/v1/search")
        	.with_account ()
        	.with_param ("resolve", "true")
        	.with_param ("q", Soup.URI.encode (query, null))
        	.then ((sess, msg) => {
                var root = network.parse (msg);
                var accounts = root.get_array_member ("accounts");
                var statuses = root.get_array_member ("statuses");
                var hashtags = root.get_array_member ("hashtags");

                clear ();

                if (accounts.get_length () > 0) {
                    append_header (_("Accounts"));
                    accounts.foreach_element ((array, i, node) => {
                        var obj = node.get_object ();
                        var acc = API.Account.parse (obj);
                        append_account (acc);
                    });
                }

                if (statuses.get_length () > 0) {
                    append_header (_("Statuses"));
                    statuses.foreach_element ((array, i, node) => {
                        var obj = node.get_object ();
                        var status = API.Status.parse (obj);
                        append_status (status);
                    });
                }

                if (hashtags.get_length () > 0) {
                    append_header (_("Hashtags"));
                    hashtags.foreach_element ((array, i, node) => {
                        append_hashtag (node.get_string ());
                    });
                }

                empty_state ();
        	})
        	.exec ();
    }

}
