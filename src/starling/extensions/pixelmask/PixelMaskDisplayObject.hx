package starling.extensions.pixelmask;

import openfl.display3D.Context3DBlendFactor;
import openfl.errors.Error;
import openfl.geom.Matrix;
import openfl.geom.Rectangle;
import starling.core.Starling;
import starling.display.BlendMode;
import starling.display.DisplayObject;
import starling.display.DisplayObjectContainer;
import starling.display.Quad;
import starling.events.Event;
import starling.rendering.Painter;
import starling.textures.RenderTexture;
import starling.utils.Pool;

class PixelMaskDisplayObject extends DisplayObjectContainer
{
	public var isAnimated(get, set):Bool;
	public var inverted(get, set):Bool;
	public var pixelMask(get, set):DisplayObject;

	private static inline var MASK_MODE_NORMAL:String = "mask";
	private static inline var MASK_MODE_INVERTED:String = "maskInverted";

	private var _mask:DisplayObject;
	private var _renderTexture:RenderTexture;
	private var _maskRenderTexture:RenderTexture;

	private var _quad:Quad;
	private var _maskQuad:Quad;

	private var _superRenderFlag:Bool = false;
	private var _scaleFactor:Float;
	private var _isAnimated:Bool = true;
	private var _maskRendered:Bool = false;

	private static var sIdentity:Matrix = new Matrix();

	public function new(scaleFactor:Float = -1, isAnimated:Bool = true)
	{
		super();

		BlendMode.register(MASK_MODE_NORMAL, Context3DBlendFactor.ZERO, Context3DBlendFactor.SOURCE_ALPHA);
		BlendMode.register(MASK_MODE_INVERTED, Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);

		_isAnimated = isAnimated;
		_scaleFactor = scaleFactor;

		_quad = new Quad(100, 100);
		_maskQuad = new Quad(100, 100);
		_maskQuad.blendMode = MASK_MODE_NORMAL;

		// Handle lost context. By using the conventional event, we can make a weak listener.
		// This avoids memory leaks when people forget to call "dispose" on the object.
		Starling.current.stage3D.addEventListener(Event.CONTEXT3D_CREATE,
												  onContextCreated, false, 0, true
		);
	}

	override public function dispose():Void
	{
		clearRenderTextures();

		_quad.dispose();
		_maskQuad.dispose();

		Starling.current.stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
		super.dispose();
	}

	private function onContextCreated(event:Dynamic):Void
	{
		refreshRenderTextures();
	}

	private function get_isAnimated():Bool
	{
		return _isAnimated;
	}

	private function set_isAnimated(value:Bool):Bool
	{
		_isAnimated = value;
		return value;
	}

	private function get_inverted():Bool
	{
		return _maskQuad.blendMode == MASK_MODE_INVERTED;
	}

	private function set_inverted(value:Bool):Bool
	{
		_maskQuad.blendMode = (value) ? MASK_MODE_INVERTED : MASK_MODE_NORMAL;
		return value;
	}

	private function get_pixelMask():DisplayObject
	{
		return _mask;
	}

	private function set_pixelMask(value:DisplayObject):DisplayObject
	{
		_mask = value;

		if (value != null)
		{
			if (_mask.width == 0 || _mask.height == 0)
			{
				throw new Error("Mask must have dimensions. Current dimensions are " +
				_mask.width + "x" + _mask.height + ".");
			}

			refreshRenderTextures();
		}
		else
		{
			clearRenderTextures();
		}
		return value;
	}

	private function clearRenderTextures():Void
	{
		if (_maskRenderTexture != null)
		{
			_maskRenderTexture.dispose();
		}
		if (_renderTexture != null)
		{
			_renderTexture.dispose();
		}
	}

	private function refreshRenderTextures():Void
	{
		if (_mask != null)
		{
			clearRenderTextures();

			var maskBounds:Rectangle = _mask.getBounds(_mask, Pool.getRectangle());
			var maskWidth:Float = maskBounds.width;
			var maskHeight:Float = maskBounds.height;
			Pool.putRectangle(maskBounds);

			_renderTexture = new RenderTexture(Math.ceil(maskWidth), Math.ceil(maskHeight), false, _scaleFactor);
			_maskRenderTexture = new RenderTexture(Math.ceil(maskWidth), Math.ceil(maskHeight), false, _scaleFactor);

			// quad using the new render texture
			_quad.texture = _renderTexture;
			_quad.readjustSize();

			// quad to blit the mask onto
			_maskQuad.texture = _maskRenderTexture;
			_maskQuad.readjustSize();
		}

		_maskRendered = false;
	}

	override public function render(painter:Painter):Void
	{
		if (_isAnimated || (!_isAnimated && !_maskRendered))
		{
			painter.finishMeshBatch();
			painter.excludeFromCache(this);

			if (_superRenderFlag || _mask == null)
			{
				super.render(painter);
			}
			else if (_mask != null)
			{
				_maskRenderTexture.draw(_mask, sIdentity);
				_renderTexture.drawBundled(drawRenderTextures);

				painter.pushState();
				painter.state.transformModelviewMatrix(_mask.transformationMatrix);

				_quad.render(painter);
				_maskRendered = true;

				painter.popState();
			}
		}
		else
		{
			_quad.render(painter);
		}
	}

	private function drawRenderTextures():Void
	{
		var matrix:Matrix = Pool.getMatrix();
		matrix.copyFrom(_mask.transformationMatrix);
		matrix.invert();

		_superRenderFlag = true;
		_renderTexture.draw(this, matrix);
		_superRenderFlag = false;
		_renderTexture.draw(_maskQuad, sIdentity);

		Pool.putMatrix(matrix);
	}
}
