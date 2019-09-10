using Gtk;
using Gdk;
using Granite;

public class Tootle.Widgets.Status : EventBox {

    public API.Status status;
    public bool is_notification = false;

    public Separator? separator;
    public Widgets.Avatar avatar;
    protected Grid grid;
    protected Widgets.RichLabel title_user;
    protected Label title_date;
    protected Label title_acct;
    public Revealer revealer;
    protected Widgets.RichLabel content_label;
    protected Widgets.RichLabel? content_spoiler;
    protected Button? spoiler_button;
    protected Box title_box;
    protected Widgets.AttachmentGrid attachments;
    protected Image pin_indicator;

    protected Box counters;
    protected Label replies;
    protected Label reblogs;
    protected Label favorites;
    protected Widgets.ImageToggleButton reblog;
    protected Widgets.ImageToggleButton favorite;
    protected Widgets.ImageToggleButton reply;

    construct {
        grid = new Grid ();

        avatar = new Widgets.Avatar ();
        avatar.valign = Align.START;
        avatar.margin_top = 6;
        avatar.margin_start = 6;
        avatar.margin_end = 6;

        title_box = new Box (Orientation.HORIZONTAL, 6);
        title_box.hexpand = true;
        title_box.margin_end = 12;
        title_box.margin_top = 6;

        title_user = new Widgets.RichLabel ("");
        title_box.pack_start (title_user, false, false, 0);

        title_acct = new Label ("");
        title_acct.opacity = 0.5;
        title_acct.ellipsize = Pango.EllipsizeMode.END;
        title_box.pack_start (title_acct, false, false, 0);

        title_date = new Label ("");
        title_date.opacity = 0.5;
        title_date.ellipsize = Pango.EllipsizeMode.END;
        title_box.pack_end (title_date, false, false, 0);
        title_box.show_all ();

        pin_indicator = new Image.from_icon_name ("view-pin-symbolic", IconSize.MENU);
        pin_indicator.opacity = 0.5;
        title_box.pack_end (pin_indicator, false, false, 0);

        content_label = new Widgets.RichLabel ("");
        content_label.wrap_words ();

        attachments = new Widgets.AttachmentGrid ();

        var revealer_box = new Box (Orientation.VERTICAL, 6);
        revealer_box.margin_end = 12;
        revealer_box.add (content_label);
        revealer_box.add (attachments);
        revealer = new Revealer ();
        revealer.reveal_child = true;
        revealer.add (revealer_box);

        reblogs = new Label ("0");
        favorites = new Label ("0");
        replies = new Label ("0");

        reblog = new Widgets.ImageToggleButton ("media-playlist-repeat-symbolic");
        reblog.set_action ();
        reblog.tooltip_text = _("Boost");
        reblog.toggled.connect (() => {
            if (reblog.sensitive)
                status.formal.update_reblogged (reblog.get_active ());
        });
        favorite = new Widgets.ImageToggleButton ("emblem-favorite-symbolic");
        favorite.set_action ();
        favorite.tooltip_text = _("Favorite");
        favorite.toggled.connect (() => {
            if (favorite.sensitive)
                status.formal.update_favorited (favorite.get_active ());
        });
        reply = new Widgets.ImageToggleButton ("mail-replied-symbolic");
        reply.set_action ();
        reply.tooltip_text = _("Reply");
        reply.toggled.connect (() => {
            reply.set_active (false);
            Dialogs.Compose.reply (status.formal);
        });

        counters = new Box (Orientation.HORIZONTAL, 6);
        counters.margin_top = 6;
        counters.margin_bottom = 6;
        counters.add (reblog);
        counters.add (reblogs);
        counters.add (favorite);
        counters.add (favorites);
        counters.add (reply);
        counters.add (replies);
        counters.show_all ();

        add (grid);
        grid.attach (avatar, 1, 1, 1, 4);
        grid.attach (title_box, 2, 2, 1, 1);
        grid.attach (revealer, 2, 4, 1, 1);
        grid.attach (counters, 2, 5, 1, 1);
        show_all ();

        button_press_event.connect (on_clicked);
    }

