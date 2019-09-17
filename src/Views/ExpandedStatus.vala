using Gtk;

public class Tootle.Views.ExpandedStatus : Views.Base {

    public API.Status root_status { get; construct set; }
    private Widgets.Status root_widget;

    public ExpandedStatus (API.Status status) {
        Object (root_status: status, state: "content");

        root_widget = append (status);
        root_widget.avatar.button_press_event.connect (root_widget.on_avatar_clicked);
        root_widget.get_style_context ().add_class ("card");
        root_widget.get_style_context ().add_class ("highlight");

        request ();
    }

    private Widgets.Status prepend (API.Status status, bool to_end = false){
        var widget = new Widgets.Status (status);
        widget.avatar.button_press_event.connect (widget.on_avatar_clicked);
        widget.revealer.reveal_child = true;

        content.pack_start (widget, false, false, 0);
        if (!to_end)
            content.reorder_child (widget, 0);

        check_resize ();
        return widget;
    }
    private Widgets.Status append (API.Status status) {
    	return prepend (status, true);
    }

    public Soup.Message request () {
        var req = new Request.GET (@"/api/v1/statuses/$(root_status.id)/context")
            .with_account ()
            .then ((sess, msg) => {
                var root = network.parse (msg);
                var ancestors = root.get_array_member ("ancestors");
                ancestors.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        prepend (status);
                    }
                });
                
                var descendants = root.get_array_member ("descendants");
                descendants.foreach_element ((array, i, node) => {
                    var object = node.get_object ();
                    if (object != null) {
                        var status = API.Status.parse (object);
                        append (status);
                    }
                });
                
                int x,y;
                translate_coordinates (root_widget, 0, 0, out x, out y);
                scrolled.vadjustment.value = (double)(y*-1); //TODO: Animate scrolling?
            })
            .exec ();
        return req;
    }

    public static void open_from_link (string q) {
        new Request.GET ("/api/v1/search")
            .with_account ()
            .with_param ("q", q)
            .with_param ("resolve", "true")
            .then ((sess, msg) => {
                var root = network.parse (msg);
                var statuses = root.get_array_member ("statuses");
                var object = statuses.get_element (0).get_object ();
                if (object != null){
                    var status = API.Status.parse (object);
                    window.open_view (new Views.ExpandedStatus (status));
                }
                else
                    Desktop.open_uri (q);
            })
            .exec ();
    }

}
