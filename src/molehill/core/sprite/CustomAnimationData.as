package molehill.core.sprite
{
	public class CustomAnimationData
	{
		public static function fromRawData(rawData:Object):CustomAnimationData
		{
			var animationData:CustomAnimationData = new CustomAnimationData(rawData['animationName']);
			animationData.frameRate = rawData['frameRate'];
			animationData.playMode = rawData['playMode'];
			
			for (var i:int = 0; i < rawData['listFrames'].length; i++)
			{
				var rawFrameData:Object = rawData['listFrames'][i];
				animationData.listFrames.push(rawFrameData['textureName'], rawFrameData['repeatCount']);
			}
			
			return animationData;
		}
		
		private var _animationName:String;
		public function CustomAnimationData(animationName:String)
		{
			_animationName = animationName;
			_listFrames = new Vector.<CustomAnimationFrameData>();
		}
		
		public function get animationName():String
		{
			return _animationName;
		}
		
		public function set animationName(value:String):void
		{
			if (_animationName == value)
			{
				return;
			}
			
			_animationName = value;
		}
		
		private var _playMode:String = AnimationPlayMode.LOOP;
		public function get playMode():String
		{
			return _playMode;
		}
		
		public function set playMode(value:String):void
		{
			if (_playMode == value)
			{
				return;
			}
			
			_playMode = value;
		}
		
		private var _frameRate:Number = 1;
		public function get frameRate():Number
		{
			return _frameRate;
		}
		
		public function set frameRate(value:Number):void
		{
			if (_frameRate == value)
			{
				return;
			}
			
			_frameRate = value;
		}
		
		public function get frameTime():Number
		{
			return 1 / _frameRate;
		}
		
		public function get totalFrames():int
		{
			var totalFrames:int = 0;
			for (var i:int = 0; i < _listFrames.length; i++)
			{
				totalFrames += _listFrames[i].repeatCount;
			}
			
			return totalFrames;
		}
		
		public function get animationDuration():Number
		{
			return frameTime * totalFrames;
		}
		
		private var _listFrames:Vector.<CustomAnimationFrameData>;
		public function get listFrames():Vector.<CustomAnimationFrameData>
		{
			return _listFrames;
		}
	}
}