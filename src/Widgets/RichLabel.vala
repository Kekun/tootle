using Gtk;
using Gee;

public class Tootle.Widgets.RichLabel : Label {

    public weak ArrayList<API.Mention>? mentions;

	construct {
		use_markup = true;
		activate_link.connect (open_link);
	}

    public RichLabel (string text) {
        set_label (text);
    }

    public static string escape_entities (string content) {
        return content
               .replace ("&nbsp;", " ")
               .replace ("'", "&apos;");
    }

    public static string restore_entities (string content) {
        return content
               .replace ("&amp;", "&")
               .replace ("&lt;", "<")
               .replace ("&gt;", ">")
               .replace ("&apos;", "'")
               .replace ("&quot;", "\"");
    }

    public new void set_label (string text) {
        base.set_markup (Html.simplify(escape_entities (text)));
    }

    public void wrap_words () {
        halign = Align.START;
        single_line_mode = false;
        set_line_wrap (true);
        wrap_mode = Pango.WrapMode.WORD_CHAR;
        justify = Justification.LEFT;
        xalign = 0;
    }

    public bool open_link (string url) {
        if ("tootle://" in url)
            return false;

        if (mentions != null){
            mentions.@foreach (mention => {
                if (url == mention.url)
                    Views.Profile.open_from_id (mention.id);
                return true;
            });
        }

        if ("/tags/" in url) {
            var encoded = url.split("/tags/")[1];
            var hashtag = Soup.URI.decode (encoded);
            window.open_view (new Views.Hashtag (hashtag));
            return true;
        }

        if ("@" in url || "tags" in url) {
            new Request.GET ("/api/v1/search")
                .with_account ()
                .with_param ("resolve", "true")
                .with_param ("q", Soup.URI.encode (url, null))
                .then ((sess, mess) => {
                    var root = network.parse (mess);
                    var accounts = root.get_array_member ("accounts");
                    var statuses = root.get_array_member ("statuses");
                    var hashtags = root.get_array_member ("hashtags");

                    if (accounts.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = API.Account.parse (item);
                        window.open_view (new Views.Profile (obj));
                    }
                    else if (statuses.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = API.Status.parse (item);
                        window.open_view (new Views.ExpandedStatus (obj));
                    }
                    else if (hashtags.get_length () > 0) {
                        var item = accounts.get_object_element (0);
                        var obj = API.Tag.parse (item);
                        window.open_view (new Views.Hashtag (obj.name));
                    }
                    else {
                        Desktop.open_uri (url);
                    }
                })
                .on_error ((status, reason) => open_link_fallback (url, reason))
                .exec ();
        }
        else {
            Desktop.open_uri (url);
        }
        return true;
    }

    public bool open_link_fallback (string url, string reason) {
        warning ("Can't resolve url: " + url);
        warning ("Reason: " + reason);

        var toast = window.toast;
        toast.title = reason;
        toast.set_default_action (_("Open in Browser"));
        ulong signal_id = 0;
        signal_id = toast.default_action.connect (() => {
            Desktop.open_uri (url);
            toast.disconnect (signal_id);
        });
        toast.send_notification ();
        return true;
    }

}
