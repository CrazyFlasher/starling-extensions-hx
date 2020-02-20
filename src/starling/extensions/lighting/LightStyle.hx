// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.extensions.lighting;

import openfl.geom.Matrix3D;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import starling.core.Starling;
import starling.display.Mesh;
import starling.display.Stage;
import starling.rendering.MeshEffect;
import starling.rendering.RenderState;
import starling.rendering.VertexData;
import starling.rendering.VertexDataFormat;
import starling.styles.MeshStyle;
import starling.textures.Texture;
import starling.utils.Color;
import starling.utils.MathUtil;
import starling.utils.MatrixUtil;

/** A mesh style that uses a normal map for dynamic, realistic lighting effects.
 *
 *  <p>Dynamic lighting requires information in which direction a pixel is facing. The
 *  direction information — encoded into a color value — is called a normal map. Normal
 *  maps can be created directly from a 3D program, or drawn on top of 2D objects with
 *  tools like <a href="https://www.codeandweb.com/spriteilluminator">SpriteIlluminator</a>.
 *  </p>
 *
 *  <p>The LightStyle class allows you to attach such a normal map to any Starling mesh.
 *  Furthermore, you can configure the material of the object, e.g. the amount of light
 *  it reflects. Beware that objects are invisible (i.e., black) until you add at least
 *  one light source to the stage!</p>
 *
 *  @see LightSource
 */
class LightStyle extends MeshStyle
{
	public var normalTexture(get, set):Texture;
	public var ambientRatio(get, set):Float;
	public var diffuseRatio(get, set):Float;
	public var specularRatio(get, set):Float;
	public var shininess(get, set):Float;

	public static var VERTEX_FORMAT:VertexDataFormat = LightEffect.VERTEX_FORMAT;

	/** The highest supported value for 'shininess'. */
	public static inline var MAX_SHININESS:Float = 32.0;

	/** The maximum number of light sources that may be used. */
	public static inline var MAX_NUM_LIGHTS:Int = 8;

	private var _normalTexture:Texture;
	private var _material:Material;

	// helpers
	private var sPoint:Point = new Point();
	private var sPoint3D:Vector3D = new Vector3D();
	private var sMatrix:Matrix = new Matrix();
	private var sMatrix3D:Matrix3D = new Matrix3D();
	private var sMatrixAlt3D:Matrix3D = new Matrix3D();
	private var sMaterial:Material = new Material();
	private var sLights:Array<LightSource> = [];

	/** Creates a new instance with the given normal texture. */
	public function new(normalTexture:Texture = null)
	{
		super();
		_normalTexture = normalTexture;
		_material = new Material();
	}

	/** Sets the texture coordinates of the specified vertex within the normal texture
     *  to the given values. */
	private function setNormalTexCoords(vertexID:Int, u:Float, v:Float):Void
	{
		if (_normalTexture != null)
		{
			_normalTexture.setTexCoords(vertexData, vertexID, "normalTexCoords", u, v);
		}
		else
		{
			vertexData.setPoint(vertexID, "normalTexCoords", u, v);
		}

		setRequiresRedraw();
	}

	/** @private */
	override public function setTexCoords(vertexID:Int, u:Float, v:Float):Void
		// In this case, it makes sense to simply sync the texture coordinates of the
	{

		// standard texture with those of the normal texture.

		setNormalTexCoords(vertexID, u, v);
		super.setTexCoords(vertexID, u, v);
	}

	/** @private */
	override public function copyFrom(meshStyle:MeshStyle):Void
	{
		if (meshStyle != null && Std.is(meshStyle, LightStyle))
		{
			var litMeshStyle:LightStyle = cast (meshStyle, LightStyle);
			_normalTexture = litMeshStyle._normalTexture;
			_material.copyFrom(litMeshStyle._material);
		}

		super.copyFrom(meshStyle);
	}

