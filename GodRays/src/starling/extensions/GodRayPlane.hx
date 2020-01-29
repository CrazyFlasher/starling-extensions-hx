package starling.extensions;

import openfl.Vector;
import starling.rendering.FilterEffect;
import openfl.display.BitmapData;
import openfl.display3D.Context3D;
import openfl.display3D.Context3DProgramType;
import starling.animation.IAnimatable;
import starling.display.Mesh;
import starling.display.Quad;
import starling.rendering.MeshEffect;
import starling.rendering.Program;
import starling.rendering.VertexDataFormat;
import starling.styles.MeshStyle;
import starling.textures.Texture;
import starling.utils.MathUtil;


/** A quad that efficiently renders a 2D light ray effect on its surface.
 *
 *  <p>This class is useful for adding atmospheric effects, like the typical effects you see
 *  underwater or in a forest. Add it to a juggler or call 'advanceTime' so that the effect
 *  becomes animated.</p>
 *
 *  <p>Play around with the different settings to make it suit the style you want. In addition
 *  to the class-specific properties, you can also assign an overall color or different colors
 *  per vertex.</p>
 */
class GodRayPlane extends Quad implements IAnimatable
{
    private var godRayStyle(get, never):GodRayStyle;
    public var speed(get, set):Float;
    public var skew(get, set):Float;
    public var shear(get, set):Float;
    public var size(get, set):Float;
    public var fade(get, set):Float;
    public var contrast(get, set):Float;

    private static inline var TEXTURE_HEIGHT:Int = 32;
    private static inline var TEXTURE_WIDTH:Int = 512;

    private var _bitmapData:BitmapData;
    private var _speed:Float;
    private var _size:Float;
    private var _skew:Float;
    private var _fade:Float;

    /** Create a new instance with the given size. Using a "packed" texture format produces
     *  a slightly different effect with visible gradient steps. */
    public function new(width:Float, height:Float, textureFormat:String = "bgra")
    {
        super(width, height);

        _speed = 0.1;
        _size = 0.1;
        _skew = 0.0;
        _fade = 1.0;

        _bitmapData = new BitmapData(TEXTURE_WIDTH, TEXTURE_HEIGHT, false);
        texture = Texture.empty(TEXTURE_WIDTH, TEXTURE_HEIGHT, true, false, false,
        1.0, textureFormat, true
        );

        updateTexture();
        textureRepeat = true;
        style = new GodRayStyle();
    }

    /** Disposes the internally used texture. */
    override public function dispose():Void
    {
        super.dispose();

        _bitmapData.dispose();
        texture.dispose();
    }

    private function updateTexture():Void
    {
        _bitmapData.perlinNoise(TEXTURE_WIDTH * _size, TEXTURE_HEIGHT * 0.2,
        2, 0, true, true, 0, true
        );
        texture.root.uploadBitmapData(_bitmapData);
    }

    private function updateVertices():Void
    {
        vertexData.setPoint(2, "texCoords", -_skew, 1.0);
        vertexData.setPoint(3, "texCoords", -_skew + 1.0, 1.0);

        vertexData.setAlpha(2, "color", 1.0 - _fade);
        vertexData.setAlpha(3, "color", 1.0 - _fade);
    }

    /** @inheritDoc */
    public function advanceTime(time:Float):Void
    {
        godRayStyle.offsetY += time * _speed;

        while (godRayStyle.offsetY > 1.0)
        {
            godRayStyle.offsetY -= 1.0;
        }
    }

    private function get_godRayStyle():GodRayStyle
    {
        return try cast(style, GodRayStyle) catch (e:Dynamic) null;
    }

    /** The speed with which the effect is animated. A value of '1.0' causes the pattern
     *  to repeat exactly after one second. Range: 0 - infinite. @default 0.1 */
    private function get_speed():Float
    {
        return _speed;
    }

    private function set_speed(value:Float):Float
    {
        _speed = MathUtil.max(0, value);
        return value;
    }

    /** Determines up the angle of the light rays.
     *  Range: -5 - 5. @default: 0.0 */
    private function get_skew():Float
    {
        return _skew;
    }

    private function set_skew(value:Float):Float
    {
        _skew = MathUtil.clamp(value, -5, 5);
        updateVertices();
        return value;
    }

    /** Determines the change in the light ray's angles over the width of the plane.
     *  Range: -1 - 10. @default: 0.0 */
    private function get_shear():Float
    {
        return godRayStyle.shear;
    }

    private function set_shear(value:Float):Float
    {
        godRayStyle.shear = value;
        return value;
    }

    /** The width of the rays. As a rule of thumb, one divided by this value will yield the
     *  approximate number of rays. Range: 0.0001 - 1. @default: 0.1 */
    private function get_size():Float
    {
        return _size;
    }

    private function set_size(value:Float):Float
    {
        _size = MathUtil.clamp(value, 0.0001, 1);
        updateTexture();
        return value;
    }

