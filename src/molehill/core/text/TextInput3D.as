package molehill.core.text
{
	import flash.ui.Keyboard;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import molehill.core.events.Input3DKeyboardEvent;
	import molehill.core.focus.IFocusable;
	import molehill.core.input.InputManager;

	public class TextInput3D extends TextField3D implements IFocusable
	{
		private static const AUTO_REPEAT_START_TIMEOUT:uint = 500;
		private static const AUTO_REPEAT_NEXT_INTERVAL:uint = 50;
		
		public function TextInput3D()
		{
			super();
		}
		
		private var _currentKeyCode:uint = 0;
		private var _currentChar:uint;
		private var _currentUpperCaseChar:uint;
		private var _currentShiftState:Boolean = false;
		private var _lastShiftStatus:Boolean = false;
		private var _lastCapsLockStatus:Boolean = false;
		private var _autoRepeatStartTimeout:uint;
		private var _autoRepeatNextInterval:uint;
		public function onFocusReceived():void
		{
			InputManager.getInstance().addEventListener(
				Input3DKeyboardEvent.KEY_DOWN, onKeyDown
			);
			InputManager.getInstance().addEventListener(
				Input3DKeyboardEvent.KEY_UP, onKeyUp
			);
		}
		
		public function onFocusLost():void
		{
			InputManager.getInstance().removeEventListener(
				Input3DKeyboardEvent.KEY_DOWN, onKeyDown
			);
			InputManager.getInstance().removeEventListener(
				Input3DKeyboardEvent.KEY_UP, onKeyUp
			);
		}
		
		private var _cursorLine:uint = 0;
		private var _cursorCol:uint = 0;
		private function onKeyDown(event:Input3DKeyboardEvent):void
		{
			_currentKeyCode = event.keyCode;
			switch (event.keyCode)
			{
				case Keyboard.ALTERNATE:
				case Keyboard.AUDIO:
				case Keyboard.BLUE:
				case Keyboard.BACK:
				case Keyboard.CAPS_LOCK:
				case Keyboard.CHANNEL_DOWN:
				case Keyboard.CHANNEL_UP:
				case Keyboard.COMMAND:
				case Keyboard.CONTROL:
				case Keyboard.DVR:
				case Keyboard.ESCAPE:
				case Keyboard.EXIT:
				case Keyboard.F1:
				case Keyboard.F2:
				case Keyboard.F3:
				case Keyboard.F4:
				case Keyboard.F5:
				case Keyboard.F6:
				case Keyboard.F7:
				case Keyboard.F8:
				case Keyboard.F9:
				case Keyboard.F10:
				case Keyboard.F11:
				case Keyboard.F12:
				case Keyboard.F13:
				case Keyboard.F14:
				case Keyboard.F15:
				case Keyboard.FAST_FORWARD:
				case Keyboard.GREEN:
				case Keyboard.GUIDE:
				case Keyboard.HELP:
				case Keyboard.INFO:
				case Keyboard.INPUT:
				case Keyboard.INSERT:
				case Keyboard.LAST:
				case Keyboard.LIVE:
				case Keyboard.MASTER_SHELL:
				case Keyboard.MENU:
				case Keyboard.NEXT:
				case Keyboard.NUMPAD:
				case Keyboard.PAUSE:
				case Keyboard.PLAY:
				case Keyboard.PAGE_DOWN:
				case Keyboard.PAGE_UP:
				case Keyboard.PREVIOUS:
				case Keyboard.RECORD:
				case Keyboard.RED:
				case Keyboard.REWIND:
				case Keyboard.SEARCH:
				case Keyboard.SETUP:
				case Keyboard.SKIP_BACKWARD:
				case Keyboard.SKIP_FORWARD:
				case Keyboard.STOP:
				case Keyboard.SUBTITLE:
				case Keyboard.TAB:
				case Keyboard.VOD:
				case Keyboard.YELLOW:
					return;
			}
			
			_currentShiftState = event.shiftKey;
			_lastCapsLockStatus = Keyboard.capsLock;
			
			var char:String = String.fromCharCode(event.charCode);
			_currentChar = event.charCode;
			
			var upperCaseChar:String = char.toLocaleUpperCase()
			if (char == upperCaseChar)
			{
				upperCaseChar = char.toLocaleLowerCase();
			}
			_currentUpperCaseChar = upperCaseChar.charCodeAt(0);
			
			_lastShiftStatus = event.shiftKey;
			addChar();
			
			clearTimeout(_autoRepeatStartTimeout);
			clearInterval(_autoRepeatNextInterval);
			
			_autoRepeatStartTimeout = setTimeout(runAutoRepeat, AUTO_REPEAT_START_TIMEOUT)
		}
		
		private function onKeyUp(event:Input3DKeyboardEvent):void
		{
			clearTimeout(_autoRepeatStartTimeout);
			clearInterval(_autoRepeatNextInterval);
			
			_currentChar = 0;
			_currentUpperCaseChar = 0;
			_currentKeyCode = 0;
			
			_currentShiftState = false;
			_lastShiftStatus = false;
			_lastCapsLockStatus = false;
		}
		
		private var _restrict:String = null;
		public function get restrict():String
		{
			return _restrict;
		}
		
		public function set restrict(value:String):void
		{
			_restrict = value;
		}
		
		private var _maxLength:uint = uint.MAX_VALUE;
		public function get maxLength():uint
		{
			return _maxLength;
		}
		
		public function set maxLength(value:uint):void
		{
			_maxLength = value;
		}
		
		private function addChar():void
		{
			switch (_currentKeyCode)
			{
				case Keyboard.BACKSPACE:
					if (text.length > 0)
					{
						text = text.substr(0, text.length - 1);
						if (_cursorCol == 0)
						{
							if (_cursorLine > 0)
							{
								_cursorLine--;
								_cursorCol = _hashSymbolsByLine[_cursorLine];
							}
						}
						else
						{
							_cursorCol--;
						}
					}
					break;
				
				default:
					if (text.length == _maxLength)
					{
						return;
					}
					
					var newChar:String = _lastCapsLockStatus == Keyboard.capsLock && _lastShiftStatus == _currentShiftState ? String.fromCharCode(_currentChar) : String.fromCharCode(_currentUpperCaseChar);
					if (_restrict != null && _restrict.indexOf(newChar) == -1)
					{
						return;
					}
					
					appendText(newChar);
					
					if (_currentKeyCode == Keyboard.ENTER)
					{
						_cursorLine++;
						_cursorCol = 0;
					}
					else
					{
						_cursorCol++;
					}
					
			}
		}
		
		private function runAutoRepeat():void
		{
			addChar();
			_autoRepeatNextInterval = setInterval(addChar, AUTO_REPEAT_NEXT_INTERVAL);
		}
	}
}