package molehill.core.animation
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import molehill.core.sprite.SpriteData;

	public class SpriteAnimationData
	{
		public static function fromRawData(rawData:Object):SpriteAnimationData
		{
			var spriteAnimationData:SpriteAnimationData = new SpriteAnimationData(null, null);
			spriteAnimationData._animationName = rawData['animationName'];
			spriteAnimationData._frameRate = int(rawData['frameRate']);
			spriteAnimationData._listStates = new Vector.<SpriteData>();
			for (var i:int = 0; i < rawData['listStates'].length; i++)
			{
				spriteAnimationData._listStates.push(SpriteData.fromRawData(rawData['listStates'][i]));
			}
			return spriteAnimationData;
		}
		
		private var _listStates:Vector.<SpriteData>;
		private var _animationName:String;
		public function SpriteAnimationData(animation:MovieClip, child:DisplayObject)
		{
			if (animation == null)
			{
				return;
			}
			
			_listStates = new Vector.<SpriteData>();
			var index:int = animation.getChildIndex(child);
			_animationName = child.name;
			if (child is Shape)
			{
				_animationName = "";
			}
			for (var i:int = 1; i < animation.totalFrames + 1; i++)
			{
				animation.gotoAndStop(i);
				
				if (_animationName == "" || _animationName == null)
				{
					if (animation.numChildren <= index)
					{
						_listStates.push(null);
						continue;
					}
					
					_listStates.push(
						new SpriteData(
							animation.getChildAt(index)
						)
					);
				}
				else
				{
					var childByName:DisplayObject = animation.getChildByName(_animationName);
					if (childByName != null)
					{
						_listStates.push(
							new SpriteData(childByName)
						);
					}
					else
					{
						_listStates.push(null);
					}
					
				}
			}
			
			animation.gotoAndStop(1);
		}
		
		private var _frameRate:int = 0;
		public function get frameRate():int
		{
			return _frameRate;
		}
		
		public function get totalFrames():uint
		{
			return _listStates.length;
		}
		
		public function get animationName():String
		{
			return _animationName;
		}
		
		public function set animationName(value:String):void
		{
			_animationName = value;
		}
		
		public function getFrameState(index:int):SpriteData
		{
			if (index < 0)
			{
				index = 0;
			}
			
			if (index >= totalFrames)
			{
				index = totalFrames - 1;
			}
			
			return _listStates[index];
		}
		
		public function get listStates():Array
		{
			var rawArray:Array = [];
			for (var i:int = 0; i < _listStates.length; i++)
			{
				if (_listStates[i] != null)
				{
					rawArray.push(
						_listStates[i].getRawData()
					);
				}
				else
				{
					rawArray.push(null);
				}
			}
			
			return rawArray;
		}

	}
}