    /** Indicates how the light rays fade out towards the bottom. Zero means no fading,
     *  one means that the rays will become completely invisible at the bottom.
     *  Range: 0 - 1, default: 1 */
    private function get_fade():Float
    {
        return _fade;
    }

    private function set_fade(value:Float):Float
    {
        _fade = MathUtil.clamp(value, 0, 1);
        updateVertices();
        return value;
    }

    /** The distinctiveness and brightness of the light rays.
     *  Range: 0 - infinite, @default: 1 */
    private function get_contrast():Float
    {
        return godRayStyle.contrast;
    }

    private function set_contrast(value:Float):Float
    {
        godRayStyle.contrast = value;
        return value;
    }
}

class GodRayStyle extends MeshStyle
{
    public var shear(get, set):Float;
    public var offsetY(get, set):Float;
    public var contrast(get, set):Float;

    public static var VERTEX_FORMAT:VertexDataFormat =
    MeshStyle.VERTEX_FORMAT.extend("settings:float3");

    private var _offsetY:Float;
    private var _shear:Float;
    private var _contrast:Float;

    public function new()
    {
        super();
        _offsetY = 0.0;
        _shear = 0.0;
        _contrast = 1.0;
    }

    override public function copyFrom(meshStyle:MeshStyle):Void
    {
        var godRayStyle:GodRayStyle = try cast(meshStyle, GodRayStyle) catch (e:Dynamic) null;
        if (godRayStyle != null)
        {
            _offsetY = godRayStyle._offsetY;
            _shear = godRayStyle._shear;
            _contrast = godRayStyle._contrast;
        }

        super.copyFrom(meshStyle);
    }

    override public function createEffect():MeshEffect
    {
        return new GodRayEffect();
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
        if (target != null)
        {
            vertexData.setPremultipliedAlpha(false, true);

            var numVertices:Int = vertexData.numVertices;
            for (i in 0...numVertices)
            {
                vertexData.setPoint3D(i, "settings", _offsetY, _shear, _contrast);
            }

            setRequiresRedraw();
        }
    }

    private function get_shear():Float
    {
        return _shear;
    }

    private function set_shear(value:Float):Float
    {
        _shear = MathUtil.clamp(value, -1, 10);
        updateVertices();
        return value;
    }

    private function get_offsetY():Float
    {
        return _offsetY;
    }

    private function set_offsetY(value:Float):Float
    {
        _offsetY = value;updateVertices();
        return value;
    }

    private function get_contrast():Float
    {
        return _contrast;
    }

    private function set_contrast(value:Float):Float
    {
        _contrast = MathUtil.max(0, value);
        updateVertices();
        return value;
    }
}

class GodRayEffect extends MeshEffect
{
    private static var sConstants:Vector<Float> = new Vector<Float>([0, 1, 2, 0.5]);

    public function new()
    {
        super();
    }

    override private function createProgram():Program
    {
        var vertexShader:String = [
            "m44 op, va0, vc0", // 4x4 matrix transform to output clip-space  
            "mov v0, va1     ", // pass texture coordinates to fragment program  
            "mov v1.xyz, va2.xyz", // copy color to v1.xyz  
            "mul v1.w, va2.w, vc4.w", // copy combined alpha to v1.w  
            "mov v2, va3     "// pass settings to fp  
        ].join("\n");

        var fragmentShader:String = [
            // offset
            "mov ft0, v0",
            "mov ft0.y, v2.x",
            "mul ft2.x, v0.y, v2.y", // shear *= v  
            "add ft2.x, ft2.x, fc5.y", // shear = 1 + v * shear  
            "div ft0.x, ft0.x, ft2.x", // texture coordinates: divide 'u' by shear
                // texture lookup
            FilterEffect.tex("ft1", "ft0", 0, texture),

                // contrast
            "mul ft1.xyz, ft1.xyz, v2.zzz", // tex color *= contrast  
            "sub ft2.xyz, fc5.yyy, v2.zzz", // ft2 = 1 - contrast  
            "add ft1.xyz, ft1.xyz, ft2.xyz", // tex color += ft2  

                // alpha + tinting
            "mul ft1.w, ft1.x, v1.w", // multiply with vertex alpha  
            "mul ft1.xyz, ft1.xxx, v1.xyz", // tint with vertex color  
            "mul ft1.xyz, ft1.xyz, ft1.www", // premultiply alpha  

                // copy to output
            "mov oc, ft1"
        ].join("\n");

        return Program.fromSource(vertexShader, fragmentShader);
    }

    override private function get_vertexFormat():VertexDataFormat
    {
        return GodRayStyle.VERTEX_FORMAT;
    }

    override private function beforeDraw(context:Context3D):Void
    {
        super.beforeDraw(context);
        context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 5, sConstants);
        vertexFormat.setVertexBufferAt(3, vertexBuffer, "settings");
    }

    override private function afterDraw(context:Context3D):Void
    {
        context.setVertexBufferAt(3, null);
        super.afterDraw(context);
    }
}