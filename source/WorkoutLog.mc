//
// WorkoutLog.mc
//
// The on-watch workout log: one entry per saved WOD, newest first, kept in
// Application.Storage and capped so storage stays small. Entries are plain
// dictionaries (Storage can't hold class instances); the label functions
// are pure and unit-tested in WorkoutLogTest.mc.
//
import Toybox.Application;
import Toybox.Lang;

module WorkoutLog {

    const STORAGE_KEY = "log";
    const MAX_ENTRIES = 50;

    // Entry keys.
    const TYPE = "type";
    const START = "start";
    const SECONDS = "secs";
    const ROUNDS = "rounds";
    const TOTAL_ROUNDS = "total";
    const PLAN = "plan";
    const COMPLETE = "done";

    function entries() as Array<Dictionary> {
        var stored = Application.Storage.getValue(STORAGE_KEY);
        if (stored instanceof Array) {
            return stored as Array<Dictionary>;
        }
        return [] as Array<Dictionary>;
    }

    //! Builds a log entry (pure; see add() to persist it).
    function makeEntry(type as Number, startEpoch as Number, seconds as Number, rounds as Number,
            totalRounds as Number, plan as String, complete as Boolean) as Dictionary {
        return {
            TYPE => type,
            START => startEpoch,
            SECONDS => seconds,
            ROUNDS => rounds,
            TOTAL_ROUNDS => totalRounds,
            PLAN => plan,
            COMPLETE => complete
        };
    }

    //! Prepends an entry, dropping the oldest beyond MAX_ENTRIES.
    function add(entry as Dictionary) as Void {
        var list = [entry] as Array<Dictionary>;
        var old = entries();
        var keep = old.size() < MAX_ENTRIES - 1 ? old.size() : MAX_ENTRIES - 1;
        for (var i = 0; i < keep; i++) {
            list.add(old[i]);
        }
        Application.Storage.setValue(STORAGE_KEY, list as Array<Application.Storage.ValueType>);
    }

    function clear() as Void {
        Application.Storage.deleteValue(STORAGE_KEY);
    }

    //! The headline result: the finish time for For Time, rounds for the
    //! others ("7 rounds", "6/8 rounds").
    function result(entry as Dictionary) as String {
        var type = entry[TYPE] as Number;
        var rounds = entry[ROUNDS] as Number;
        var total = entry[TOTAL_ROUNDS] as Number;
        if (type == WOD_FOR_TIME) {
            return WodFormat.clock(entry[SECONDS] as Number);
        }
        if (total > 0) {
            return rounds.format("%d") + "/" + total.format("%d") + " rounds";
        }
        return WodFormat.rounds(rounds);
    }

    //! How the workout ended. A For Time is finished whenever the athlete
    //! stops the clock; it only "completes" on its own by hitting the cap.
    function status(entry as Dictionary) as String {
        var complete = entry[COMPLETE] == true;
        if (entry[TYPE] == WOD_FOR_TIME) {
            return complete ? "Time cap" : "Finished";
        }
        return complete ? "Completed" : "Stopped early";
    }

    //! The line under the headline: the rounds for For Time (whose headline
    //! is the time), the workout time for the others; "" if nothing to add.
    function detail(entry as Dictionary) as String {
        if (entry[TYPE] == WOD_FOR_TIME) {
            var rounds = entry[ROUNDS] as Number;
            return rounds > 0 ? WodFormat.rounds(rounds) : "";
        }
        return WodFormat.clock(entry[SECONDS] as Number);
    }

    //! Menu label, e.g. "AMRAP  7 rounds".
    function title(entry as Dictionary) as String {
        return WodFormat.typeName(entry[TYPE] as Number) + "  " + result(entry);
    }

    //! Menu sub-label, e.g. "Oct 28 18:05  20:00".
    function subtitle(entry as Dictionary) as String {
        return WodFormat.dateTime(entry[START] as Number) + "  " + WodFormat.clock(entry[SECONDS] as Number);
    }
}
