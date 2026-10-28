//
// WodTheme.mc
//
// Colors shared by all screens. Each phase has one color used for its label
// and progress ring, so work / rest are readable at a glance mid-workout.
// Plain RGB values: MIP devices map them to their nearest palette color.
//
import Toybox.Graphics;
import Toybox.Lang;

module WodTheme {

    const BACKGROUND = Graphics.COLOR_BLACK;
    const TEXT = Graphics.COLOR_WHITE;
    const DIM = 0x8A8A8A;
    const TRACK = 0x2A2A2A;
    const HEART = 0xFF4060;

    const PREP = 0xFFB300;
    const WORK = 0x00D66E;
    const REST = 0xFF4040;
    const DONE = 0x3D9BFF;
    const PAUSED = 0xFFB300;

    const TYPE_COLORS = [0xFF7A00, 0x3D9BFF, 0x00D66E, 0xE040FB] as Array<Number>;

    function phaseColor(phase as Number) as Number {
        if (phase == PHASE_PREP) {
            return PREP;
        }
        if (phase == PHASE_REST) {
            return REST;
        }
        if (phase == PHASE_DONE) {
            return DONE;
        }
        return WORK;
    }

    function typeColor(type as Number) as Number {
        if (type < 0 || type >= TYPE_COLORS.size()) {
            return TEXT;
        }
        return TYPE_COLORS[type];
    }
}
