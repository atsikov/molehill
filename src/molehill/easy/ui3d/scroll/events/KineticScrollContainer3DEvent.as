package molehill.easy.ui3d.scroll.events
{
	import flash.events.Event;
	
	public class KineticScrollContainer3DEvent extends Event
	{
		public static const SCROLL_COMPLETED:String = "scrollCompleted";
		
		public function KineticScrollContainer3DEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}