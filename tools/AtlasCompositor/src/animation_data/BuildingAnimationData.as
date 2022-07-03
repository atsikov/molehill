package animation_data
{
	import flash.geom.Point;
	
	import molehill.core.animation.SpriteAnimationData;

	public class BuildingAnimationData
	{
		public static const MASK_POSITION:String = 'maskPosition';
		public static const ANIMATION_DATA:String = 'animationData';
		public static const TEXTURE_ID:String = 'textureID';
		
		private var _hashPeopleAnimations:Object;
		public function BuildingAnimationData()
		{
		}
		
		public function get hashPeopleAnimations():Object
		{
			return _hashPeopleAnimations;
		}
		
		public function addPeopleAnimation(animationData:SpriteAnimationData, textureID:String):void
		{
			if (_hashPeopleAnimations == null)
			{
				_hashPeopleAnimations = {};
			}
			
			if (_hashPeopleAnimations[animationData.animationName] != null)
			{
				return;
			}
			
			_hashPeopleAnimations[animationData.animationName] = {};
			_hashPeopleAnimations[animationData.animationName][ANIMATION_DATA] = animationData;
			_hashPeopleAnimations[animationData.animationName][TEXTURE_ID] = textureID;
		}
		
		private var _shineAnimationData:Object;
		public function get shineAnimationData():Object
		{
			return _shineAnimationData;
		}
		
		public function addShineAnimationData(maskPosition:Point, lightAnimationData:SpriteAnimationData):void
		{
			_shineAnimationData = {};
			_shineAnimationData[MASK_POSITION] = maskPosition;
			_shineAnimationData[ANIMATION_DATA] = lightAnimationData;
		}
		
		private var _hashTechnicalAnimation:Array;
		public function get hashTechnicalAnimation():Array
		{
			if (_hashTechnicalAnimation == null)
			{
				_hashTechnicalAnimation = [];
			}
			
			return _hashTechnicalAnimation;
		}
		
		public function addTechincalAnimation(animationData:SpriteAnimationData, textureID:String):void
		{
			if (_hashTechnicalAnimation == null)
			{
				_hashTechnicalAnimation = [];
			}
			
			if (getTechnicalAnimation(animationData.animationName) != null)
			{
				return;
			}
			
			var animationObject:Object = {};
			animationObject[ANIMATION_DATA] = animationData;
			animationObject[TEXTURE_ID] = textureID;
			
			_hashTechnicalAnimation.push(
				{
					'id': animationData.animationName,
					'data': animationObject
				}
			);
		}
		
		private function getTechnicalAnimation(animID:String):Object
		{
			for (var i:int = 0; i < _hashTechnicalAnimation.length; i++)
			{
				if (_hashTechnicalAnimation[i].id == animID)	
				{
					return _hashTechnicalAnimation[i];
				}
			}
			
			return null;
		}
		
		private var _technicalAnimationX:Number = 0;
		private var _technicalAnimationY:Number = 0;
		public function get technicalAnimationX():Number
		{
			return _technicalAnimationX;
		}
		
		public function set technicalAnimationX(value:Number):void
		{
			_technicalAnimationX = value;
		}
		
		public function get technicalAnimationY():Number
		{
			return _technicalAnimationY;
		}
		
		public function set technicalAnimationY(value:Number):void
		{
			_technicalAnimationY = value;
		}
		
	}
}