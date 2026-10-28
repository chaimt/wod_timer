//
// WodEngineTest.mc
//
// Simulator unit tests for WodEngine, WorkoutLog labels and the TimerView
// text helpers (run with monkeyc -t / monkeydo -t, i.e. `task test`).
//
import Toybox.Lang;
import Toybox.Test;

function _assertState(state as WodState, phase as Number, round as Number,
        phaseMs as Number, phaseElapsedMs as Number) as Void {
    Test.assertEqual(phase, state.phase);
    Test.assertEqual(round, state.round);
    Test.assertEqual(phaseMs, state.phaseMs);
    Test.assertEqual(phaseElapsedMs, state.phaseElapsedMs);
}

(:test)
function testPrepCountdownPrecedesWork(logger as Test.Logger) as Boolean {
    var amrap = WodConfig.defaults(WOD_AMRAP);
    _assertState(WodEngine.stateAt(amrap, 10000, 0), PHASE_PREP, 0, 10000, 0);
    _assertState(WodEngine.stateAt(amrap, 10000, 9999), PHASE_PREP, 0, 10000, 9999);
    _assertState(WodEngine.stateAt(amrap, 10000, 10000), PHASE_WORK, 0, 1200000, 0);
    // No countdown configured: work starts immediately.
    _assertState(WodEngine.stateAt(amrap, 0, 0), PHASE_WORK, 0, 1200000, 0);
    return true;
}

(:test)
function testAmrapEndsAtItsTime(logger as Test.Logger) as Boolean {
    var amrap = new WodConfig(WOD_AMRAP, 60, 0, 0, 0);
    var state = WodEngine.stateAt(amrap, 0, 45000);
    Test.assertEqual(15000, state.remainingMs());
    Test.assertEqual(45000, state.workoutElapsedMs);
    var done = WodEngine.stateAt(amrap, 0, 61000);
    Test.assertEqual(PHASE_DONE, done.phase);
    Test.assertEqual(60000, done.workoutElapsedMs);
    return true;
}

(:test)
function testForTimeIsOpenEndedUnlessCapped(logger as Test.Logger) as Boolean {
    var open = WodConfig.defaults(WOD_FOR_TIME);
    var state = WodEngine.stateAt(open, 0, 5400000);
    _assertState(state, PHASE_WORK, 0, 0, 5400000);
    Test.assertEqual(0, WodEngine.countdownBeep(state));

    var capped = new WodConfig(WOD_FOR_TIME, 600, 0, 0, 0);
    Test.assertEqual(PHASE_WORK, WodEngine.stateAt(capped, 0, 599999).phase);
    Test.assertEqual(PHASE_DONE, WodEngine.stateAt(capped, 0, 600000).phase);
    return true;
}

(:test)
function testEmomIntervalsAndShortLastInterval(logger as Test.Logger) as Boolean {
    var emom = new WodConfig(WOD_EMOM, 150, 60, 0, 0);
    _assertState(WodEngine.stateAt(emom, 0, 0), PHASE_WORK, 1, 60000, 0);
    _assertState(WodEngine.stateAt(emom, 0, 59999), PHASE_WORK, 1, 60000, 59999);
    _assertState(WodEngine.stateAt(emom, 0, 60000), PHASE_WORK, 2, 60000, 0);
    // 2:30 total: the third interval only lasts 30 s.
    _assertState(WodEngine.stateAt(emom, 0, 125000), PHASE_WORK, 3, 30000, 5000);
    Test.assertEqual(3, WodEngine.stateAt(emom, 0, 125000).totalRounds);
    Test.assertEqual(PHASE_DONE, WodEngine.stateAt(emom, 0, 150000).phase);
    return true;
}

(:test)
function testTabataAlternatesWorkAndRest(logger as Test.Logger) as Boolean {
    var tabata = WodConfig.defaults(WOD_TABATA);
    _assertState(WodEngine.stateAt(tabata, 0, 0), PHASE_WORK, 1, 20000, 0);
    _assertState(WodEngine.stateAt(tabata, 0, 20000), PHASE_REST, 1, 10000, 0);
    _assertState(WodEngine.stateAt(tabata, 0, 30000), PHASE_WORK, 2, 20000, 0);
    // Last round: 7 x 30 s = 210 s, work until 230 s, then done (no rest).
    _assertState(WodEngine.stateAt(tabata, 0, 229999), PHASE_WORK, 8, 20000, 19999);
    var done = WodEngine.stateAt(tabata, 0, 230000);
    Test.assertEqual(PHASE_DONE, done.phase);
    Test.assertEqual(8, done.round);
    return true;
}