	/** @private */
	override public function batchVertexData(targetStyle:MeshStyle, targetVertexID:Int = 0,
											 matrix:Matrix = null, vertexID:Int = 0,
											 numVertices:Int = -1):Void
	{
		super.batchVertexData(targetStyle, targetVertexID, matrix, vertexID, numVertices);

		if (matrix != null)
		{
			// when the mesh is transformed, the directions of the normal vectors must change,
			// too. To be able to rotate them correctly in the shaders, we store the direction
			// of x- and y-axis in the vertex data. (The z-axis is the cross product of x & y.)

			var targetLightStyle:LightStyle = cast (targetStyle, LightStyle);
			var targetVertexData:VertexData = targetLightStyle.vertexData;

			sMatrix.setTo(matrix.a, matrix.b, matrix.c, matrix.d, 0, 0);
			vertexData.copyAttributeTo(targetVertexData, targetVertexID, "xAxis", sMatrix, vertexID, numVertices);
			vertexData.copyAttributeTo(targetVertexData, targetVertexID, "yAxis", sMatrix, vertexID, numVertices);

			if (matrix.a * matrix.d < 0)
			{
				// When we end up here, the mesh has been flipped horizontally or vertically.
				// Unfortunately, this makes the local z-axis point into the screen, which
				// means we're now looking at the object from behind, and it becomes dark.
				// We reverse this effect manually via the "zScale" vertex attribute.

				if (numVertices < 0)
				{
					numVertices = vertexData.numVertices - vertexID;
				}

				for (i in 0...numVertices)
				{
					var zScale:Float = vertexData.getFloat(vertexID + i, "zScale");
					targetVertexData.setFloat(targetVertexID + i, "zScale", zScale * -1);
				}
			}
		}
	}

/** @private */
	override public function canBatchWith(meshStyle:MeshStyle):Bool
	{
		var litMeshStyle:LightStyle;

		if (meshStyle != null && Std.is(meshStyle, LightStyle))
		{
			litMeshStyle = cast (meshStyle, LightStyle);

			if (super.canBatchWith(meshStyle))
			{
				var newNormalTexture:Texture = litMeshStyle._normalTexture;

				if (_normalTexture == null && newNormalTexture == null)
				{
					return true;
				}
				else if (_normalTexture != null && newNormalTexture != null)
				{
					return _normalTexture.base == newNormalTexture.base;
				}
				else
				{
					return false;
				}
			}
		}

		return false;
	}

	/** @private */
	override public function createEffect():MeshEffect
	{
		return new LightEffect();
	}

	/** @private */
	override public function updateEffect(effect:MeshEffect, state:RenderState):Void
	{
		var lightEffect:LightEffect = cast (effect, LightEffect);
		lightEffect.normalTexture = _normalTexture;

		var stage:Stage = target.stage != null ? target.stage : Starling.current.stage;
		var lights:Array<LightSource> = LightSource.getActiveInstances(stage, sLights);
		lightEffect.numLights = lights.length;

		// get transformation matrix from the stage to the current coordinate system
		if (state.is3D)
		{
			sMatrixAlt3D.copyFrom(state.modelviewMatrix3D);
		}
		else
		{
			MatrixUtil.convertTo3D(state.modelviewMatrix, sMatrixAlt3D);
		}
		sMatrixAlt3D.invert();

		// update camera position
		sPoint3D.copyFrom(stage.cameraPosition);
		MatrixUtil.transformPoint3D(sMatrixAlt3D, sPoint3D, lightEffect.cameraPosition);

		var i:Int = 0;
		while (i < lights.length)
		{
			var light:LightSource = lights[i];
			var lightColor:Int = Color.multiply(light.color, light.brightness);
			var lightPosOrDir:Vector3D;

			// get transformation matrix from the light to the current coordinate system
			light.getTransformationMatrix3D(null, sMatrix3D);
			sMatrix3D.append(sMatrixAlt3D);

			if (light.type == LightSource.TYPE_POINT)
			{
				lightPosOrDir = MatrixUtil.transformCoords3D(sMatrix3D, 0, 0, 0, sPoint3D);
			}
				// type = directional
			else
			{

				{
					// we're only interested in the rotation, so we wipe out any translations
					sPoint3D.setTo(0, 0, 0);
					sMatrix3D.copyColumnFrom(3, sPoint3D);
					lightPosOrDir = MatrixUtil.transformCoords3D(sMatrix3D, -1, 0, 0, sPoint3D);
				}
			}

			// update light properties
			lightEffect.setLightAt(i, light.type, lightColor, lightPosOrDir);
			++i;
		}

		super.updateEffect(effect, state);
	}

/** @private */
	override private function get_vertexFormat():VertexDataFormat
	{
		return VERTEX_FORMAT;
	}

/** @private */
	override private function onTargetAssigned(target:Mesh):Void
	{
		var numVertices:Int = vertexData.numVertices;

		for (i in 0...numVertices)
		{
			getTexCoords(i, sPoint);
			setNormalTexCoords(i, sPoint.x, sPoint.y);
			setVertexMaterial(i, _material);
			vertexData.setPoint(i, "xAxis", 1, 0);
			vertexData.setPoint(i, "yAxis", 0, 1);
			vertexData.setFloat(i, "zScale", 1);
		}
	}

