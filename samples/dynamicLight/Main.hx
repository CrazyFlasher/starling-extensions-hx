import openfl.display.StageAlign;
import openfl.display.StageScaleMode;
import openfl.display3D.Context3DRenderMode;
import openfl.system.Capabilities;
import openfl.utils.Assets;
import starling.assets.AssetManager;
import starling.core.Starling;

class Main extends openfl.display.Sprite
{
    private var _starling:Starling;
    private var _assets:AssetManager;

    private var demo:Demo;

    public function new()
    {
        super();

        init();
    }

    private function init():Void
    {
        stage.scaleMode = StageScaleMode.NO_SCALE;
        stage.align = StageAlign.TOP_LEFT;

        Starling.multitouchEnabled = true; // for Multitouch Scene

        _starling = new Starling(Demo, stage, null, null, Context3DRenderMode.AUTO, "auto");
        _starling.stage.stageWidth = stage.stageWidth;
        _starling.stage.stageHeight = stage.stageHeight;
        _starling.enableErrorChecking = Capabilities.isDebugger;
        _starling.skipUnchangedFrames = true;
        _starling.supportBrowserZoom = true;
        _starling.supportHighResolutions = true;
        _starling.simulateMultitouch = true;
        _starling.addEventListener(starling.events.Event.ROOT_CREATED, function():Void
        {
            loadAssets(startGame);
        });

        _starling.start();
    }

    private function loadAssets(onComplete:Void -> Void):Void
    {
        _assets = new AssetManager();

        _assets.verbose = true;
        _assets.enqueue([
            Assets.getPath("assets/lightbulbs.png"),
            Assets.getPath("assets/character.png"),
            Assets.getPath("assets/character_n.png"),
            Assets.getPath("assets/character.xml")
        ]);
        _assets.loadQueue(onComplete);
    }

    private function startGame():Void
    {
        demo = cast(_starling.root, Demo);
        demo.start(_assets);
    }
}
