//
// WodEngine.mc
//
// The timer's state machine as pure functions of elapsed time. A running
// workout only stores how many milliseconds have elapsed (see WodSession);
// the phase, round and phase progress are recomputed from that on every
// tick, so a delayed or skipped tick can never make the clock drift.
// Unit-tested in WodEngineTest.mc.
//
import Toybox.Lang;

// What changed between two consecutive states (WodEngine.transition()).
enum {
    EVENT_NONE = 0,
    EVENT_WORK = 1,
    EVENT_REST = 2,
    EVENT_DONE = 3
}

//! Snapshot of the timer at one instant.
class WodState {
    var phase as Number;
    //! 1-based round driven by the timer; 0 when rounds are counted manually.
    var round as Number;
    var totalRounds as Number;
    //! Length of the current phase; 0 when open-ended (uncapped For Time).
    var phaseMs as Number;
    var phaseElapsedMs as Number;
    //! Workout time so far, excluding the get-ready countdown.
    var workoutElapsedMs as Number;

    function initialize(phase as Number, round as Number, totalRounds as Number,
            phaseMs as Number, phaseElapsedMs as Number, workoutElapsedMs as Number) {
        self.phase = phase;
        self.round = round;
        self.totalRounds = totalRounds;
        self.phaseMs = phaseMs;
        self.phaseElapsedMs = phaseElapsedMs;
        self.workoutElapsedMs = workoutElapsedMs;
    }

    function remainingMs() as Number {
        return phaseMs - phaseElapsedMs;
    }

    //! Fraction of the current phase completed, 0.0 - 1.0; 0.0 if open-ended.
    function progress() as Float {
        if (phaseMs <= 0) {
            return 0.0;
        }
        var p = phaseElapsedMs.toFloat() / phaseMs;
        return p > 1.0 ? 1.0 : p;
    }
}

module WodEngine {

    const COUNTDOWN_BEEPS = 3;

    //! State of a workout `elapsedMs` after START (pauses excluded).
    function stateAt(config as WodConfig, prepMs as Number, elapsedMs as Number) as WodState {
        var totalRounds = config.totalRounds();
        if (elapsedMs < prepMs) {
            return new WodState(PHASE_PREP, 0, totalRounds, prepMs, elapsedMs, 0);
        }
        var t = elapsedMs - prepMs;
        var workoutMs = config.workoutMs();
        if (workoutMs > 0 && t >= workoutMs) {
            return new WodState(PHASE_DONE, totalRounds, totalRounds, 0, 0, workoutMs);
        }

        if (config.type == WOD_EMOM) {
            var intervalMs = config.workSec * 1000;
            var index = t / intervalMs;
            var start = index * intervalMs;
            var length = workoutMs - start < intervalMs ? workoutMs - start : intervalMs;
            return new WodState(PHASE_WORK, index + 1, totalRounds, length, t - start, t);
        }

        if (config.type == WOD_TABATA) {
            var workMs = config.workSec * 1000;
            var restMs = config.restSec * 1000;
            var cycleMs = workMs + restMs;
            var inCycle = t % cycleMs;
            var round = t / cycleMs + 1;
            if (inCycle < workMs) {
                return new WodState(PHASE_WORK, round, totalRounds, workMs, inCycle, t);
            }
            return new WodState(PHASE_REST, round, totalRounds, restMs, inCycle - workMs, t);
        }

        // AMRAP counts down its time; For Time counts up to the cap, if any.
        return new WodState(PHASE_WORK, 0, 0, workoutMs, t, t);
    }

    //! The cue to play when the timer moves from `prev` to `next`: a new
    //! work interval (including each EMOM minute), a rest, or the finish.
    function transition(prev as WodState?, next as WodState) as Number {
        if (prev != null && prev.phase == next.phase && prev.round == next.round) {
            return EVENT_NONE;
        }
        if (next.phase == PHASE_WORK) {
            return EVENT_WORK;
        }
        if (next.phase == PHASE_REST) {
            return EVENT_REST;
        }
        if (next.phase == PHASE_DONE) {
            return EVENT_DONE;
        }
        return EVENT_NONE;
    }

    //! 3, 2 or 1 during the last three seconds of a timed phase (the beeps
    //! before each change), otherwise 0.
    function countdownBeep(state as WodState) as Number {
        if (state.phase == PHASE_DONE || state.phaseMs <= 0) {
            return 0;
        }
        var seconds = WodFormat.countdownSeconds(state.remainingMs());
        if (seconds >= 1 && seconds <= COUNTDOWN_BEEPS) {
            return seconds;
        }
        return 0;
    }

    //! Rounds finished so far. Timer-driven types count completed intervals
    //! (a Tabata round is done once its work part is); AMRAP / For Time use
    //! the athlete's tally.
    function completedRounds(state as WodState, manualRounds as Number) as Number {
        if (state.totalRounds == 0) {
            return manualRounds;
        }
        if (state.phase == PHASE_DONE) {
            return state.totalRounds;
        }
        if (state.phase == PHASE_REST) {
            return state.round;
        }
        if (state.phase == PHASE_PREP) {
            return 0;
        }
        return state.round - 1;
    }
}
