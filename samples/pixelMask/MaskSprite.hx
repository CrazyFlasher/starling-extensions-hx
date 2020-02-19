import starling.assets.AssetManager;
import starling.core.Starling;
import starling.display.MovieClip;
import starling.display.Sprite;

class MaskSprite extends Sprite
{
    public function new()
    {
        super();
    }

    public function init(assets:AssetManager):Void
    {
        var _mc:MovieClip = new MovieClip(assets.getTextureAtlas("pixelmask").getTextures(), 18);
        addChild(_mc);
        Starling.current.juggler.add(_mc);
    }
}