(:test)
function testTabataWithoutRest(logger as Test.Logger) as Boolean {
    var tabata = new WodConfig(WOD_TABATA, 0, 30, 0, 3);
    _assertState(WodEngine.stateAt(tabata, 0, 30000), PHASE_WORK, 2, 30000, 0);
    Test.assertEqual(PHASE_DONE, WodEngine.stateAt(tabata, 0, 90000).phase);
    return true;
}

(:test)
function testTransitions(logger as Test.Logger) as Boolean {
    var tabata = WodConfig.defaults(WOD_TABATA);
    var prep = WodEngine.stateAt(tabata, 5000, 0);
    var work1 = WodEngine.stateAt(tabata, 5000, 5000);
    var work1Later = WodEngine.stateAt(tabata, 5000, 6000);
    var rest1 = WodEngine.stateAt(tabata, 5000, 25000);
    var work2 = WodEngine.stateAt(tabata, 5000, 35000);
    var done = WodEngine.stateAt(tabata, 5000, 235000);
    Test.assertEqual(EVENT_NONE, WodEngine.transition(null, prep));
    Test.assertEqual(EVENT_WORK, WodEngine.transition(null, work1));
    Test.assertEqual(EVENT_WORK, WodEngine.transition(prep, work1));
    Test.assertEqual(EVENT_NONE, WodEngine.transition(work1, work1Later));
    Test.assertEqual(EVENT_REST, WodEngine.transition(work1Later, rest1));
    Test.assertEqual(EVENT_WORK, WodEngine.transition(rest1, work2));
    Test.assertEqual(EVENT_DONE, WodEngine.transition(work2, done));

    // Each new EMOM interval is a work transition even though the phase stays WORK.
    var emom = WodConfig.defaults(WOD_EMOM);
    Test.assertEqual(EVENT_WORK, WodEngine.transition(WodEngine.stateAt(emom, 0, 59900),
        WodEngine.stateAt(emom, 0, 60000)));
    return true;
}

(:test)
function testCountdownBeepsLastThreeSeconds(logger as Test.Logger) as Boolean {
    var emom = WodConfig.defaults(WOD_EMOM);
    Test.assertEqual(0, WodEngine.countdownBeep(WodEngine.stateAt(emom, 0, 56999)));
    Test.assertEqual(3, WodEngine.countdownBeep(WodEngine.stateAt(emom, 0, 57000)));
    Test.assertEqual(2, WodEngine.countdownBeep(WodEngine.stateAt(emom, 0, 58000)));
    Test.assertEqual(1, WodEngine.countdownBeep(WodEngine.stateAt(emom, 0, 59999)));
    Test.assertEqual(0, WodEngine.countdownBeep(WodEngine.stateAt(emom, 0, 600000)));
    // The get-ready countdown beeps too.
    Test.assertEqual(3, WodEngine.countdownBeep(WodEngine.stateAt(emom, 10000, 7500)));
    return true;
}

(:test)
function testCompletedRounds(logger as Test.Logger) as Boolean {
    var tabata = WodConfig.defaults(WOD_TABATA);
    Test.assertEqual(0, WodEngine.completedRounds(WodEngine.stateAt(tabata, 5000, 1000), 0));
    Test.assertEqual(0, WodEngine.completedRounds(WodEngine.stateAt(tabata, 0, 1000), 0));
    Test.assertEqual(1, WodEngine.completedRounds(WodEngine.stateAt(tabata, 0, 21000), 0));
    Test.assertEqual(1, WodEngine.completedRounds(WodEngine.stateAt(tabata, 0, 31000), 0));
    Test.assertEqual(8, WodEngine.completedRounds(WodEngine.stateAt(tabata, 0, 999000), 0));
    var amrap = WodConfig.defaults(WOD_AMRAP);
    Test.assertEqual(6, WodEngine.completedRounds(WodEngine.stateAt(amrap, 0, 1000), 6));
    return true;
}

