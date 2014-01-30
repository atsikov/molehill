package molehill.core.sort
{
	import flash.events.Event;
	
	public class ZSortEvent extends Event
	{
		public static const MOVE:String = 'ZSortMove';
		
		public function ZSortEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}