package molehill.core.input
{
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
		}
		
		private var _cursorCandidate:String = "";
		public function setCursor(cursor:String):void
		{
			if (_cursorCandidate == MouseCursor.BUTTON)
			{
				return;
			}
			
			_cursorCandidate = cursor;
			
			FrameExecutorUtil.getInstance().addNextFrameHandler(doSetCursor);
		}
		
		private function doSetCursor():void
		{
			Mouse.cursor = _cursorCandidate;
			_cursorCandidate = "";
		}
	}
}