	/** The texture encoding the surface normals. */
	private function get_normalTexture():Texture
	{
		return _normalTexture;
	}

	private function set_normalTexture(value:Texture):Texture
	{
		if (value != _normalTexture)
		{
			if (target != null)
			{
				var i:Int = 0;
				while (i < vertexData.numVertices)
				{
					getTexCoords(i, sPoint);
					if (value != null)
					{
						value.setTexCoords(vertexData, i, "normalTexCoords", sPoint.x, sPoint.y);
					}
					++i;
				}
			}

			_normalTexture = value;
			setRequiresRedraw();
		}
		return value;
	}

	private function setVertexMaterial(vertexID:Int, material:Material):Void
	{
		vertexData.setUnsignedInt(vertexID, "material", material.encode());
		setRequiresRedraw();
	}

	private function getVertexMaterial(vertexID:Int, out:Material = null):Material
	{
		if (out == null)
		{
			out = new Material();
		}
		out.decode(vertexData.getUnsignedInt(vertexID, "material"));
		return out;
	}

	/** Returns the amount of ambient light reflected by the surface around the given vertex.
     *  As a rule of thumb, ambient and diffuse ratio should sum up to '1'. @default 0.5 */
	public function getAmbientRatio(vertexID:Int):Float
	{
		return getVertexMaterial(vertexID).ambientRatio;
	}

	/** Assigns the amount of ambient light reflected by the surface around the given vertex.
     *  As a rule of thumb, ambient and diffuse ratio should sum up to '1'. */
	public function setAmbientRatio(vertexID:Int, value:Float):Void
	{
		getVertexMaterial(vertexID, sMaterial);

		if (sMaterial.ambientRatio != value)
		{
			sMaterial.ambientRatio = value;
			setVertexMaterial(vertexID, sMaterial);
		}
	}

	/** Returns the amount of diffuse light reflected by the surface around the given vertex.
     *  As a rule of thumb, ambient and diffuse ratio should sum up to '1'. @default 0.5 */
	public function getDiffuseRatio(vertexID:Int):Float
	{
		return getVertexMaterial(vertexID).diffuseRatio;
	}

	/** Assigns the amount of diffuse light reflected by the surface around the given vertex.
     *  As a rule of thumb, ambient and diffuse ratio should sum up to '1'. */
	public function setDiffuseRatio(vertexID:Int, value:Float):Void
	{
		getVertexMaterial(vertexID, sMaterial);

		if (sMaterial.diffuseRatio != value)
		{
			sMaterial.diffuseRatio = value;
			setVertexMaterial(vertexID, sMaterial);
		}
	}

	/** Returns the amount of specular light reflected by the surface around the given vertex.
     *  @default 0.1 */
	public function getSpecularRatio(vertexID:Int):Float
	{
		return getVertexMaterial(vertexID).specularRatio;
	}

	/** Assigns the amount of specular light reflected by the surface around the given vertex.
     */
	public function setSpecularRatio(vertexID:Int, value:Float):Void
	{
		getVertexMaterial(vertexID, sMaterial);

		if (sMaterial.specularRatio != value)
		{
			sMaterial.specularRatio = value;
			setVertexMaterial(vertexID, sMaterial);
		}
	}

	/** Shininess is larger for surfaces that are smooth and mirror-like. When this value
     *  is large the specular highlight is small. Range: 0 - 32 @default 1.0 */
	public function getShininess(vertexID:Int):Float
	{
		return getVertexMaterial(vertexID).shininess;
	}

