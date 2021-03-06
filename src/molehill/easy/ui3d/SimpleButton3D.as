package molehill.easy.ui3d
{
	import flash.geom.Point;
	import flash.ui.MouseCursor;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.input.InputManager;
	import molehill.core.input.MouseCursorManager;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	public class SimpleButton3D extends InteractiveSprite3D
	{
		protected static const STATE_NORMAL:String   = "normal";
		protected static const STATE_OVER:String     = "over";
		protected static const STATE_DOWN:String     = "down";
		protected static const STATE_DISABLED:String = "disabled";
		
		protected var _currentState:String = STATE_NORMAL;
		
		protected var _normalTextureData:TextureData;
		protected var _overTextureData:TextureData;
		protected var _downTextureData:TextureData;
		protected var _disabledTextureData:TextureData;
		
		private static var _defaultSoundClick:String;
		public static function set defaultSoundClick(value:String):void
		{
			_defaultSoundClick = value;
		}
		
		private static var _playSoundCallback:Function;
		/**
		 * need to accept sound id as string parameter
		 */
		public static function set playSoundCallback(value:Function):void
		{
			_playSoundCallback = value;
		}

		
		public function SimpleButton3D(
			normalTextureID:String,
			overTextureID:String = null,
			downTextureID:String = null,
			disabledTextureID:String = null
		)
		{
			var tm:TextureManager = TextureManager.getInstance();
			
			mouseEnabled = true;
			ignoreTransparentPixels = true;
			
			_normalTextureData = tm.getTextureDataByID(normalTextureID);
			_overTextureData = overTextureID != null ? tm.getTextureDataByID(overTextureID) : _normalTextureData;
			_downTextureData = downTextureID != null ? tm.getTextureDataByID(downTextureID) : _normalTextureData;
			_disabledTextureData = tm.getTextureDataByID(disabledTextureID);
			
			setTexture(_normalTextureData.textureID);
			setSize(_normalTextureData.width, _normalTextureData.height);
			
			addEventListener(Input3DMouseEvent.MOUSE_OVER, onSpriteMouseOver);
			addEventListener(Input3DMouseEvent.MOUSE_OUT, onSpriteMouseOut);
			addEventListener(Input3DMouseEvent.MOUSE_MOVE, onSpriteMouseMove);
			addEventListener(Input3DMouseEvent.MOUSE_DOWN, onSpriteMouseDown);
			addEventListener(Input3DMouseEvent.MOUSE_UP, onSpriteMouseUp);
			addEventListener(Input3DMouseEvent.CLICK, onSpriteClick);
		}
		
		private var _soundClick:String;
		public function set soundClick(value:String):void
		{
			_soundClick = value;
		}

		private function onSpriteClick(event:Input3DMouseEvent):void
		{
			if (!_enabled)
			{
				event.stopImmediatePropagation();
			}
			
			var soundClick:String = _soundClick == null ? _defaultSoundClick : _soundClick;
			
			if (_playSoundCallback != null && soundClick != null && soundClick != "")
			{
				_playSoundCallback(_defaultSoundClick);
			}
		}
		
		private function onSpriteMouseOver(event:Input3DMouseEvent):void
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
			var tm:TextureManager = TextureManager.getInstance();
			
			if(_enabled)
			{
				switch (_currentState)
				{
					case STATE_NORMAL:
						if (textureID != _normalTextureData.textureID)
						{
							setTexture(_normalTextureData.textureID);
						}
						break;
					
					case STATE_OVER:
						if (textureID != _overTextureData.textureID)
						{
							setTexture(_overTextureData.textureID);
						}
						break;
					
					case STATE_DOWN:
						if (textureID != _downTextureData.textureID)
						{
							setTexture(_downTextureData.textureID);
						}
						break;
				}
			}
			else
			{
				if (_disabledTextureData != null)
				{
					if (textureID != _disabledTextureData.textureID)
					{
						setTexture(_disabledTextureData.textureID);
					}
				}
				else
				{
					if (textureID != _normalTextureData.textureID)
					{
						setTexture(_normalTextureData.textureID);
					}
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