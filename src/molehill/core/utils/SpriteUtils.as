package molehill.core.utils
{
	import flash.utils.getDefinitionByName;
	
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.CustomAnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	import spark.effects.Animate;

	public class SpriteUtils
	{
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
				
				if (child is AnimatedSprite3D)
				{
					(child as AnimatedSprite3D).play();
				}
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
			}
			
			for (var field:String in rawData)
			{
				sprite[field] = rawData[field];
			}
			
			return sprite;
		}
	}
}