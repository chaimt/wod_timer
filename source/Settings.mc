//
// Settings.mc
//
// Typed access to the user settings in resources/settings/properties.xml.
// They are edited both from the on-watch Settings menu and from the phone
// app, so every read validates the value and falls back to the default.
//
import Toybox.Application;
import Toybox.Lang;

module Settings {

    const PREP_KEY = "prepSeconds";
    const SOUND_KEY = "sound";
    const VIBRATE_KEY = "vibrate";
    const RECORD_KEY = "recordActivity";

    const PREP_DEFAULT = 10;
    const PREP_MAX = 30;
    //! Values offered by the on-watch Countdown item, cycled in order.
    const PREP_CHOICES = [0, 3, 5, 10, 15, 20, 30] as Array<Number>;

    function prepSeconds() as Number {
        var value = Application.Properties.getValue(PREP_KEY);
        if (!(value instanceof Number) || value < 0 || value > PREP_MAX) {
            return PREP_DEFAULT;
        }
        return value;
    }

    //! The countdown choice after the current one (wrapping to the first).
    function nextPrepSeconds(current as Number) as Number {
        for (var i = 0; i < PREP_CHOICES.size(); i++) {
            if (PREP_CHOICES[i] > current) {
                return PREP_CHOICES[i];
            }
        }
        return PREP_CHOICES[0];
    }

    function sound() as Boolean {
        return _flag(SOUND_KEY);
    }

    function vibrate() as Boolean {
        return _flag(VIBRATE_KEY);
    }

    function recordActivity() as Boolean {
        return _flag(RECORD_KEY);
    }

    function setValue(key as String, value as Number or Boolean) as Void {
        Application.Properties.setValue(key, value);
    }

    function _flag(key as String) as Boolean {
        var value = Application.Properties.getValue(key);
        return !(value instanceof Boolean) || value;
    }
}
