import starling.animation.Transitions;
import starling.core.Starling;
import starling.extensions.TextureMaskStyle;
import starling.display.Image;
import starling.display.Sprite;
import starling.assets.AssetManager;

class Demo extends Sprite
{
    public function new()
    {
        super();
    }

    private var maskStyle:TextureMaskStyle;

    public function start(assets:AssetManager):Void
    {
        var image:Image = new Image(assets.getTexture("starling"));
        image.x = (stage.stageWidth - image.width) / 2;
        image.y = (stage.stageHeight - image.height) / 2;
        addChild(image);

        var mask:Image = new Image(assets.getTexture("mask"));
        mask.x = (stage.stageWidth - mask.width) / 2;
        mask.y = (stage.stageHeight - mask.height) / 2;
        addChild(mask);

        maskStyle = new TextureMaskStyle(1.0);
        mask.style = maskStyle;

        image.mask = mask;

        fadeIn();
    }

    private function fadeIn():Void
    {
        Starling.current.juggler.tween(maskStyle, 3, {threshold: 0.0, onComplete: fadeOut});
    }

    private function fadeOut():Void
    {
        Starling.current.juggler.tween(maskStyle, 3, {threshold: 1.0, onComplete: fadeIn});
    }
}