	/** Shininess is larger for surfaces that are smooth and mirror-like. When this value
     *  is large the specular highlight is small. Range: 0 - 32 @default 1.0 */
	public function setShininess(vertexID:Int, value:Float):Void
	{
		getVertexMaterial(vertexID, sMaterial);

		if (sMaterial.shininess != value)
		{
			sMaterial.shininess = value;
			setVertexMaterial(vertexID, sMaterial);
		}
	}

	/** The amount of ambient light reflected by the surface. As a rule of thumb, ambient
     *  and diffuse ratio should sum up to '1'. @default 0.5 */
	private function get_ambientRatio():Float
	{
		return _material.ambientRatio;
	}

	private function set_ambientRatio(value:Float):Float
	{
		_material.ambientRatio = value;

		if (vertexData != null)
		{
			var i:Int = 0;
			var len:Int = vertexData.numVertices;
			while (i < len)
			{
				setAmbientRatio(i, value);
				++i;
			}
		}
		return value;
	}

	/** The amount of diffuse light reflected by the surface. As a rule of thumb, ambient
     *  and diffuse ratio should sum up to '1'. @default 0.5 */
	private function get_diffuseRatio():Float
	{
		return _material.diffuseRatio;
	}

	private function set_diffuseRatio(value:Float):Float
	{
		_material.diffuseRatio = value;

		if (vertexData != null)
		{
			var i:Int = 0;
			var len:Int = vertexData.numVertices;
			while (i < len)
			{
				setDiffuseRatio(i, value);
				++i;
			}
		}
		return value;
	}

	/** The amount of specular light reflected by the surface. @default 0.1 */
	private function get_specularRatio():Float
	{
		return _material.specularRatio;
	}

	private function set_specularRatio(value:Float):Float
	{
		_material.specularRatio = value;

		if (vertexData != null)
		{
			var i:Int = 0;
			var len:Int = vertexData.numVertices;
			while (i < len)
			{
				setSpecularRatio(i, value);
				++i;
			}
		}
		return value;
	}

	/** Shininess is larger for surfaces that are smooth and mirror-like. When this value
     *  is large the specular highlight is small. Range: 0 - 32 @default 1.0 */
	private function get_shininess():Float
	{
		return _material.shininess;
	}

	private function set_shininess(value:Float):Float
	{
		_material.shininess = value;

		if (vertexData != null)
		{
			var i:Int = 0;
			var len:Int = vertexData.numVertices;
			while (i < len)
			{
				setShininess(i, value);
				++i;
			}
		}
		return value;
	}
}


class Material
{
	public var ambientRatio:Float;
	public var diffuseRatio:Float;
	public var specularRatio:Float;
	public var shininess:Float;

	public function new(ambientRatio:Float = 0.5, diffuseRatio:Float = 0.5,
						specularRatio:Float = 0.1, shininess:Float = 1.0)
	{
		this.ambientRatio = ambientRatio;
		this.diffuseRatio = diffuseRatio;
		this.specularRatio = specularRatio;
		this.shininess = shininess;
	}

	public function copyFrom(material:Material):Void
	{
		ambientRatio = material.ambientRatio;
		diffuseRatio = material.diffuseRatio;
		specularRatio = material.specularRatio;
		shininess = material.shininess;
	}

	public function decode(encoded:Int):Void
	{
		ambientRatio = (encoded & 0xff) / 255.0;
		diffuseRatio = ((encoded >> 8) & 0xff) / 255.0;
		specularRatio = ((encoded >> 16) & 0xff) / 255.0;
		shininess = ((encoded >> 24) & 0xff) / 255.0 * LightStyle.MAX_SHININESS;
	}

	public function encode():Int
		// all other material ratios are between 0 and 1; shininess, however, goes up to
	{

		// MAX_SHININESS. We store its ratio relative to the maximum and restore the actual
		// value in "decode" and in the vertex shader.

		var S:Float = LightStyle.MAX_SHININESS;

		var amb:Int = Std.int(MathUtil.clamp(ambientRatio * 255, 0, 255));
		var dif:Int = Std.int(MathUtil.clamp(diffuseRatio * 255, 0, 255));
		var spe:Int = Std.int(MathUtil.clamp(specularRatio * 255, 0, 255));
		var shi:Int = Std.int(MathUtil.clamp(shininess / S * 255, 0, 255));

		return (amb | (dif << 8) | (spe << 16) | (shi << 24));
	}
}