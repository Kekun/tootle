using Gtk;

public class Tootle.Views.Followers : Views.Timeline {

    public Followers (API.Account account) {
        base (account.id.to_string ());
    }

    public new void append (API.Account account) {
        if (empty != null)
            empty.destroy ();

        var separator = new Separator (Orientation.HORIZONTAL);
        separator.show ();

        var widget = new Widgets.Account (account);
        widget.separator = separator;
        content.pack_start (separator, false, false, 0);
        content.pack_start (widget, false, false, 0);
    }

    public override string get_url () {
        if (page_next != null)
            return page_next;

        var url = "%s/api/v1/accounts/%s/followers".printf (accounts.active.instance, this.timeline);
        return url;
    }

    public override void request () {
    	new Request.GET (get_url ())
    		.with_account ()
    		.then_parse_array ((node, msg) => {
                var obj = node.get_object ();
                if (obj != null){
                    var status = API.Account.parse (obj);
                    append (status);
                }

                get_pages (msg.response_headers.get_one ("Link"));
                empty_state ();
    		})
    		.on_error (network.on_error)
    		.exec ();
    }

}
