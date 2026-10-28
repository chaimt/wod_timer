//
// LogMenu.mc
//
// The workout log: one item per saved WOD (newest first) opening its result
// screen, and a Clear item that needs a second press. LogDetailView is also
// the result screen shown right after saving a workout.
//
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class LogMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Workout Log"});
        var entries = WorkoutLog.entries();
        for (var i = 0; i < entries.size(); i++) {
            addItem(new WatchUi.MenuItem(WorkoutLog.title(entries[i]), WorkoutLog.subtitle(entries[i]), i, null));
        }
        if (entries.size() == 0) {
            addItem(new WatchUi.MenuItem("No workouts yet", null, :empty, null));
        } else {
            addItem(new WatchUi.MenuItem("Clear log", null, :clear, null));
        }
    }
}

class LogMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as LogMenu;
    private var _onChange as Method() as Void;
    private var _clearArmed as Boolean = false;

    function initialize(menu as LogMenu, onChange as Method() as Void) {
        Menu2InputDelegate.initialize();
        _menu = menu;
        _onChange = onChange;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id instanceof Number) {
            var entries = WorkoutLog.entries();
            if (id < entries.size()) {
                WatchUi.pushView(new LogDetailView(entries[id]), new LogDetailDelegate(), WatchUi.SLIDE_LEFT);
            }
        } else if (id == :clear) {
            if (!_clearArmed) {
                _clearArmed = true;
                item.setSubLabel("Press again to clear");
                WatchUi.requestUpdate();
                return;
            }
            WorkoutLog.clear();
            _onChange.invoke();
            WatchUi.popView(WatchUi.SLIDE_RIGHT);
        }
    }
}

//! Result of one workout: type, headline result, time, plan and date.
class LogDetailView extends WatchUi.View {

    private var _entry as Dictionary;

    function initialize(entry as Dictionary) {
        View.initialize();
        _entry = entry;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var type = _entry[WorkoutLog.TYPE] as Number;
        var center = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(WodTheme.BACKGROUND, WodTheme.BACKGROUND);
        dc.clear();
        dc.setPenWidth(w * 0.02 < 3 ? 3 : (w * 0.02).toNumber());
        dc.setColor(WodTheme.typeColor(type), Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, h / 2, w / 2 - w * 0.02);

        dc.drawText(cx, h * 0.17, Graphics.FONT_SMALL, WodFormat.typeName(type), center);

        dc.setColor(WodTheme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.27, Graphics.FONT_XTINY, WorkoutLog.status(_entry), center);

        dc.setColor(WodTheme.TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.43, Graphics.FONT_LARGE, WorkoutLog.result(_entry), center);
        dc.drawText(cx, h * 0.57, Graphics.FONT_MEDIUM, WorkoutLog.detail(_entry), center);

        dc.setColor(WodTheme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.70, Graphics.FONT_TINY, _entry[WorkoutLog.PLAN] as String, center);
        dc.drawText(cx, h * 0.80, Graphics.FONT_TINY,
            WodFormat.dateTime(_entry[WorkoutLog.START] as Number), center);
    }
}

class LogDetailDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    //! START closes the result screen just like BACK.
    function onSelect() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}
