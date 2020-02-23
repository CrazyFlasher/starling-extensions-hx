package starling.extensions.wave;

import starling.animation.IAnimatable;
import starling.filters.FragmentFilter;
import starling.rendering.FilterEffect;

@:keep
class WaveFilter extends FragmentFilter implements IAnimatable
{
	private var waveEffect(get, never):WaveEffect;

	public function new()
	{
		super();
	}

	override private function createEffect():FilterEffect
	{
		return new WaveEffect();
	}

	private function get_waveEffect():WaveEffect
	{
		return Std.is(effect, WaveEffect) ? cast (effect, WaveEffect) : null;
	}

	//TODO: Setters and Getters ?
	public function addWaveSource(src:WaveSource):Void
	{
		waveEffect.addWaveSource(src);
		setRequiresRedraw();
	}

	public function removeWaveSource(src:WaveSource):Void
	{
		waveEffect.removeWaveSource(src);
		setRequiresRedraw();
	}

	public function advanceTime(time:Float):Void
	{
		waveEffect.advanceTime(time);
		setRequiresRedraw();
	}
}

