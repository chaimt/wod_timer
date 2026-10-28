//
// SetupMenu.mc
//
// Per-WOD setup: a Start item showing the plan, then one item per editable
// field ("Time 20:00", "Work 0:20", ...). Editing a field opens the value
// picker and saves the new setting immediately, so the next session starts
// from the last-used values.
//
import Toybox.Lang;
import Toybox.WatchUi;

class SetupMenu extends WatchUi.Menu2 {

    private var _config as WodConfig;
    private var _fields as Array<FieldSpec>;

    function initialize(config as WodConfig) {
        Menu2.initialize({:title => WodFormat.typeName(config.type)});
        _config = config;
        _fields = WodConfig.fieldsFor(config.type);
        addItem(new WatchUi.MenuItem("Start", config.summary(), :start, null));
        for (var i = 0; i < _fields.size(); i++) {
            var spec = _fields[i];
            addItem(new WatchUi.MenuItem(spec.label, spec.format(config.getField(spec.field)), spec.field, null));
        }
    }

    function config() as WodConfig {
        return _config;
    }

    function fieldSpec(field as Number) as FieldSpec? {
        for (var i = 0; i < _fields.size(); i++) {
            if (_fields[i].field == field) {
                return _fields[i];
            }
        }
        return null;
    }

    //! Re-reads sub-labels after a field changed.
    function refresh() as Void {
        var start = getItem(0);
        if (start != null) {
            start.setSubLabel(_config.summary());
        }
        for (var i = 0; i < _fields.size(); i++) {
            var spec = _fields[i];
            var item = getItem(i + 1);
            if (item != null) {
                item.setSubLabel(spec.format(_config.getField(spec.field)));
            }
        }
        WatchUi.requestUpdate();
    }
}

class SetupMenuDelegate extends WatchUi.Menu2InputDelegate {

    private var _menu as SetupMenu;
    private var _onChange as Method() as Void;
    private var _editing as Number = FIELD_TOTAL;

    //! `onChange` lets the main menu refresh its summary sub-labels.
    function initialize(menu as SetupMenu, onChange as Method() as Void) {
        Menu2InputDelegate.initialize();
        _menu = menu;
        _onChange = onChange;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :start) {
            var session = new WodSession(_menu.config());
            var view = new TimerView(session);
            WatchUi.pushView(view, new TimerDelegate(view), WatchUi.SLIDE_LEFT);
            return;
        }
        var spec = _menu.fieldSpec(id as Number);
        if (spec == null) {
            return;
        }
        _editing = spec.field;
        var picker = new ValuePickerView(spec, _menu.config().getField(spec.field));
        WatchUi.pushView(picker, new ValuePickerDelegate(picker, method(:onValue)), WatchUi.SLIDE_LEFT);
    }

    function onValue(value as Number) as Void {
        var config = _menu.config();
        config.setField(_editing, value);
        config.save();
        _menu.refresh();
        _onChange.invoke();
    }
}
