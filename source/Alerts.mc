//
// Alerts.mc
//
// Sound and vibration cues. Each cue has a distinct pitch so the athlete can
// tell work from rest without looking: short ticks for the 3-2-1 countdown,
// a high tone for "go", a low tone for rest and a rising jingle at the end.
// Honors the Sound / Vibration settings and degrades to the device's built-in
// tones where custom tone profiles are unsupported. Phase changes also wake
// the display, since the screen may have timed out mid-workout.
//
import Toybox.Attention;
import Toybox.Lang;

module Alerts {

    //! 3-2-1 countdown tick before a phase change.
    function tick() as Void {
        _play(Attention.TONE_KEY, [[1300, 120]]);
        _vibrate([[60, 120]]);
    }

    //! A work interval starts (first interval, every EMOM minute, after rest).
    function work() as Void {
        _play(Attention.TONE_START, [[2000, 550]]);
        _vibrate([[100, 600]]);
        _wake();
    }

    //! A rest interval starts.
    function rest() as Void {
        _play(Attention.TONE_STOP, [[800, 550]]);
        _vibrate([[100, 300], [0, 150], [100, 300]]);
        _wake();
    }

    //! The athlete logged a round.
    function round() as Void {
        _play(Attention.TONE_LAP, null);
        _vibrate([[80, 150]]);
    }

    //! The workout finished.
    function done() as Void {
        _play(Attention.TONE_SUCCESS, [[1200, 180], [1600, 180], [2000, 180], [2400, 600]]);
        _vibrate([[100, 400], [0, 200], [100, 400], [0, 200], [100, 800]]);
        _wake();
    }

    //! Plays a custom [frequency Hz, duration ms] sequence where supported,
    //! else the built-in `fallback` tone.
    function _play(fallback as Attention.Tone, notes as Array<Array<Number>>?) as Void {
        if (!Settings.sound() || !(Attention has :playTone)) {
            return;
        }
        if (notes != null && Attention has :ToneProfile) {
            var profile = [] as Array<Attention.ToneProfile>;
            for (var i = 0; i < notes.size(); i++) {
                profile.add(new Attention.ToneProfile(notes[i][0], notes[i][1]));
            }
            Attention.playTone({:toneProfile => profile});
            return;
        }
        Attention.playTone(fallback);
    }

    //! Turns the display on. AMOLED devices throw if the backlight is held
    //! on too long; a one-off wake per phase change never should, but a
    //! missed wake must not crash the workout.
    function _wake() as Void {
        if (!(Attention has :backlight)) {
            return;
        }
        try {
            Attention.backlight(true);
        } catch (e) {
            // Burn-in protection refused; the cue still played.
        }
    }

    //! Runs a [duty %, duration ms] vibration sequence.
    function _vibrate(pattern as Array<Array<Number>>) as Void {
        if (!Settings.vibrate() || !(Attention has :vibrate)) {
            return;
        }
        var profile = [] as Array<Attention.VibeProfile>;
        for (var i = 0; i < pattern.size(); i++) {
            profile.add(new Attention.VibeProfile(pattern[i][0], pattern[i][1]));
        }
        Attention.vibrate(profile);
    }
}
