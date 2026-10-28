//
// TimerView.mc
//
// The workout screen: a big clock in the middle, the phase (GET READY /
// WORK / REST / DONE) above it, the round counter below, and a ring around
// the bezel showing progress through the current phase in the phase color.
// For an uncapped For Time the ring sweeps once a minute instead.
//
// A 100 ms timer drives WodSession.update() so cues fire on time, but the
// screen is only redrawn when the displayed second or phase changes.
//
import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Timer;
import Toybox.WatchUi;

class TimerView extends WatchUi.View {

    const TICK_MS = 100;
    const CLOCK_FONTS = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
        Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD] as Array<Graphics.FontDefinition>;

    private var _session as WodSession;
    private var _timer as Timer.Timer?;
    private var _lastSecond as Number = -1;
    private var _lastPhase as Number = -1;
    private var _lastStatus as Number = -1;

    function initialize(session as WodSession) {
        View.initialize();
        _session = session;
    }

    function session() as WodSession {
        return _session;
    }

    function onShow() as Void {
        var app = Application.getApp() as WodApp;
        app.activeSession = _session;
        _timer = new Timer.Timer();
        _timer.start(method(:onTick), TICK_MS, true);
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onTick() as Void {
        var state = _session.update();
        var second = _session.elapsedMs() / 1000;
        var status = _session.status();
        if (second != _lastSecond || state.phase != _lastPhase || status != _lastStatus) {
            _lastSecond = second;
            _lastPhase = state.phase;
            _lastStatus = status;
            WatchUi.requestUpdate();
        }
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var state = _session.update();
        var status = _session.status();
        var config = _session.config;
        var color = status == SESSION_READY ? WodTheme.PREP : WodTheme.phaseColor(state.phase);

        dc.setColor(WodTheme.BACKGROUND, WodTheme.BACKGROUND);
        dc.clear();
        _drawRing(dc, w, h, state, status, color);

        dc.setColor(WodTheme.typeColor(config.type), Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.15, Graphics.FONT_XTINY, WodFormat.typeName(config.type),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var label = WodFormat.phaseName(state.phase);
        var labelColor = color;
        if (status == SESSION_READY) {
            label = "PRESS START";
        } else if (status == SESSION_PAUSED) {
            label = "PAUSED";
            labelColor = WodTheme.PAUSED;
        }
        dc.setColor(labelColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.25, Graphics.FONT_SMALL, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var clock = clockText(config, state, status);
        dc.setColor(status == SESSION_PAUSED ? WodTheme.DIM : WodTheme.TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.47, _clockFont(dc, clock, w, h), clock,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(WodTheme.TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.67, Graphics.FONT_MEDIUM, roundText(config, state, _session.manualRounds()),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(WodTheme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h * 0.78, Graphics.FONT_TINY, footerText(config, state, status),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        _drawHeartRate(dc, w, h);
    }

    //! The big number: the get-ready countdown, then time left in the phase
    //! (AMRAP / EMOM / Tabata) or time elapsed (For Time).
    static function clockText(config as WodConfig, state as WodState, status as Number) as String {
        if (status == SESSION_READY) {
            if (config.type == WOD_AMRAP) {
                return WodFormat.clock(config.totalSec);
            }
            if (config.type == WOD_FOR_TIME) {
                return WodFormat.clock(0);
            }
            return WodFormat.clock(config.workSec);
        }
        if (state.phase == PHASE_PREP) {
            return WodFormat.countdownSeconds(state.remainingMs()).format("%d");
        }
        if (state.phase == PHASE_DONE || config.type == WOD_FOR_TIME) {
            return WodFormat.clock(WodFormat.countUpSeconds(state.workoutElapsedMs));
        }
        return WodFormat.clock(WodFormat.countdownSeconds(state.remainingMs()));
    }

    //! "ROUND 3/8" for timer-driven rounds, "ROUNDS 5" for the athlete's tally.
    static function roundText(config as WodConfig, state as WodState, manualRounds as Number) as String {
        if (config.countsRoundsManually()) {
            return "ROUNDS " + manualRounds.format("%d");
        }
        var round = state.round;
        if (state.phase == PHASE_PREP) {
            round = 0;
        }
        return "ROUND " + round.format("%d") + "/" + state.totalRounds.format("%d");
    }

    //! Secondary line: the plan before starting, then the workout clock that
    //! the big number doesn't show (time left overall, or the cap).
    static function footerText(config as WodConfig, state as WodState, status as Number) as String {
        if (status == SESSION_READY || state.phase == PHASE_PREP) {
            return config.summary();
        }
        if (state.phase == PHASE_DONE || status == SESSION_FINISHED) {
            return "START to save";
        }
        if (config.type == WOD_FOR_TIME) {
            return config.summary();
        }
        if (config.type == WOD_AMRAP) {
            return "Elapsed " + WodFormat.clock(WodFormat.countUpSeconds(state.workoutElapsedMs));
        }
        var left = config.workoutMs() - state.workoutElapsedMs;
        return "Total left " + WodFormat.clock(WodFormat.countdownSeconds(left));
    }

    private function _drawRing(dc as Graphics.Dc, w as Number, h as Number, state as WodState,
            status as Number, color as Number) as Void {
        var pen = (w * 0.035).toNumber();
        if (pen < 4) {
            pen = 4;
        }
        var r = w / 2 - pen / 2 - 1;
        dc.setPenWidth(pen);
        dc.setColor(WodTheme.TRACK, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(w / 2, h / 2, r);

        var fraction = state.progress();
        if (status == SESSION_READY) {
            fraction = 0.0;
        } else if (state.phase == PHASE_DONE) {
            fraction = 1.0;
        } else if (state.phaseMs == 0) {
            fraction = (state.workoutElapsedMs % 60000) / 60000.0;
        }
        if (fraction <= 0.0) {
            return;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        if (fraction >= 1.0) {
            dc.drawCircle(w / 2, h / 2, r);
            return;
        }
        // Arcs are in degrees counter-clockwise from 3 o'clock; sweep
        // clockwise from 12 o'clock like a clock hand.
        var end = 90 - (fraction * 360).toNumber();
        if (end == 90) {
            return;
        }
        dc.drawArc(w / 2, h / 2, r, Graphics.ARC_CLOCKWISE, 90, end < 0 ? end + 360 : end);
    }

    //! Live heart rate with a small heart glyph; "--" while there is no reading.
    private function _drawHeartRate(dc as Graphics.Dc, w as Number, h as Number) as Void {
        var info = Activity.getActivityInfo();
        var hr = info != null ? info.currentHeartRate : null;
        var text = hr != null ? hr.format("%d") : "--";
        var y = h * 0.88;
        var textWidth = dc.getTextWidthInPixels(text, Graphics.FONT_TINY);
        var size = dc.getFontHeight(Graphics.FONT_TINY) / 3;
        var x = w / 2 - (textWidth + size * 3) / 2 + size;

        dc.setColor(WodTheme.HEART, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - size / 2, y - size / 3, size / 2 + 1);
        dc.fillCircle(x + size / 2, y - size / 3, size / 2 + 1);
        dc.fillPolygon([[x - size - 1, y - size / 4], [x + size + 1, y - size / 4], [x, y + size]]);

        dc.setColor(WodTheme.TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + size * 2, y, Graphics.FONT_TINY, text,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    //! Largest number font whose rendering of `text` fits the dial.
    private function _clockFont(dc as Graphics.Dc, text as String, w as Number, h as Number) as Graphics.FontDefinition {
        for (var i = 0; i < CLOCK_FONTS.size() - 1; i++) {
            var font = CLOCK_FONTS[i];
            if (dc.getTextWidthInPixels(text, font) <= w * 0.78 && dc.getFontHeight(font) <= h * 0.36) {
                return font;
            }
        }
        return CLOCK_FONTS[CLOCK_FONTS.size() - 1];
    }
}
