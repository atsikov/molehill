package molehill.easy.events
{
	public class EasyEvent
	{
		private var _type:String;
		private var _bubbles:Boolean = false;
		private var _cancelable:Boolean = false;
		public function EasyEvent(type:String, bubbles:Boolean=true, cancelable:Boolean=false)
		{
			_type = type;
			_bubbles = bubbles;
			_cancelable = cancelable;
		}
		
		/**
		 * Public methods
		 **/
		private var _defaultBehaviorPrevented:Boolean = false;
		public function preventDefault():void
		{
			if (!_cancelable)
			{
				return;
			}
			
			_defaultBehaviorPrevented = true;
		}
		
		public function isDefaultPrevented():void
		{
			
		}
		
		public function stopPropagation():void
		{
			
		}
		
		public function stopImmediatePropagation():void
		{
			
		}
		
		/**
		 * Internal methods
		 **/
	}
}