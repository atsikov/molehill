package molehill.core.events
{
	import flash.events.Event;

	public class Sprite3DContainerEvent extends Event
	{
		public static const CHILD_ADDED:String = "childAdded";
		
		public function Sprite3DContainerEvent(type:String)
		{
			super(type);
		}
	}
}