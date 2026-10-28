//
// TimerDelegate.mc
//
// Workout controls, following Garmin's activity conventions:
//   START          start / pause / resume (opens the finish menu when done)
//   BACK (LAP)     +1 round in AMRAP / For Time; otherwise pause and open
//                  the finish menu (Resume / Save / Discard)
//   tap            +1 round in AMRAP / For Time; starts the timer when ready
//   MENU (hold UP) pause and open the finish menu
// Before the first START, BACK leaves the screen as usual.
//
import Toybox.Lang;
import Toybox.WatchUi;

class TimerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as TimerView;

    function initialize(view as TimerView) {
        BehaviorDelegate.initialize();
        _view = view;
    }

    function onSelect() as Boolean {
        var session = _view.session();
        if (session.status() == SESSION_FINISHED) {
            _openFinishMenu();
        } else {
            session.toggle();
            WatchUi.requestUpdate();
        }
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var session = _view.session();
        var status = session.status();
        if (status == SESSION_READY) {
            session.start();
        } else if (status == SESSION_RUNNING) {
            session.addRound();
        } else {
            _openFinishMenu();
        }
        WatchUi.requestUpdate();
        return true;
    }

    function onBack() as Boolean {
        var session = _view.session();
        var status = session.status();
        if (status == SESSION_READY) {
            return false;
        }
        if (status == SESSION_RUNNING && session.addRound()) {
            WatchUi.requestUpdate();
            return true;
        }
        session.pause();
        _openFinishMenu();
        return true;
    }

    function onMenu() as Boolean {
        var session = _view.session();
        if (session.status() == SESSION_READY) {
            return false;
        }
        session.pause();
        _openFinishMenu();
        return true;
    }

    private function _openFinishMenu() as Void {
        var session = _view.session();
        WatchUi.pushView(new FinishMenu(session), new FinishMenuDelegate(session), WatchUi.SLIDE_UP);
    }
}
