package molehill.core.events
{
	import flash.events.Event;
	
	import molehill.core.molehill_input_internal;
	import molehill.core.sprite.Sprite3D;

	public class Input3DMouseEvent extends Event
	{
		/**
		 * @eventType click
		 **/
		public static const CLICK:String 		= "click";
		
		/**
		 * @eventType mouseUp
		 **/
		public static const MOUSE_UP:String 	= "mouseUp";
		/**
		 * @eventType mouseDown
		 **/
		public static const MOUSE_DOWN:String 	= "mouseDown";
		/**
		 * @eventType mouseMove
		 **/
		public static const MOUSE_MOVE:String 	= "mouseMove";
		
		/**
		 * @eventType mouseOver
		 **/
		public static const MOUSE_OVER:String 	= "mouseOver";
		/**
		 * @eventType mouseOut
		 **/
		public static const MOUSE_OUT:String 	= "mouseOut";
		
		public function Input3DMouseEvent(type:String, stageX:Number, stageY:Number, localX:Number, localY:Number, eventInitiator:Sprite3D)
		{
			_stageX = stageX;
			_stageY = stageY;
			_localX = localX;
			_localY = localY;
			_eventInitiator = eventInitiator;
			
			super(type, true);
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
		
		private var _eventInitiator:Sprite3D;
		public function get eventInitiator():Sprite3D
		{
			return _eventInitiator;
		}
		
		override public function clone():Event
		{
			return new Input3DMouseEvent(type, stageX, stageY, localX, localY, eventInitiator); 
		}
		
	}
}