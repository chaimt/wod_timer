//
// FinishMenu.mc
//
// Shown when a workout is paused or has ended: Resume (if paused), Save or
// Discard. Saving replaces the timer with the result screen; discarding
// asks for a second press instead of a separate confirmation dialog, which
// keeps the view stack simple (menu -> timer -> setup).
//
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class FinishMenu extends WatchUi.Menu2 {

    function initialize(session as WodSession) {
        var finished = session.status() == SESSION_FINISHED;
        Menu2.initialize({:title => finished ? "Done!" : "Paused"});
        if (!finished) {
            addItem(new WatchUi.MenuItem("Resume", null, :resume, null));
        }
        addItem(new WatchUi.MenuItem("Save", Settings.recordActivity() ? "Log + Garmin Connect" : "Log", :save, null));
        addItem(new WatchUi.MenuItem("Discard", null, :discard, null));
    }
}

class FinishMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _session as WodSession;
    private var _discardArmed as Boolean = false;

    function initialize(session as WodSession) {
        Menu2InputDelegate.initialize();
        _session = session;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :resume) {
            _session.resume();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        } else if (id == :save) {
            var entry = _session.finish(true);
            (Application.getApp() as WodApp).onLogChanged();
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            if (entry != null) {
                WatchUi.switchToView(new LogDetailView(entry), new LogDetailDelegate(), WatchUi.SLIDE_UP);
            } else {
                WatchUi.popView(WatchUi.SLIDE_DOWN);
            }
        } else if (id == :discard) {
            if (!_discardArmed) {
                _discardArmed = true;
                item.setSubLabel("Press again to discard");
                WatchUi.requestUpdate();
                return;
            }
            _session.finish(false);
            WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
    }
}
