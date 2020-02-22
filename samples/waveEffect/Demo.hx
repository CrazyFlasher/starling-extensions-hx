import starling.display.Image;
import starling.extensions.wave.WaveSource;
import starling.extensions.wave.WaveFilter;
import openfl.geom.Point;
import starling.core.Starling;
import starling.display.Sprite;
import starling.assets.AssetManager;

class Demo extends Sprite
{
	public function new()
	{
		super();
	}

	public function start(assets:AssetManager):Void
	{
		//creating and configuring the WaveFilter
		var waveFilter:WaveFilter = new WaveFilter();
		var linear_source:WaveSource = new WaveSource(WaveSource.LINEAR, .01, .5, 50, 30);
		var radial_source:WaveSource = new WaveSource(WaveSource.RADIAL, .02, 5, 60, 5, new Point(.3, .3), 1);

		waveFilter.addWaveSource(linear_source);
		waveFilter.addWaveSource(radial_source);
		Starling.current.juggler.add(waveFilter);

		//creating an Image and applying the filter
		var image:Image = new Image(assets.getTexture("ocean"));
		image.filter = waveFilter;
		addChild(image);
	}
}
