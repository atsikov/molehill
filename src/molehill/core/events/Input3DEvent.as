package molehill.core.events
{
	import flash.events.Event;

	public class Input3DEvent extends Event
	{
		public static const CLICK:String 		= "click";
		
		public static const MOUSE_UP:String 	= "mouseUp";
		public static const MOUSE_DOWN:String 	= "mouseDown";
		public static const MOUSE_MOVE:String 	= "mouseMove";
		
		public static const MOUSE_OVER:String 	= "mouseOver";
		public static const MOUSE_OUT:String 	= "mouseOut";
		
		public function Input3DEvent(type:String, stageX:Number, stageY:Number, localX:Number, localY:Number)
		{
			_stageX = stageX;
			_stageY = stageY;
			_localX = localX;
			_localY = localY;
			
			super(type);
		}
		
		private var _stageX:Number;
		public function get stageX():Number
		{
			return _stageX;
		}

		private var _stageY:Number;
		public function get stageY():Number
		{
			return _stageY;
		}

		private var _localX:Number;
		public function get localX():Number
		{
			return _localX;
		}
		
		private var _localY:Number;
		public function get localY():Number
		{
			return _localY;
		}
		
	}
}