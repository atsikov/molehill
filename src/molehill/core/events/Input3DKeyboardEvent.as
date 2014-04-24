package molehill.core.events
{
	import flash.events.KeyboardEvent;
	
	public class Input3DKeyboardEvent extends KeyboardEvent
	{
		public static const KEY_DOWN:String = "keyDown";
		public static const KEY_UP:String 	= "keyUp";
		
		public function Input3DKeyboardEvent(type:String, charCodeValue:uint, keyCodeValue:uint, keyLocationValue:uint, ctrlKeyValue:Boolean, altKeyValue:Boolean, shiftKeyValue:Boolean)
		{
			super(type, false, false, charCodeValue, keyCodeValue, keyLocationValue, ctrlKeyValue, altKeyValue, shiftKeyValue);
		}
	}
}