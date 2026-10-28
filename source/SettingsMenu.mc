//
// SettingsMenu.mc
//
// On-watch settings: the get-ready countdown length (each press cycles
// through Settings.PREP_CHOICES), sounds, vibration, and whether workouts
// are recorded as Garmin Connect activities. The same settings are
// editable from the phone app.
//
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsMenu extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Settings"});
        addItem(new WatchUi.MenuItem("Countdown", prepLabel(Settings.prepSeconds()), :prep, null));
        addItem(new WatchUi.ToggleMenuItem("Sounds", null, :sound, Settings.sound(), null));
        addItem(new WatchUi.ToggleMenuItem("Vibration", null, :vibrate, Settings.vibrate(), null));
        addItem(new WatchUi.ToggleMenuItem("Record activity", {:enabled => "Garmin Connect", :disabled => "Off"},
            :record, Settings.recordActivity(), null));
    }

    static function prepLabel(seconds as Number) as String {
        return seconds == 0 ? "Off" : seconds.format("%d") + " s";
    }
}

class SettingsMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :prep) {
            var next = Settings.nextPrepSeconds(Settings.prepSeconds());
            Settings.setValue(Settings.PREP_KEY, next);
            item.setSubLabel(SettingsMenu.prepLabel(next));
            WatchUi.requestUpdate();
        } else if (item instanceof WatchUi.ToggleMenuItem) {
            var key = Settings.RECORD_KEY;
            if (id == :sound) {
                key = Settings.SOUND_KEY;
            } else if (id == :vibrate) {
                key = Settings.VIBRATE_KEY;
            }
            Settings.setValue(key, item.isEnabled());
        }
    }
}
