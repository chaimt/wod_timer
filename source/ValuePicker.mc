//
// ValuePicker.mc
//
// Full-screen editor for one numeric field (a time or a count): UP / DOWN
// or swipes change it by the field's step, wrapping at the ends; START
// accepts and BACK cancels. On touch screens, tapping the upper or lower
// third steps the value and tapping the middle accepts.
//
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

class ValuePickerView extends WatchUi.View {

    var value as Number;
    private var _spec as FieldSpec;

    function initialize(spec as FieldSpec, value as Number) {
        View.initialize();
        _spec = spec;
        self.value = spec.clamp(value);
    }

    function step(direction as Number) as Void {
        value = _spec.stepped(value, direction);
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        dc.setColor(WodTheme.BACKGROUND, WodTheme.BACKGROUND);
        dc.clear();

        dc.setColor(WodTheme.TEXT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.17, Graphics.FONT_SMALL, _spec.label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var text = _spec.format(value);
        var font = text.length() > 5 ? Graphics.FONT_NUMBER_MEDIUM : Graphics.FONT_NUMBER_HOT;
        if (value == 0 && _spec.kind == KIND_CAP) {
            font = Graphics.FONT_LARGE;
        }
        dc.drawText(cx, h * 0.5, font, text, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var a = w * 0.05;
        dc.setColor(WodTheme.WORK, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx - a, h * 0.31], [cx + a, h * 0.31], [cx, h * 0.31 - a]]);
        dc.fillPolygon([[cx - a, h * 0.69], [cx + a, h * 0.69], [cx, h * 0.69 + a]]);

        dc.setColor(WodTheme.DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h * 0.84, Graphics.FONT_XTINY, "START to set",
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class ValuePickerDelegate extends WatchUi.BehaviorDelegate {

    private var _view as ValuePickerView;
    private var _onAccept as Method(value as Number) as Void;

    function initialize(view as ValuePickerView, onAccept as Method(value as Number) as Void) {
        BehaviorDelegate.initialize();
        _view = view;
        _onAccept = onAccept;
    }

    function onPreviousPage() as Boolean {
        _view.step(1);
        return true;
    }

    function onNextPage() as Boolean {
        _view.step(-1);
        return true;
    }

    function onSelect() as Boolean {
        _onAccept.invoke(_view.value);
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }

    function onTap(clickEvent as WatchUi.ClickEvent) as Boolean {
        var y = clickEvent.getCoordinates()[1];
        var h = System.getDeviceSettings().screenHeight;
        if (y < h / 3) {
            _view.step(1);
        } else if (y > h * 2 / 3) {
            _view.step(-1);
        } else {
            return onSelect();
        }
        return true;
    }
}