(:test)
function testProgress(logger as Test.Logger) as Boolean {
    var emom = WodConfig.defaults(WOD_EMOM);
    Test.assertEqual(0.5, WodEngine.stateAt(emom, 0, 30000).progress());
    Test.assertEqual(0.0, WodEngine.stateAt(WodConfig.defaults(WOD_FOR_TIME), 0, 30000).progress());
    return true;
}

(:test)
function testTimerScreenText(logger as Test.Logger) as Boolean {
    var tabata = WodConfig.defaults(WOD_TABATA);
    var ready = WodEngine.stateAt(tabata, 10000, 0);
    Test.assertEqual("0:20", TimerView.clockText(tabata, ready, SESSION_READY));
    Test.assertEqual("10", TimerView.clockText(tabata, ready, SESSION_RUNNING));
    Test.assertEqual("ROUND 0/8", TimerView.roundText(tabata, ready, 0));

    var rest = WodEngine.stateAt(tabata, 0, 22500);
    Test.assertEqual("0:08", TimerView.clockText(tabata, rest, SESSION_RUNNING));
    Test.assertEqual("ROUND 1/8", TimerView.roundText(tabata, rest, 0));
    Test.assertEqual("Total left 3:28", TimerView.footerText(tabata, rest, SESSION_RUNNING));

    var forTime = WodConfig.defaults(WOD_FOR_TIME);
    var running = WodEngine.stateAt(forTime, 0, 754000);
    Test.assertEqual("12:34", TimerView.clockText(forTime, running, SESSION_RUNNING));
    Test.assertEqual("ROUNDS 4", TimerView.roundText(forTime, running, 4));

    var amrap = WodConfig.defaults(WOD_AMRAP);
    var amrapState = WodEngine.stateAt(amrap, 0, 61000);
    Test.assertEqual("18:59", TimerView.clockText(amrap, amrapState, SESSION_RUNNING));
    Test.assertEqual("Elapsed 1:01", TimerView.footerText(amrap, amrapState, SESSION_RUNNING));
    return true;
}

(:test)
function testWorkoutLogLabels(logger as Test.Logger) as Boolean {
    var forTime = WorkoutLog.makeEntry(WOD_FOR_TIME, 0, 754, 3, 0, "No cap", false);
    Test.assertEqual("12:34", WorkoutLog.result(forTime));
    Test.assertEqual("FOR TIME  12:34", WorkoutLog.title(forTime));

    var amrap = WorkoutLog.makeEntry(WOD_AMRAP, 0, 1200, 7, 0, "20:00", true);
    Test.assertEqual("AMRAP  7 rounds", WorkoutLog.title(amrap));

    var tabata = WorkoutLog.makeEntry(WOD_TABATA, 0, 140, 5, 8, "8 x 0:20 / 0:10", false);
    Test.assertEqual("5/8 rounds", WorkoutLog.result(tabata));
    return true;
}

(:test)
function testWorkoutLogStatusAndDetail(logger as Test.Logger) as Boolean {
    var finished = WorkoutLog.makeEntry(WOD_FOR_TIME, 0, 754, 3, 0, "No cap", false);
    Test.assertEqual("Finished", WorkoutLog.status(finished));
    Test.assertEqual("3 rounds", WorkoutLog.detail(finished));
    var capped = WorkoutLog.makeEntry(WOD_FOR_TIME, 0, 900, 0, 0, "Cap 15:00", true);
    Test.assertEqual("Time cap", WorkoutLog.status(capped));
    Test.assertEqual("", WorkoutLog.detail(capped));

    var amrap = WorkoutLog.makeEntry(WOD_AMRAP, 0, 1200, 7, 0, "20:00", true);
    Test.assertEqual("Completed", WorkoutLog.status(amrap));
    Test.assertEqual("20:00", WorkoutLog.detail(amrap));
    var early = WorkoutLog.makeEntry(WOD_EMOM, 0, 300, 5, 10, "10 x 1:00", false);
    Test.assertEqual("Stopped early", WorkoutLog.status(early));
    return true;
}
