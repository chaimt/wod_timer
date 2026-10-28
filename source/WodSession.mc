//
// WodSession.mc
//
// One run of a workout: start / pause / resume, the athlete's round tally,
// the sound cues and FIT recording. Time is kept as accumulated running
// milliseconds from System.getTimer(), so pauses are excluded and WodEngine
// derives everything else from that single number.
//
// The FIT recording starts with the first work interval (the get-ready
// countdown is not part of the activity) and gets one lap per round, so
// Garmin Connect shows a per-round split table. It is saved as Garmin's
// HIIT sport with the matching AMRAP / EMOM / Tabata sub-sport.
//
import Toybox.Activity;
import Toybox.ActivityRecording;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

enum {
    SESSION_READY = 0,
    SESSION_RUNNING = 1,
    SESSION_PAUSED = 2,
    SESSION_FINISHED = 3
}

class WodSession {

    var config as WodConfig;

    private var _prepMs as Number;
    private var _status as Number = SESSION_READY;
    private var _accumulatedMs as Number = 0;
    private var _resumedAt as Number = 0;
    private var _startEpoch as Number = 0;
    private var _manualRounds as Number = 0;
    private var _lastState as WodState? = null;
    private var _lastBeep as Number = 0;
    private var _recording as ActivityRecording.Session? = null;
    private var _closed as Boolean = false;

    function initialize(config as WodConfig) {
        self.config = config;
        _prepMs = Settings.prepSeconds() * 1000;
    }

    function status() as Number {
        return _status;
    }

    function manualRounds() as Number {
        return _manualRounds;
    }

    //! START button: start, pause or resume.
    function toggle() as Void {
        if (_status == SESSION_READY) {
            start();
        } else if (_status == SESSION_RUNNING) {
            pause();
        } else if (_status == SESSION_PAUSED) {
            resume();
        }
    }

    function start() as Void {
        if (_status != SESSION_READY) {
            return;
        }
        _startEpoch = Time.now().value();
        _status = SESSION_RUNNING;
        _resumedAt = System.getTimer();
        update();
    }

    function pause() as Void {
        if (_status != SESSION_RUNNING) {
            return;
        }
        _accumulatedMs = elapsedMs();
        _status = SESSION_PAUSED;
        if (_recording != null && _recording.isRecording()) {
            _recording.stop();
        }
    }

    function resume() as Void {
        if (_status != SESSION_PAUSED) {
            return;
        }
        _resumedAt = System.getTimer();
        _status = SESSION_RUNNING;
        if (_recording != null && !_recording.isRecording()) {
            _recording.start();
        }
    }

    //! Running time since START, pauses excluded, get-ready included.
    function elapsedMs() as Number {
        if (_status == SESSION_RUNNING) {
            return _accumulatedMs + (System.getTimer() - _resumedAt);
        }
        return _accumulatedMs;
    }

    //! Current state; while running also fires the cues and laps for any
    //! transition since the previous call. Call it from the UI tick.
    function update() as WodState {
        var state = WodEngine.stateAt(config, _prepMs, elapsedMs());
        if (_status != SESSION_RUNNING) {
            return state;
        }
        var event = WodEngine.transition(_lastState, state);
        if (event == EVENT_WORK) {
            if (_recording == null) {
                _startRecording();
            } else {
                _lap();
            }
            Alerts.work();
        } else if (event == EVENT_REST) {
            _lap();
            Alerts.rest();
        } else if (event == EVENT_DONE) {
            _complete();
            Alerts.done();
        }

        var beep = WodEngine.countdownBeep(state);
        if (beep != 0 && beep != _lastBeep && event == EVENT_NONE) {
            Alerts.tick();
        }
        _lastBeep = beep;
        _lastState = state;
        return state;
    }

    //! Tap / LAP during an AMRAP or For Time work phase: one more round.
    function addRound() as Boolean {
        if (_status != SESSION_RUNNING || !config.countsRoundsManually()) {
            return false;
        }
        if (update().phase != PHASE_WORK) {
            return false;
        }
        _manualRounds += 1;
        _lap();
        Alerts.round();
        return true;
    }

    //! True once the athlete has done any actual work (past the countdown).
    function hasProgress() as Boolean {
        return elapsedMs() > _prepMs;
    }

    //! Ends the session. With `save`, writes the log entry and the FIT
    //! activity and returns the entry; otherwise discards both. Returns null
    //! when nothing was saved. Safe to call more than once.
    function finish(save as Boolean) as Dictionary? {
        if (_closed) {
            return null;
        }
        if (_status == SESSION_RUNNING) {
            pause();
        }
        _status = SESSION_FINISHED;
        _closed = true;

        var state = WodEngine.stateAt(config, _prepMs, _accumulatedMs);
        var keep = save && state.workoutElapsedMs > 0;
        if (_recording != null) {
            if (_recording.isRecording()) {
                _recording.stop();
            }
            if (keep) {
                _recording.save();
            } else {
                _recording.discard();
            }
            _recording = null;
        }
        if (!keep) {
            return null;
        }
        var entry = WorkoutLog.makeEntry(config.type, _startEpoch,
            WodFormat.countUpSeconds(state.workoutElapsedMs),
            WodEngine.completedRounds(state, _manualRounds), state.totalRounds,
            config.summary(), state.phase == PHASE_DONE);
        WorkoutLog.add(entry);
        return entry;
    }

    //! The timer ran out: freeze the clock at the end and stop recording
    //! until the athlete chooses Save or Discard.
    private function _complete() as Void {
        _accumulatedMs = _prepMs + config.workoutMs();
        _status = SESSION_FINISHED;
        if (_recording != null && _recording.isRecording()) {
            _recording.stop();
        }
    }

    private function _startRecording() as Void {
        if (!Settings.recordActivity() || !(Toybox has :ActivityRecording)) {
            return;
        }
        _recording = ActivityRecording.createSession({
            :name => WodFormat.typeName(config.type),
            :sport => Activity.SPORT_HIIT,
            :subSport => _subSport()
        });
        _recording.start();
    }

    private function _lap() as Void {
        if (_recording != null && _recording.isRecording()) {
            _recording.addLap();
        }
    }

    private function _subSport() as Activity.SubSport {
        if (config.type == WOD_AMRAP) {
            return Activity.SUB_SPORT_AMRAP;
        }
        if (config.type == WOD_EMOM) {
            return Activity.SUB_SPORT_EMOM;
        }
        if (config.type == WOD_TABATA) {
            return Activity.SUB_SPORT_TABATA;
        }
        return Activity.SUB_SPORT_HIIT;
    }
}
