package molehill.core.input
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	
	import utils.FrameExecutorUtil;

	public class MouseCursorManager
	{
		private static var _instance:MouseCursorManager
		public static function getInstance():MouseCursorManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new MouseCursorManager();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function MouseCursorManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use MouseCursorManager::getInstance()");
			}
			
			_eventDispatcher = new Sprite();
		}
		
		private var _eventDispatcher:Sprite;
		private var _cursorCandidate:String = "";
		private var _currentCursor:String = "";
		public function setCursor(cursor:String):void
		{
			if (_cursorCandidate == MouseCursor.BUTTON)
			{
				return;
			}
			
			_cursorCandidate = cursor;
			
			_eventDispatcher.addEventListener(Event.EXIT_FRAME, onExitFrame);
		}
		
		protected function onExitFrame(event:Event):void
		{
			doSetCursor();
			
			_eventDispatcher.removeEventListener(Event.EXIT_FRAME, onExitFrame);
		}
		
		private function doSetCursor():void
		{
			if (_currentCursor != _cursorCandidate)
			{
				try
				{
					Mouse.cursor = _cursorCandidate;
					_currentCursor = _cursorCandidate;
				}
				catch (e:Error)
				{
					//nothing
				}
			}
			
			_cursorCandidate = "";
		}
	}
}
