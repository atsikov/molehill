package molehill.core.events
{
	import flash.events.Event;
	
	public class Sprite3DEvent extends Event
	{
		public function Sprite3DEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		override public function clone():Event
		{
			return this;
		}
	}
}