package model.events
{
	import flash.events.Event;
	
	import molehill.core.animation.CustomAnimationData;
	
	public class AnimationDataEvent extends Event
	{
		public static const FRAMES_CHANGED:String = "framesChanged";
		public static const PROPERTIES_CHANGED:String = "propertiesChanged";
		
		private var _animationData:CustomAnimationData;
		public function AnimationDataEvent(type:String, animationData:CustomAnimationData)
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