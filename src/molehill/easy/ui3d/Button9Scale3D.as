package molehill.easy.ui3d
{
	import appbase.model.AppConfig;
	
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.ui.MouseCursor;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.input.InputManager;
	import molehill.core.input.MouseCursorManager;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	public class Button9Scale3D extends Sprite3DContainer
	{
		protected static const STATE_NORMAL:String   = "normal";
		protected static const STATE_OVER:String     = "over";
		protected static const STATE_DOWN:String     = "down";
		protected static const STATE_DISABLED:String = "disabled";
		
		protected var _currentState:String = STATE_NORMAL;
		
		protected var _normalState:Sprite3D9Scale;
		protected var _overState:Sprite3D9Scale;
		protected var _downState:Sprite3D9Scale;
		protected var _disabledState:Sprite3D9Scale;
		
		private static var _soundClick:String;
		public static function set soundClick(value:String):void
		{
			_soundClick = value;
		}
		
		public function Button9Scale3D(
			normalTextureID:String,
			scaleRect:Rectangle,
			scaleMethod:String = "stretch",
			overTextureID:String = null,
			downTextureID:String = null,
			disabledTextureID:String = null
		)
		{
			mouseEnabled = true;
			ignoreTransparentPixels = true;
			
			_normalState = new Sprite3D9Scale(
				normalTextureID,
				scaleRect,
				scaleMethod
			);
			
			_overState = overTextureID == null || overTextureID == normalTextureID ? null :
				new Sprite3D9Scale(
					overTextureID,
					scaleRect,
					scaleMethod
				);
			
			_downState = downTextureID == null || downTextureID == normalTextureID ? null :
				new Sprite3D9Scale(
					downTextureID,
					scaleRect,
					scaleMethod
				);
			
			_disabledState = disabledTextureID == null || disabledTextureID == normalTextureID ? null :
				new Sprite3D9Scale(
					disabledTextureID,
					scaleRect,
					scaleMethod
				);
			
			addChild(_normalState);
			
			addEventListener(Input3DMouseEvent.MOUSE_OVER, onSpriteMouseOver);
			addEventListener(Input3DMouseEvent.MOUSE_OUT, onSpriteMouseOut);
			addEventListener(Input3DMouseEvent.MOUSE_MOVE, onSpriteMouseMove);
			addEventListener(Input3DMouseEvent.MOUSE_DOWN, onSpriteMouseDown);
			addEventListener(Input3DMouseEvent.MOUSE_UP, onSpriteMouseUp);
			addEventListener(Input3DMouseEvent.CLICK, onSpriteClick);
		}
		
		private function onSpriteClick(event:Input3DMouseEvent):void
		{
			if (!_enabled)
			{
				event.stopImmediatePropagation();
			}
			
			if (_soundClick != null && _soundClick != "")
			{
				AppConfig.eventSoundManager.playOnce(
					_soundClick
				);
			}
		}
		
		override public function get width():Number
		{
			var child:Sprite3D = getChildAt(0);
			return child.width;
		}
		
		override public function set width(value:Number):void
		{
			setSize(value, height);
		}
		
		override public function get height():Number
		{
			var child:Sprite3D = getChildAt(0);
			return child.height;
		}
		
		override public function set height(value:Number):void
		{
			setSize(width, value);
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			_normalState.setSize(w, h);
			if (_overState != null)
			{
				_overState.setSize(w, h);
			}
			if (_downState != null)
			{
				_downState.setSize(w, h);
			}
			if (_disabledState != null)
			{
				_disabledState.setSize(w, h);
			}
		}
		
		protected function onSpriteMouseOver(event:Input3DMouseEvent):void
		{
			MouseCursorManager.getInstance().setCursor(MouseCursor.BUTTON);
			
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_OVER;
			updateState();
			
		}
		
		private function onSpriteMouseOut(event:Input3DMouseEvent):void
		{
			MouseCursorManager.getInstance().setCursor(MouseCursor.AUTO);
			
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_NORMAL;
			updateState();
		}
		
		private function onSpriteMouseMove(event:Input3DMouseEvent):void
		{
			
		}
		
		private function onSpriteMouseDown(event:Input3DMouseEvent):void
		{
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_DOWN;
			updateState();
		}
		
		private function onSpriteMouseUp(event:Input3DMouseEvent):void
		{
			isBlinking = false;
			
			_currentState = STATE_OVER;
			updateState();
		}
		
		protected function updateState():void
		{
			var child:Sprite3D = getChildAt(0);
			
			if(_enabled)
			{
				switch (_currentState)
				{
					case STATE_NORMAL:
						if (child !== _normalState)
						{
							removeChild(child);
							addChildAt(_normalState, 0);
						}
						break;
					
					case STATE_OVER:
						if (_overState != null)
						{
							if (child !== _overState)
							{
								removeChild(child);
								addChildAt(_overState, 0);
							}
						}
						else if (child !== _normalState)
						{
							removeChild(child);
							addChildAt(_normalState, 0);
						}
						break;
					
					case STATE_DOWN:
						if (_downState != null)
						{
							if (child !== _downState)
							{
								removeChild(child);
								addChildAt(_downState, 0);
							}
						}
						else if (child !== _normalState)
						{
							removeChild(child);
							addChildAt(_normalState, 0);
						}
						break;
				}
			}
			else
			{
				if (_disabledState != null)
				{
					if (child !== _disabledState)
					{
						removeChild(child);
						addChildAt(_disabledState, 0);
					}
				}
				else if (child !== _normalState)
				{
					removeChild(child);
					addChildAt(_normalState, 0);
				}
			}
		}
		
		protected var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			if (_enabled == value)
			{
				return;
			}
			
			_enabled = value;
			
			if (value)
			{
				_currentState = STATE_NORMAL;
				addEventListener(Input3DMouseEvent.MOUSE_OVER, onSpriteMouseOver);
				addEventListener(Input3DMouseEvent.MOUSE_OUT, onSpriteMouseOut);
				addEventListener(Input3DMouseEvent.MOUSE_DOWN, onSpriteMouseDown);
				addEventListener(Input3DMouseEvent.MOUSE_UP, onSpriteMouseUp);
				addEventListener(Input3DMouseEvent.MOUSE_MOVE, onSpriteMouseMove);
			}
			else
			{
				var stagePoint:Point = new Point(
					InputManager.getInstance().mouseStageX,
					InputManager.getInstance().mouseStageY
				);
				
				var localPoint:Point = stagePoint.clone();
				globalToLocal(localPoint);
				
				dispatchEvent(
					new Input3DMouseEvent(
						Input3DMouseEvent.MOUSE_OUT,
						stagePoint.x, stagePoint.y,
						localPoint.x, localPoint.y,
						this
					)
				);
				
				removeEventListener(Input3DMouseEvent.MOUSE_OVER, onSpriteMouseOver);
				removeEventListener(Input3DMouseEvent.MOUSE_OUT, onSpriteMouseOut);
				removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onSpriteMouseDown);
				removeEventListener(Input3DMouseEvent.MOUSE_UP, onSpriteMouseUp);
				removeEventListener(Input3DMouseEvent.MOUSE_MOVE, onSpriteMouseMove);
			}
			
			updateState();
		}
		
		private var _isBlinking:Boolean = false;
		private var _blinkInterval:int = -1;
		public function set isBlinking(value:Boolean):void
		{
			if (value == _isBlinking)
			{
				return;
			}
			
			_isBlinking = value;
			
			if (_isBlinking)
			{
				_blinkInterval = setInterval(blink, 500);
			}
			else
			{
				clearInterval(_blinkInterval);
			}
		}
		
		private function blink():void
		{
			if (_currentState == STATE_NORMAL)
			{
				_currentState = STATE_OVER;
			}
			else if (_currentState == STATE_OVER)
			{
				_currentState = STATE_NORMAL;
			}
			
			updateState();
		}
	}
}