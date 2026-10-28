//
// WodConfig.mc
//
// The parameters of one workout and the editable fields each WOD type
// exposes. Fields are shared across types with a per-type meaning:
//
//   type       totalSec          workSec        restSec   rounds
//   AMRAP      time to count     -              -         -
//   FOR TIME   time cap (0=none) -              -         -
//   EMOM       total time        interval       -         -
//   TABATA     -                 work           rest      rounds
//
// The last-used settings of each type persist in Application.Storage.
//
import Toybox.Application;
import Toybox.Lang;

// Editable fields, used as Menu2 item identifiers in the setup menu.
enum {
    FIELD_TOTAL = 0,
    FIELD_WORK = 1,
    FIELD_REST = 2,
    FIELD_ROUNDS = 3
}

// How a field value is displayed.
enum {
    KIND_CLOCK = 0,
    KIND_CAP = 1,
    KIND_COUNT = 2
}

//! Range, step and label of one editable field.
class FieldSpec {
    var field as Number;
    var label as String;
    var min as Number;
    var max as Number;
    var step as Number;
    var kind as Number;

    function initialize(field as Number, label as String, min as Number, max as Number,
            step as Number, kind as Number) {
        self.field = field;
        self.label = label;
        self.min = min;
        self.max = max;
        self.step = step;
        self.kind = kind;
    }

    //! Display form of a value of this field ("20:00", "None", "8").
    function format(value as Number) as String {
        if (kind == KIND_COUNT) {
            return value.format("%d");
        }
        if (kind == KIND_CAP && value == 0) {
            return "None";
        }
        return WodFormat.clock(value);
    }

    //! Value moved one step up (+1) or down (-1), wrapping around the range
    //! so long ranges are quick to traverse from either end.
    function stepped(value as Number, direction as Number) as Number {
        var next = value + direction * step;
        if (next > max) {
            return min;
        }
        if (next < min) {
            return max;
        }
        return next;
    }

    function clamp(value as Number) as Number {
        if (value < min) {
            return min;
        }
        if (value > max) {
            return max;
        }
        return value;
    }
}

// Longest settable time (2 h) and the Storage key prefix of saved plans.
const WOD_MAX_TIME_SEC = 7200;
const WOD_STORAGE_PREFIX = "cfg";

class WodConfig {

    var type as Number;
    var totalSec as Number;
    var workSec as Number;
    var restSec as Number;
    var rounds as Number;

    function initialize(type as Number, totalSec as Number, workSec as Number,
            restSec as Number, rounds as Number) {
        self.type = type;
        self.totalSec = totalSec;
        self.workSec = workSec;
        self.restSec = restSec;
        self.rounds = rounds;
    }

    //! Factory settings: 20 min AMRAP, uncapped For Time, 10 x 1:00 EMOM and
    //! the classic 8 x 20 s / 10 s Tabata.
    static function defaults(type as Number) as WodConfig {
        if (type == WOD_AMRAP) {
            return new WodConfig(type, 20 * 60, 0, 0, 0);
        }
        if (type == WOD_EMOM) {
            return new WodConfig(type, 10 * 60, 60, 0, 0);
        }
        if (type == WOD_TABATA) {
            return new WodConfig(type, 0, 20, 10, 8);
        }
        return new WodConfig(WOD_FOR_TIME, 0, 0, 0, 0);
    }

    //! Editable fields for a WOD type, in setup-menu order.
    static function fieldsFor(type as Number) as Array<FieldSpec> {
        if (type == WOD_AMRAP) {
            return [new FieldSpec(FIELD_TOTAL, "Time", 60, WOD_MAX_TIME_SEC, 60, KIND_CLOCK)];
        }
        if (type == WOD_EMOM) {
            return [
                new FieldSpec(FIELD_TOTAL, "Total time", 60, WOD_MAX_TIME_SEC, 60, KIND_CLOCK),
                new FieldSpec(FIELD_WORK, "Every", 15, 600, 15, KIND_CLOCK)
            ];
        }
        if (type == WOD_TABATA) {
            return [
                new FieldSpec(FIELD_WORK, "Work", 5, 600, 5, KIND_CLOCK),
                new FieldSpec(FIELD_REST, "Rest", 0, 600, 5, KIND_CLOCK),
                new FieldSpec(FIELD_ROUNDS, "Rounds", 1, 99, 1, KIND_COUNT)
            ];
        }
        return [new FieldSpec(FIELD_TOTAL, "Time cap", 0, WOD_MAX_TIME_SEC, 60, KIND_CAP)];
    }

    //! Last-used settings of a type, falling back to defaults. Stored values
    //! are clamped to the field ranges so a stale entry can't break the timer.
    static function load(type as Number) as WodConfig {
        var config = defaults(type);
        var stored = Application.Storage.getValue(WOD_STORAGE_PREFIX + type.format("%d"));
        if (stored instanceof Array && stored.size() == 4) {
            var fields = fieldsFor(type);
            for (var i = 0; i < fields.size(); i++) {
                var value = stored[fields[i].field];
                if (value instanceof Number) {
                    config.setField(fields[i].field, fields[i].clamp(value));
                }
            }
        }
        return config;
    }

    function save() as Void {
        Application.Storage.setValue(WOD_STORAGE_PREFIX + type.format("%d"),
            [totalSec, workSec, restSec, rounds] as Array<Application.Storage.ValueType>);
    }

    function getField(field as Number) as Number {
        if (field == FIELD_TOTAL) {
            return totalSec;
        }
        if (field == FIELD_WORK) {
            return workSec;
        }
        if (field == FIELD_REST) {
            return restSec;
        }
        return rounds;
    }

    function setField(field as Number, value as Number) as Void {
        if (field == FIELD_TOTAL) {
            totalSec = value;
        } else if (field == FIELD_WORK) {
            workSec = value;
        } else if (field == FIELD_REST) {
            restSec = value;
        } else {
            rounds = value;
        }
    }

    //! Rounds the timer drives itself; 0 when the athlete counts rounds.
    //! A trailing partial EMOM interval counts as a round.
    function totalRounds() as Number {
        if (type == WOD_EMOM) {
            return (totalSec + workSec - 1) / workSec;
        }
        if (type == WOD_TABATA) {
            return rounds;
        }
        return 0;
    }

    //! True when rounds are tallied by the athlete (tap / LAP).
    function countsRoundsManually() as Boolean {
        return type == WOD_AMRAP || type == WOD_FOR_TIME;
    }

    //! Planned workout length in ms, excluding the get-ready countdown;
    //! 0 for an uncapped For Time. Tabata skips the rest after the last round.
    function workoutMs() as Number {
        if (type == WOD_TABATA) {
            return (rounds * workSec + (rounds - 1) * restSec) * 1000;
        }
        return totalSec * 1000;
    }

    //! One-line description used as a menu sub-label and in the log.
    function summary() as String {
        if (type == WOD_AMRAP) {
            return WodFormat.clock(totalSec);
        }
        if (type == WOD_EMOM) {
            return totalRounds().format("%d") + " x " + WodFormat.clock(workSec);
        }
        if (type == WOD_TABATA) {
            return rounds.format("%d") + " x " + WodFormat.clock(workSec) + " / " + WodFormat.clock(restSec);
        }
        if (totalSec == 0) {
            return "No cap";
        }
        return "Cap " + WodFormat.clock(totalSec);
    }
}
