package model.events
{
	import flash.events.Event;
	
	import molehill.core.animation.CustomAnimationData;
	
	public class ModelEvent extends Event
	{
		public static const ANIMATION_ADDED:String = "animationAdded";
		public static const ANIMATION_REMOVED:String = "animationRemoved";
		
		public static const ACTIVE_ANIMATION_CHANGED:String = "activeAnimationChanged";
		public static const ACTIVE_FRAME_CHANGED:String = "activeFrameChanged";
		
		public static const TEXTURES_UPDATED:String = "texturesUpdated";
		
		private var _animationData:CustomAnimationData;
		public function ModelEvent(type:String, animationData:CustomAnimationData)
		{
			_animationData = animationData;
			
			super(type);
		}
		
		public function get animationData():CustomAnimationData
		{
			return _animationData;
		}
	}
}