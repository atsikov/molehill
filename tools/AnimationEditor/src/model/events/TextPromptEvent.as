package model.events
{
	import flash.events.Event;
	
	public class TextPromptEvent extends Event
	{
		public static const OK:String = "ok";
		public static const CANCEL:String = "cancel";
		
		private var _value:*;
		public function TextPromptEvent(type:String, value:* = null)
		{
			_value = value;
			
			super(type);
		}
		
		public function get value():*
		{
			return _value;
		}
	}
}