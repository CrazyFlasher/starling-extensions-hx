package starling.extensions.wave;

import flash.geom.Point;

class WaveSource
{
	public static inline var LINEAR:Int = 0;
	public static inline var RADIAL:Int = 1;

	public var type:Int;

	public var amplitude:Float;
	public var frequency:Float;

	public var xComponent:Float; // density on x axis
	public var yComponent:Float; // density on y axis, no effect on RADIAL sources

	public var origin:Point; // center of radial waves - relative tex coordinates 0-1, not used on LINEAR
	public var fallOff:Float; // not used
	public var aspect:Float; // texture aspect, not used on LINEAR

	public var time:Float;
	public var propagation:Float; // wave propagation speed, 0=instant, not used on LINEAR


	public function new(type:Int, amplitude:Float = .01, frequency:Float = 5, xComponent:Float = 20, yComponent:Float = 5,
						origin:Point = null, aspect:Float = 1, propagation:Float = 0, fallOff:Float = 0)
	{
		this.type = type;
		this.amplitude = amplitude;
		this.frequency = frequency;
		this.xComponent = xComponent;
		this.yComponent = yComponent;
		(origin == null) ? this.origin = new Point(.5, .5) : this.origin = origin;
		this.aspect = aspect;
		this.fallOff = fallOff;
		this.time = 0;
		this.propagation = propagation;
	}
}

