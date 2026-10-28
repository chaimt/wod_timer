//
// WodFormat.mc
//
// Shared WOD enums plus the pure formatting helpers every screen uses
// ("12:34", "1:02:03", "AMRAP", "Oct 28 18:05"). No device state is read
// here, so everything is unit-tested in WodFormatTest.mc.
//
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Workout types, in main-menu order.
enum {
    WOD_AMRAP = 0,
    WOD_FOR_TIME = 1,
    WOD_EMOM = 2,
    WOD_TABATA = 3
}

// Timer phases produced by WodEngine.stateAt().
enum {
    PHASE_PREP = 0,
    PHASE_WORK = 1,
    PHASE_REST = 2,
    PHASE_DONE = 3
}

module WodFormat {

    const TYPE_NAMES = ["AMRAP", "FOR TIME", "EMOM", "TABATA"] as Array<String>;
    const PHASE_NAMES = ["GET READY", "WORK", "REST", "DONE"] as Array<String>;

    //! Whole seconds as "m:ss", or "h:mm:ss" from one hour up. Negative
    //! input clamps to "0:00" so a late tick never shows "-0:01".
    function clock(seconds as Number) as String {
        if (seconds < 0) {
            seconds = 0;
        }
        var h = seconds / 3600;
        var m = (seconds % 3600) / 60;
        var s = seconds % 60;
        if (h > 0) {
            return h.format("%d") + ":" + m.format("%02d") + ":" + s.format("%02d");
        }
        return m.format("%d") + ":" + s.format("%02d");
    }

    //! Seconds shown by a count-down: rounds up so "0:00" appears only when
    //! the phase has really ended, and the last second reads "0:01".
    function countdownSeconds(ms as Number) as Number {
        if (ms <= 0) {
            return 0;
        }
        return (ms + 999) / 1000;
    }

    //! Seconds shown by a count-up: whole seconds already elapsed.
    function countUpSeconds(ms as Number) as Number {
        if (ms <= 0) {
            return 0;
        }
        return ms / 1000;
    }

    function typeName(type as Number) as String {
        if (type < 0 || type >= TYPE_NAMES.size()) {
            return "WOD";
        }
        return TYPE_NAMES[type];
    }

    function phaseName(phase as Number) as String {
        if (phase < 0 || phase >= PHASE_NAMES.size()) {
            return "";
        }
        return PHASE_NAMES[phase];
    }

    //! "1 round" / "7 rounds".
    function rounds(count as Number) as String {
        return count.format("%d") + (count == 1 ? " round" : " rounds");
    }

    //! Local start time of a logged workout, e.g. "Oct 28 18:05".
    function dateTime(epochSeconds as Number) as String {
        var info = Gregorian.info(new Time.Moment(epochSeconds), Time.FORMAT_MEDIUM);
        return info.month.toString() + " " + info.day.format("%d") + " "
            + info.hour.format("%02d") + ":" + info.min.format("%02d");
    }
}
