package molehill.easy.prefabs
{
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
	import molehill.core.texture.TextureManager;

	public class SpritePrefabData
	{
		private static var _isInited:Boolean = false;
		private var _rawData:ByteArray;
		private var _rawContentData:Array;
		private var _textureData:*;
		public function SpritePrefabData(rawData:ByteArray)
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
						_rawContentData = chunkData.readObject();
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
							TextureManager.createTexture(arfTextureData);
							_textureData = arfTextureData;
						}
						else if (header == 'BRF')
						{
							var brfTextureData:BRFTextureData = new BRFTextureData(chunkData);
							TextureManager.createTexture(brfTextureData);
							_textureData = brfTextureData;
						}
						
						break;
				}
				rawData.position += chunkSize;
			}
		}
		
		private function createSpritesSturcture(rawData:Array, parent:Sprite3DContainer):void
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

		private function createSingleSprite(rawData:Object):Sprite3D
		{
			var spriteClass:Class = getDefinitionByName(rawData['class_name']) as Class;
			var sprite:Sprite3D = new spriteClass();
			if (rawData['textureID'] != null)
			{
				sprite.setTexture(rawData['textureID']);
			}
			if (rawData['shader'] == 'color')
			{
				sprite.shader = Shader3DFactory.getInstance().getShaderInstance(null, false, Shader3D.TEXTURE_DONT_USE_TEXTURE);
			}
			
			if (rawData['custom_animation'] != null)
			{
				var customAnimation:CustomAnimationData = CustomAnimationData.fromRawData(rawData['custom_animation']);
				(sprite as CustomAnimatedSprite3D).customAnimationData = customAnimation;
				
				(sprite as CustomAnimatedSprite3D).play();
				
				CustomAnimationManager.getInstance().addAnimationData(customAnimation);
			}
			
			for (var field:String in rawData)
			{
				switch (field)
				{
					case 'class_name':
					case 'textureID':
					case 'textureAtlasID':
					case 'shader':
					case 'custom_animation':
						break;
					
					default:
						sprite[field] = rawData[field];
				}
			}
			
			return sprite;
		}
		
		public function newInstance():Sprite3DContainer
		{
			var parent:Sprite3DContainer = new Sprite3DContainer();
			createSpritesSturcture(_rawContentData, parent);
			return parent;
		}

		public function get textureData():*
		{
			return _textureData;
		}
	}
}