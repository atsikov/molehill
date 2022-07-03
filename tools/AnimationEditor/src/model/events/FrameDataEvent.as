package model.events
{
	import flash.events.Event;
	
	import molehill.core.animation.CustomAnimationFrameData;
	
	public class FrameDataEvent extends Event
	{
		public static const REPEAT_COUNT_CHANGED:String = "repeatCountChanged";
		public static const TEXTURE_CHANGED:String = "textureChanged";
		
		private var _frameData:CustomAnimationFrameData;
		public function FrameDataEvent(type:String, frameData:CustomAnimationFrameData)
		{
			_frameData = frameData;
			super(type);
		}
		
		override public function clone():Event
		{
			return new FrameDataEvent(type, _frameData);
		}
		
		public function get frameData():CustomAnimationFrameData
		{
			return _frameData;
		}
	}
}