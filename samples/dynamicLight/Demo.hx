import openfl.geom.Rectangle;
import starling.extensions.lighting.LightStyle;
import openfl.geom.Point;
import starling.events.Touch;
import starling.events.TouchPhase;
import starling.events.TouchEvent;
import starling.display.DisplayObject;
import starling.display.Sprite3D;
import starling.events.Event;
import starling.display.MovieClip;
import starling.extensions.lighting.LightSource;
import openfl.Vector;
import starling.textures.TextureAtlas;
import starling.textures.Texture;
import starling.core.Starling;
import starling.display.Sprite;
import starling.assets.AssetManager;

class Demo extends Sprite
{
	private var _characters:Sprite;
	private var _stageWidth:Float;
	private var _stageHeight:Float;

	public function new()
	{
		super();
	}

	public function start(assets:AssetManager):Void
	{
		_stageWidth = Starling.current.stage.stageWidth;
		_stageHeight = Starling.current.stage.stageHeight;

		_characters = new Sprite();
		_characters.y = _stageHeight / 2;
		addChild(_characters);

		var characterNormalTexture:Texture = assets.getTexture("character_n");
		var characterXml:Xml = assets.getXml("character");

		var normalTextureAtlas:TextureAtlas = new TextureAtlas(characterNormalTexture, characterXml);
		var textures:Vector<Texture> = assets.getTextureAtlas("character").getTextures();
		var normalTextures:Vector<Texture> = normalTextureAtlas.getTextures();

		var bulbTextureAltas:Texture = assets.getTexture("lightbulbs");
		var textureWidth:Float = bulbTextureAltas.width / 3;
		var textureHeight:Float = bulbTextureAltas.height;

		var pointLightTexture:Texture = Texture.fromTexture(bulbTextureAltas, new Rectangle(0, 0, textureWidth, textureHeight));
		var ambientLightTexture:Texture = Texture.fromTexture(bulbTextureAltas, new Rectangle(textureWidth, 0, textureWidth, textureHeight));
		var directionalLightTexture:Texture = Texture.fromTexture(bulbTextureAltas, new Rectangle(textureWidth * 2, 0, textureWidth,
			textureHeight));

		var ambientLight:LightSource = LightSource.createAmbientLight();
		ambientLight.x = _stageWidth * 0.5;
		ambientLight.y = _stageHeight * 0.2;
		ambientLight.z = -150;
		ambientLight.showLightBulb = ambientLightTexture;

		var pointLightA:LightSource = LightSource.createPointLight(0x00ff00);
		pointLightA.x = _stageWidth * 0.25;
		pointLightA.y = _stageHeight * 0.2;
		pointLightA.z = -150;
		pointLightA.showLightBulb = pointLightTexture;

		var pointLightB:LightSource = LightSource.createPointLight(0xff00ff);
		pointLightB.x = _stageWidth * 0.75;
		pointLightB.y = _stageHeight * 0.2;
		pointLightB.z = -150;
		pointLightB.showLightBulb = pointLightTexture;

		var directionalLight:LightSource = LightSource.createDirectionalLight();
		directionalLight.x = _stageWidth * 0.6;
		directionalLight.y = _stageHeight * 0.3;
		directionalLight.z = -150;
		directionalLight.rotationY = -1.0;
		directionalLight.showLightBulb = directionalLightTexture;

		addMarchingCharacters(8, textures, normalTextures);
		// addStaticCharacter(textures[0], normalTextures[0]);

		addChild(ambientLight);
		addChild(pointLightA);
		addChild(pointLightB);
		// addChild(directionalLight);
	}

	private function addMarchingCharacters(count:Int,
										   textures:Vector<Texture>,
										   normalTextures:Vector<Texture>):Void
	{
		var characterWidth:Float = textures[0].frameWidth;
		var offset:Float = (_stageWidth + characterWidth) / count;

		for (i in 0...count)
		{
			var movie:MovieClip = createCharacter(textures, normalTextures);
			movie.currentTime = movie.totalTime * Math.random();
			movie.x = -characterWidth + i * offset;
			movie.y = movie.height / -2;
			movie.addEventListener(Event.ENTER_FRAME, (event:Event, passedTime:Float) -> {
				var character:MovieClip = cast event.target;
				character.advanceTime(passedTime);
				character.x += 100 * passedTime;

				if (character.x > _stageWidth)
					character.x = -character.width + (character.x - _stageWidth);
			});
			addChild(movie);
			_characters.addChild(movie);
		}
	}

	/** This method is useful during development, to have a simple static image that's easy
         *  to experiment with. */
	private function addStaticCharacter(texture:Texture, normalTexture:Texture):Void
	{
		var movie:MovieClip = createCharacter(
			new Vector<Texture>([texture]),
			new Vector<Texture>([normalTexture]), 1);

		movie.alignPivot();
		_characters.addChild(movie);

		var sprite3D:Sprite3D = new Sprite3D();
		sprite3D.addChild(movie);
		sprite3D.x = _stageWidth / 2 + 0.5;
		sprite3D.y = _stageHeight / 2 + 0.5;
		addChild(sprite3D);

		var that:DisplayObject = this;

		sprite3D.addEventListener(TouchEvent.TOUCH, function(event:TouchEvent):Void
		{
			var touch:Touch = event.getTouch(sprite3D, TouchPhase.MOVED);
			if (touch != null)
			{
				var movement:Point = touch.getMovement(that);

				if (event.shiftKey)
				{
					sprite3D.rotationX -= movement.y * 0.01;
					sprite3D.rotationY += movement.x * 0.01;
				} else
				{
					sprite3D.x += movement.x;
					sprite3D.y += movement.y;
				}
			}
		});
	}

	private function createCharacter(textures:Vector<Texture>,
									 normalTextures:Vector<Texture>,
									 fps:Int = 12):MovieClip
	{
		var movie:MovieClip = new MovieClip(textures, fps);
		var lightStyle:LightStyle = new LightStyle(normalTextures[0]);
		lightStyle.ambientRatio = 0.3;
		lightStyle.diffuseRatio = 0.7;
		lightStyle.specularRatio = 0.5;
		lightStyle.shininess = 16;

		movie.style = lightStyle;

		for (i in 0...movie.numFrames)
		{
			movie.setFrameAction(i, (movieClip:MovieClip, frameID:Int) ->
			{
				lightStyle.normalTexture = normalTextures[frameID];
			});
		}

		return movie;
	}
}
