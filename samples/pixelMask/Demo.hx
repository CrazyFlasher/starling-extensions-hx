import starling.assets.AssetManager;
import starling.core.Starling;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Touch;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.extensions.PDParticleSystem;
import starling.extensions.pixelmask.PixelMaskDisplayObject;

class Demo extends Sprite
{
    private var _particleContainer:PixelMaskDisplayObject;

    public function new()
    {
        super();
    }

    public function start(assets:AssetManager):Void
    {
        // background image
        var background:Image = new Image(assets.getTexture("bg"));
        addChild(background);

        // create particle system
        var ps:PDParticleSystem = new PDParticleSystem(
            assets.getXml("particle_pex").toString(),
            assets.getTexture("particle")
        );
        ps.x = stage.stageWidth / 2;
        ps.y = stage.stageHeight;
        ps.scaleY = -1;
        Starling.current.juggler.add(ps);
        ps.start();

        // create mask sprite
        var mask:MaskSprite = new MaskSprite();
        mask.init(assets);
        mask.x = (stage.stageWidth - mask.width) / 2;
        mask.y = (stage.stageHeight - mask.height) / 2;
        addEventListener(TouchEvent.TOUCH, handleClick);

        // apply the masking here:
        _particleContainer = new PixelMaskDisplayObject();

        addChild(_particleContainer);
        _particleContainer.pixelMask = mask;
        _particleContainer.addChild(ps);
    }

    private function handleClick(e:TouchEvent):Void
    {
        var touch:Touch = e.getTouch(this, TouchPhase.ENDED);
        if (touch != null)
        {
            _particleContainer.inverted = !_particleContainer.inverted;
        }
    }
}
