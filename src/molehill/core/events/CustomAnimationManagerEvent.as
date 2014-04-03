package molehill.core.events
{
	import flash.events.Event;
	
	public class CustomAnimationManagerEvent extends Event
	{
		/**
		 * @eventType animationsAdded
		 **/
		public static const ANIMATIONS_ADDED:String = "animationsAdded";
		public function CustomAnimationManagerEvent(type:String)
		{
			super(type);
		}
	}
}