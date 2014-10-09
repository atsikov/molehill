package molehill.core.utils
{
	import flash.geom.Rectangle;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationManager;
	import molehill.core.render.particles.ParticleEmitter;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.CustomAnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.ARFTextureData;
	import molehill.core.texture.BRFTextureData;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;

	public class Sprite3DUtils
	{
		private static var _isInited:Boolean = false;
		public static function createFromPrefabBytes(rawData:ByteArray):Sprite3DContainer
		{
			if (!_isInited)
			{
				registerClassAlias("molehill.core.sprite::Sprite3D", Sprite3D);
				registerClassAlias("molehill.core.sprite::Sprite3DContainer", Sprite3DContainer);
				registerClassAlias("molehill.core.sprite::AnimatedSprite3D", AnimatedSprite3D);
				registerClassAlias("molehill.core.sprite::CustomAnimatedSprite3D", CustomAnimatedSprite3D);
				registerClassAlias("molehill.core.render.particles::ParticleEmitter", ParticleEmitter);
				
				_isInited = true;
			}
			
			rawData.position = 0;
			while (rawData.bytesAvailable)
			{
				var header:String = rawData.readUTFBytes(3);
				var chunkSize:int = 0x10000 * rawData.readUnsignedByte() + 0x100 * rawData.readUnsignedByte() + rawData.readUnsignedByte();
				var chunkData:ByteArray = new ByteArray();
				switch (header)
				{
					case 'PRE': // Prefab Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						var rawSpriteData:Array = chunkData.readObject();
						break;
					
					case 'ATF': // Texture Data
					case 'ARF': // Texture Data
					case 'BRF': // Texture Data
						rawData.position -= 6;
						chunkSize = rawData.length - rawData.position;
						chunkData.writeBytes(rawData, rawData.position);
						
						if (header == 'ARF' || header == 'ATF')
						{
							var arfTextureData:ARFTextureData = new ARFTextureData(chunkData);
							if (!TextureManager.getInstance().isARFUploaded(arfTextureData))
							{
								TextureManager.createTexture(arfTextureData);
							}
						}
						else if (header == 'BRF')
						{
							var brfTextureData:BRFTextureData = new BRFTextureData(chunkData);
							if (!TextureManager.getInstance().isBRFUploaded(brfTextureData))
							{
								TextureManager.createTexture(brfTextureData);
							}
						}
						
						break;
				}
				rawData.position += chunkSize;
			}
			
			var parent:Sprite3DContainer = new Sprite3DContainer();
			createSpritesSturcture(rawSpriteData, parent);
			return parent;
		}
	
		public static function createFromRawData(rawData:Array):Sprite3DContainer
		{
			var parent:Sprite3DContainer = new Sprite3DContainer();
			createSpritesSturcture(rawData, parent);
			return parent;
		}
		
		private static function createSpritesSturcture(rawData:Array, parent:Sprite3DContainer):void
		{
			if (rawData == null)
			{
				return;
			}
			
			for (var i:int = 0; i < rawData.length; i++)
			{
				var child:Sprite3D = createSingleSprite(rawData[i].values);
				parent.addChild(child);
				createSpritesSturcture(rawData[i].children, child as Sprite3DContainer);
			}
		}
		
		private static function createSingleSprite(rawData:Object):Sprite3D
		{
			var spriteClass:Class = getDefinitionByName(rawData['class_name']) as Class;
			var sprite:Sprite3D = new spriteClass();
			if (rawData['textureID'] != null)
			{
				sprite.setTexture(rawData['textureID']);
			}
			if (rawData['shader'] == 'color')
			{
				sprite.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, false, Shader3D.TEXTURE_DONT_USE_TEXTURE);
			}
			
			if (rawData['custom_animation'] != null)
			{
				var customAnimation:CustomAnimationData = CustomAnimationData.fromRawData(rawData['custom_animation']);
				(sprite as CustomAnimatedSprite3D).customAnimationData = customAnimation;
				
				(sprite as CustomAnimatedSprite3D).play();
				
				CustomAnimationManager.getInstance().addAnimationData(customAnimation);
			}
			
			delete rawData['class_name'];
			delete rawData['textureID'];
			delete rawData['textureAtlasID'];
			delete rawData['shader'];
			delete rawData['custom_animation'];
			
			for (var field:String in rawData)
			{
				sprite[field] = rawData[field];
			}
			
			return sprite;
		}
		
		/**
		 * Deflates sprite texture region by dX and dY in pixels
		 * Use after setTexture()
		 * width -= 2 * dX;
		 * height -= 2 * dY;
		 * x += dX;
		 * y += dY;
		 */
		public static function deflateSpriteTextureRegion(targetSprite:Sprite3D, dX:int, dY:int):void
		{
			var tm:TextureManager = TextureManager.getInstance();
			
			var textureAtlas:TextureAtlasData = tm.getAtlasDataByTextureID(targetSprite.textureID);
			
			var dW:Number = dX / textureAtlas.width;
			var dH:Number = dY / textureAtlas.height;
			
			var deflatedRect:Rectangle = textureAtlas.getTextureRegion(targetSprite.textureID).clone();
			deflatedRect.inflate(-dW, -dH);
			
			targetSprite.textureRegion = deflatedRect;
		}
	}
}