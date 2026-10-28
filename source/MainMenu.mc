//
// MainMenu.mc
//
// The home screen: choose the WOD type (each shows its last-used plan as
// a sub-label), the workout log, or settings. BACK from here exits the app.
//
import Toybox.Lang;
import Toybox.WatchUi;

class MainMenu extends WatchUi.Menu2 {

    const TYPE_LABELS = ["AMRAP", "For Time", "EMOM", "Tabata"] as Array<String>;

    function initialize() {
        Menu2.initialize({:title => "WOD Timer"});
        for (var type = WOD_AMRAP; type <= WOD_TABATA; type++) {
            addItem(new WatchUi.MenuItem(TYPE_LABELS[type], WodConfig.load(type).summary(), type, null));
        }
        addItem(new WatchUi.MenuItem("Workout Log", _logSummary(), :log, null));
        addItem(new WatchUi.MenuItem("Settings", null, :settings, null));
    }

    //! Re-reads the plan and log sub-labels after they changed.
    function refresh() as Void {
        for (var type = WOD_AMRAP; type <= WOD_TABATA; type++) {
            var item = getItem(type);
            if (item != null) {
                item.setSubLabel(WodConfig.load(type).summary());
            }
        }
        var log = getItem(findItemById(:log));
        if (log != null) {
            log.setSubLabel(_logSummary());
        }
        WatchUi.requestUpdate();
    }

    private function _logSummary() as String {
        var count = WorkoutLog.entries().size();
        if (count == 0) {
            return "No workouts yet";
        }
        return count.format("%d") + (count == 1 ? " workout" : " workouts");
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as MainMenu;

    function initialize(menu as MainMenu) {
        Menu2InputDelegate.initialize();
        _menu = menu;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :log) {
            var log = new LogMenu();
            WatchUi.pushView(log, new LogMenuDelegate(log, method(:onChange)), WatchUi.SLIDE_LEFT);
        } else if (id == :settings) {
            WatchUi.pushView(new SettingsMenu(), new SettingsMenuDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id instanceof Number) {
            var setup = new SetupMenu(WodConfig.load(id));
            WatchUi.pushView(setup, new SetupMenuDelegate(setup, method(:onChange)), WatchUi.SLIDE_LEFT);
        }
    }

    //! Called by sub-screens whenever a plan or the log changed.
    function onChange() as Void {
        _menu.refresh();
    }
}
