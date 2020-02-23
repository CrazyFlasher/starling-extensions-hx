// =================================================================================================
//
//	Starling Framework
//	Copyright 2011-2016 Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions;

import openfl.display3D.Context3D;
import starling.display.Mesh;
import starling.rendering.FilterEffect;
import starling.rendering.MeshEffect;
import starling.rendering.Program;
import starling.rendering.VertexDataFormat;
import starling.styles.MeshStyle;

@:keep
class TextureMaskStyle extends MeshStyle
{
	public var threshold(get, set):Float;

	public static var VERTEX_FORMAT:VertexDataFormat = MeshStyle.VERTEX_FORMAT.extend("threshold:float1");

	private var _threshold:Float;

	public function new(threshold:Float = 0.5)
	{
		super();

		_threshold = threshold;
	}

	/*override public function copyFrom(meshStyle:MeshStyle):Void
	{
		var otherStyle:TextureMaskStyle = cast meshStyle;
		if (otherStyle != null)
		{
			_threshold = otherStyle._threshold;
		}

		super.copyFrom(meshStyle);
	}*/

	override public function createEffect():MeshEffect
	{
		return new TextureMaskEffect();
	}

	override private function get_vertexFormat():VertexDataFormat
	{
		return VERTEX_FORMAT;
	}

	override private function onTargetAssigned(target:Mesh):Void
	{
		updateVertices();
	}

	private function updateVertices():Void
	{
		var numVertices:Int = vertexData.numVertices;
		for (i in 0...numVertices)
		{
			vertexData.setFloat(i, "threshold", _threshold);
		}

		setRequiresRedraw();
	}

	// properties

	private function get_threshold():Float
	{
		return _threshold;
	}

	private function set_threshold(value:Float):Float
	{
		if (_threshold != value && target != null)
		{
			_threshold = value;
			updateVertices();
		}
		return value;
	}
}

@:keep
class TextureMaskEffect extends MeshEffect
{
	public static var VERTEX_FORMAT:VertexDataFormat = TextureMaskStyle.VERTEX_FORMAT;

	public function new()
	{
		super();
	}

	override private function createProgram():Program
	{
		if (texture != null)
		{
			var vertexShader:String = [
				"m44 op, va0, vc0", // 4x4 matrix transform to output clip-space
				"mov v0, va1     ", // pass texture coordinates to fragment program
				"mul v1, va2, vc4", // multiply alpha (vc4) with color (va2), pass to fp
				"mov v2, va3     " // pass threshold to fp
			].join("\n");

			var fragmentShader:String = [
                FilterEffect.tex("ft0", "v0", 0, texture),
				"sub ft1, ft0, v2.xxxx", // subtract threshold
				"kil ft1.w            ", // abort if alpha < 0
				"mul  oc, ft0, v1     " // else multiply with color & copy to output buffer
			].join("\n");

			return Program.fromSource(vertexShader, fragmentShader);
		}
		else
		{
			return super.createProgram();
		}
	}

	override private function beforeDraw(context:Context3D):Void
	{
		super.beforeDraw(context);

		if (texture != null)
		{
			vertexFormat.setVertexBufferAt(3, vertexBuffer, "threshold");
		}
	}

	override private function afterDraw(context:Context3D):Void
	{
		if (texture != null)
		{
			context.setVertexBufferAt(3, null);
		}
		super.afterDraw(context);
	}

	override private function get_vertexFormat():VertexDataFormat
	{
		return VERTEX_FORMAT;
	}
}