    public Status (API.Status status, bool notification = false) {
        this.status = status;
        this.status.updated.connect (rebind);
        is_notification = notification;

        if (status.reblog != null) {
            var image = new Image.from_icon_name("media-playlist-repeat-symbolic", IconSize.BUTTON);
            image.halign = Align.END;
            image.margin_end = 6;
            image.margin_top = 6;
            image.show ();

            var label_text = API.NotificationType.REBLOG_REMOTE_USER.get_desc (status.account);
            var label = new Widgets.RichLabel (label_text);
            label.halign = Align.START;
            label.margin_top = 6;
            label.show ();

            grid.attach (image, 1, 0, 1, 1);
            grid.attach (label, 2, 0, 2, 1);
        }

        if (status.has_spoiler ()) {
            revealer.reveal_child = false;
            var spoiler_box = new Box (Orientation.HORIZONTAL, 6);
            spoiler_box.margin_end = 12;

            var spoiler_button_text = _("Toggle content");
            if (status.sensitive && status.attachments != null) {
                spoiler_button = new Button.from_icon_name ("mail-attachment-symbolic", IconSize.BUTTON);
                spoiler_button.label = spoiler_button_text;
                spoiler_button.always_show_image = true;
                content_label.margin_top = 6;
            }
            else {
                spoiler_button = new Button.with_label (spoiler_button_text);
            }
            spoiler_button.hexpand = true;
            spoiler_button.halign = Align.END;
            spoiler_button.clicked.connect (() => revealer.set_reveal_child (!revealer.child_revealed));

            var spoiler_text = _("[ This post contains sensitive content ]");
            if (status.spoiler_text != null)
                spoiler_text = status.spoiler_text;
            content_spoiler = new Widgets.RichLabel (spoiler_text);
            content_spoiler.wrap_words ();

            spoiler_box.add (content_spoiler);
            spoiler_box.add (spoiler_button);
            spoiler_box.show_all ();
            grid.attach (spoiler_box, 2, 3, 1, 1);
        }

        if (!is_notification && status.formal.attachments != null)
            attachments.pack (status.formal.attachments);
        else
            attachments.destroy ();

        destroy.connect (() => {
            if (separator != null)
                separator.destroy ();
        });

        network.status_removed.connect (id => {
            if (id == status.id)
                destroy ();
        });

        rebind ();
    }

    public void highlight () {
        grid.get_style_context ().add_class ("card");
        grid.margin_bottom = 6;
    }

    public void rebind () {
        var formal = status.formal;

        title_user.set_label ("<b>%s</b>".printf ((formal.account.display_name)));
        title_acct.label = "@" + formal.account.acct;
        content_label.set_label (formal.content);
        content_label.mentions = formal.mentions;
        pin_indicator.visible = status.pinned;

        var datetime = parse_date_iso8601 (formal.created_at);
        title_date.label = Granite.DateTime.get_relative_datetime (datetime);

        reblogs.label = formal.reblogs_count.to_string ();
        favorites.label = formal.favourites_count.to_string ();
        replies.label = formal.replies_count.to_string ();

        reblog.sensitive = false;
        reblog.active = formal.reblogged;
        reblog.sensitive = true;
        favorite.sensitive = false;
        favorite.active = formal.favorited;
        favorite.sensitive = true;

        if (formal.visibility == API.Visibility.DIRECT) {
            reblog.sensitive = false;
            reblog.icon.icon_name = formal.visibility.get_icon ();
            reblog.tooltip_text = _("This post can't be boosted");
        }

        avatar.url = formal.account.avatar;
    }

    private GLib.DateTime? parse_date_iso8601 (string date) {
        var timeval = GLib.TimeVal ();
        if (timeval.from_iso8601 (date))
            return new GLib.DateTime.from_timeval_local (timeval);

        return null;
    }

    public bool on_avatar_clicked (EventButton ev) {
        if (ev.button == 1) {
            var view = new Views.Profile (status.formal.account);
            return window.open_view (view);
        }
        return false;
    }

    public bool open (EventButton ev) {
        if (ev.button == 1) {
            var formal = status.formal;
            var view = new Views.ExpandedStatus (formal);
            return window.open_view (view);
        }
        return false;
    }

    protected virtual bool on_clicked (EventButton ev) {
        if (ev.button == 3)
            return open_menu (ev.button, ev.time);
        return false;

    }

    public virtual bool open_menu (uint button, uint32 time) {
        var menu = new Gtk.Menu ();

        var is_muted = status.muted;
        var is_pinned = status.pinned;

        var item_muting = new Gtk.MenuItem.with_label (is_muted ? _("Unmute Conversation") : _("Mute Conversation"));
        item_muting.activate.connect (() => status.update_muted (!is_muted));
        var item_open_link = new Gtk.MenuItem.with_label (_("Open in Browser"));
        item_open_link.activate.connect (() => Desktop.open_uri (status.formal.url));
        var item_copy_link = new Gtk.MenuItem.with_label (_("Copy Link"));
        item_copy_link.activate.connect (() => Desktop.copy (status.formal.url));
        var item_copy = new Gtk.MenuItem.with_label (_("Copy Text"));
        item_copy.activate.connect (() => {
            var sanitized = Html.remove_tags (status.formal.content);
            Desktop.copy (sanitized);
        });

        if (status.is_owned ()) {
            var item_pin = new Gtk.MenuItem.with_label (is_pinned ? _("Unpin from Profile") : _("Pin on Profile"));
            item_pin.activate.connect (() => status.update_pinned (!is_pinned));
            menu.add (item_pin);

            var item_delete = new Gtk.MenuItem.with_label (_("Delete"));
            item_delete.activate.connect (() => status.poof ());
            menu.add (item_delete);

            var item_redraft = new Gtk.MenuItem.with_label (_("Redraft"));
            item_redraft.activate.connect (() => Dialogs.Compose.redraft (status.formal));
            menu.add (item_redraft);

            menu.add (new SeparatorMenuItem ());
        }

        if (is_notification)
            menu.add (item_muting);

        menu.add (item_open_link);
        menu.add (new SeparatorMenuItem ());
        menu.add (item_copy_link);
        menu.add (item_copy);

        menu.show_all ();
        menu.attach_widget = this;
        menu.popup_at_pointer ();
        return true;
    }

}
