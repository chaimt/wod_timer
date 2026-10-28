//
// WodFormatTest.mc
//
// Simulator unit tests for WodFormat and WodConfig (run with monkeyc -t /
// monkeydo -t, i.e. `task test`).
//
import Toybox.Lang;
import Toybox.Test;

(:test)
function testClockFormats(logger as Test.Logger) as Boolean {
    Test.assertEqual("0:00", WodFormat.clock(0));
    Test.assertEqual("0:09", WodFormat.clock(9));
    Test.assertEqual("20:00", WodFormat.clock(1200));
    Test.assertEqual("59:59", WodFormat.clock(3599));
    Test.assertEqual("1:00:00", WodFormat.clock(3600));
    Test.assertEqual("1:02:03", WodFormat.clock(3723));
    Test.assertEqual("0:00", WodFormat.clock(-5));
    return true;
}

(:test)
function testCountdownRoundsUpCountUpRoundsDown(logger as Test.Logger) as Boolean {
    Test.assertEqual(3, WodFormat.countdownSeconds(3000));
    Test.assertEqual(3, WodFormat.countdownSeconds(2001));
    Test.assertEqual(1, WodFormat.countdownSeconds(1));
    Test.assertEqual(0, WodFormat.countdownSeconds(0));
    Test.assertEqual(0, WodFormat.countdownSeconds(-40));
    Test.assertEqual(2, WodFormat.countUpSeconds(2999));
    Test.assertEqual(0, WodFormat.countUpSeconds(-1));
    return true;
}

(:test)
function testNames(logger as Test.Logger) as Boolean {
    Test.assertEqual("AMRAP", WodFormat.typeName(WOD_AMRAP));
    Test.assertEqual("FOR TIME", WodFormat.typeName(WOD_FOR_TIME));
    Test.assertEqual("TABATA", WodFormat.typeName(WOD_TABATA));
    Test.assertEqual("WOD", WodFormat.typeName(9));
    Test.assertEqual("REST", WodFormat.phaseName(PHASE_REST));
    Test.assertEqual("1 round", WodFormat.rounds(1));
    Test.assertEqual("7 rounds", WodFormat.rounds(7));
    return true;
}

(:test)
function testConfigDefaultsAndSummaries(logger as Test.Logger) as Boolean {
    Test.assertEqual("20:00", WodConfig.defaults(WOD_AMRAP).summary());
    Test.assertEqual("No cap", WodConfig.defaults(WOD_FOR_TIME).summary());
    Test.assertEqual("10 x 1:00", WodConfig.defaults(WOD_EMOM).summary());
    Test.assertEqual("8 x 0:20 / 0:10", WodConfig.defaults(WOD_TABATA).summary());
    Test.assertEqual("Cap 15:00", new WodConfig(WOD_FOR_TIME, 900, 0, 0, 0).summary());
    return true;
}

(:test)
function testConfigRoundsAndLength(logger as Test.Logger) as Boolean {
    var tabata = WodConfig.defaults(WOD_TABATA);
    Test.assertEqual(8, tabata.totalRounds());
    // 8 x 20 s work + 7 x 10 s rest: no rest after the last round.
    Test.assertEqual(230000, tabata.workoutMs());

    // 10:30 EMOM every 1:00 -> 11 intervals, the last one 30 s.
    var emom = new WodConfig(WOD_EMOM, 630, 60, 0, 0);
    Test.assertEqual(11, emom.totalRounds());

    Test.assertEqual(0, WodConfig.defaults(WOD_AMRAP).totalRounds());
    Test.assertEqual(0, WodConfig.defaults(WOD_FOR_TIME).workoutMs());
    Test.assert(WodConfig.defaults(WOD_AMRAP).countsRoundsManually());
    Test.assert(!WodConfig.defaults(WOD_EMOM).countsRoundsManually());
    return true;
}

(:test)
function testFieldSpecStepsWrapAndFormat(logger as Test.Logger) as Boolean {
    var cap = WodConfig.fieldsFor(WOD_FOR_TIME)[0];
    Test.assertEqual("None", cap.format(0));
    Test.assertEqual("15:00", cap.format(900));
    Test.assertEqual(60, cap.stepped(0, 1));
    Test.assertEqual(WOD_MAX_TIME_SEC, cap.stepped(0, -1));
    Test.assertEqual(0, cap.stepped(WOD_MAX_TIME_SEC, 1));

    var rounds = WodConfig.fieldsFor(WOD_TABATA)[2];
    Test.assertEqual(FIELD_ROUNDS, rounds.field);
    Test.assertEqual("8", rounds.format(8));
    Test.assertEqual(1, rounds.clamp(-3));
    Test.assertEqual(99, rounds.clamp(500));
    return true;
}

(:test)
function testConfigFieldAccess(logger as Test.Logger) as Boolean {
    var config = WodConfig.defaults(WOD_TABATA);
    config.setField(FIELD_WORK, 40);
    config.setField(FIELD_REST, 20);
    config.setField(FIELD_ROUNDS, 5);
    Test.assertEqual(40, config.getField(FIELD_WORK));
    Test.assertEqual("5 x 0:40 / 0:20", config.summary());
    return true;
}

(:test)
function testNextPrepSecondsCycles(logger as Test.Logger) as Boolean {
    Test.assertEqual(3, Settings.nextPrepSeconds(0));
    Test.assertEqual(15, Settings.nextPrepSeconds(10));
    Test.assertEqual(15, Settings.nextPrepSeconds(12));
    Test.assertEqual(0, Settings.nextPrepSeconds(30));
    return true;
}
