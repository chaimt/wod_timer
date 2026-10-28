//
// WodApp.mc
//
// Application entry point for WOD Timer, a Connect IQ take on the SmartWOD
// Timer phone app: AMRAP, For Time, EMOM and Tabata timers with a round
// counter, audio / vibration cues and a workout log.
//
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class WodApp extends Application.AppBase {

    //! The workout on screen, so it isn't lost if the app is closed mid-WOD.
    var activeSession as WodSession? = null;
    private var _mainMenu as MainMenu? = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    //! Exiting the app (or the system closing it) saves a workout in
    //! progress rather than silently dropping it. finish() is a no-op for a
    //! session that was already saved or discarded.
    function onStop(state as Dictionary?) as Void {
        var session = activeSession;
        if (session != null && session.hasProgress()) {
            session.finish(true);
        }
    }

    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        var menu = new MainMenu();
        _mainMenu = menu;
        return [menu, new MainMenuDelegate(menu)];
    }

    //! A workout was saved: refresh the log count on the home screen.
    function onLogChanged() as Void {
        var menu = _mainMenu;
        if (menu != null) {
            menu.refresh();
        }
    }
}
