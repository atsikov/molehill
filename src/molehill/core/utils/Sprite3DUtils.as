package molehill.core.utils
{
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationManager;
	import molehill.core.sprite.CustomAnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.ARFTextureData;
	import molehill.core.texture.BRFTextureData;
	import molehill.core.texture.TextureManager;

	public class Sprite3DUtils
	{
		public static function createFromPrefabBytes(rawData:ByteArray):Sprite3DContainer
		{
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
			sprite.setTexture(rawData['textureID']);
			delete rawData['textureID'];
			delete rawData['class_name'];
			
			if (rawData['custom_animation'] != null)
			{
				var customAnimation:CustomAnimationData = CustomAnimationData.fromRawData(rawData['custom_animation']);
				(sprite as CustomAnimatedSprite3D).customAnimationData = customAnimation;
				delete rawData['custom_animation'];
				
				(sprite as CustomAnimatedSprite3D).play();
				
				CustomAnimationManager.getInstance().addAnimationData(customAnimation);
			}
			
			for (var field:String in rawData)
			{
				sprite[field] = rawData[field];
			}
			
			return sprite;
		}
	}
}