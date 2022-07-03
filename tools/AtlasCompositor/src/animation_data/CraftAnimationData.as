package animation_data
{
	import molehill.core.sprite.SpriteAnimationData;
	import molehill.core.texture.SpriteSheetData;

	public class CraftAnimationData
	{
		public static const MASK_POSITION:String = 'maskPosition';
		public static const ANIMATION_DATA:String = 'animationData';
		public static const SPRITE_SHEET_DATA:String = 'spriteSheetData';
		public static const ANIMATION_X:String = 'animationX';
		public static const ANIMATION_Y:String = 'animationY';
		
		public function CraftAnimationData()
		{
		}
		
		private var _hashPropellerAnimations:Object;
		private var _hashSmokeAnimations:Array;
		public function get hashPropellerAnimations():Object
		{
			return _hashPropellerAnimations;
		}
		
		public function addPropellerAnimation(animationData:SpriteAnimationData, spriteSheetData:SpriteSheetData, propX:Number, propY:Number):void
		{
			if (_hashPropellerAnimations == null)
			{
				_hashPropellerAnimations = {};
			}
			
			if (_hashPropellerAnimations[animationData.animationName] != null)
			{
				return;
			}
			
			_hashPropellerAnimations[animationData.animationName] = {};
			_hashPropellerAnimations[animationData.animationName][ANIMATION_DATA] = animationData;
			_hashPropellerAnimations[animationData.animationName][SPRITE_SHEET_DATA] = spriteSheetData;
			_hashPropellerAnimations[animationData.animationName][ANIMATION_X] = propX;
			_hashPropellerAnimations[animationData.animationName][ANIMATION_Y] = propY;
		}
		
		public function getPropellerAnimation(animationName:String):Object
		{
			if (_hashPropellerAnimations == null)
			{
				_hashPropellerAnimations = {};
			}

			return _hashPropellerAnimations[animationName];
		}
		
		public function addSmokeAnimation(animationData:SpriteAnimationData, spriteSheetData:SpriteSheetData, animX:Number, animY:Number):void
		{
			if (_hashSmokeAnimations == null)
			{
				_hashSmokeAnimations = [];
			}
			
			var dataObject:Object = {};
			dataObject[ANIMATION_DATA] = animationData;
			dataObject[SPRITE_SHEET_DATA] = spriteSheetData;
			dataObject[ANIMATION_X] = animX;
			dataObject[ANIMATION_Y] = animY;
			
			
			_hashSmokeAnimations.push(dataObject);
		}
		
		public function getSmokeAnimation():Array
		{
			return _hashSmokeAnimations;
		}
	}
}