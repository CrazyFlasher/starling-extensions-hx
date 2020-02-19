package
import starling.events.KeyboardEvent;
import openfl.geom.Point;
import starling.events.Touch;
import starling.events.TouchPhase;
import openfl.ui.Keyboard;
import starling.events.TouchEvent;
import starling.assets.AssetManager;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite3D;
import starling.extensions.GodRayPlane;

class Demo extends Sprite3D
{
    private var _godRays:GodRayPlane;

    public function new()
    {
        super();
    }

    public function start(assets:AssetManager):Void
    {
        var background:Image = new Image(assets.getTexture("forest"));
        addChild(background);

        _godRays = new GodRayPlane(background.width, background.height);
        _godRays.speed = 0.1;
        _godRays.size = 0.1;
        _godRays.skew = 0;
        _godRays.shear = 0;
        _godRays.fade = 1;
        _godRays.size = 0.065;
        _godRays.shear = 0.5;
        _godRays.skew = -0.26;
        _godRays.contrast = 3.5;

        addChild(_godRays);

        addEventListener(TouchEvent.TOUCH, onTouch);
        Starling.current.stage.addEventListener(KeyboardEvent.KEY_UP, onKey);

        Starling.current.juggler.add(_godRays);
    }

    private var _testProperty:String = "skew";

    private function onKey(event:KeyboardEvent):Void
    {
        var keyCode:UInt = event.keyCode;

        trace(keyCode);

        switch keyCode
        {
            case Keyboard.P: _testProperty = "speed";
            case Keyboard.I: _testProperty = "size";
            case Keyboard.K: _testProperty = "skew";
            case Keyboard.H: _testProperty = "shear";
            case Keyboard.F: _testProperty = "fade";
            case Keyboard.C: _testProperty = "contrast";
        }

        trace("now modifying " + _testProperty);
    }

    private function onTouch(event:TouchEvent):Void
    {
        var touch:Touch = event.getTouch(this, TouchPhase.MOVED);

        if (touch != null)
        {
            var movement:Point = touch.getMovement(this);
            var delta:Float = movement.x / 200;

            Reflect.setProperty(_godRays, _testProperty, Reflect.getProperty(_godRays, _testProperty) + delta);

            trace("godRays." + _testProperty + " = " + Reflect.getProperty(_godRays, _testProperty));

            _godRays.advanceTime(0);
        }
    }
}
