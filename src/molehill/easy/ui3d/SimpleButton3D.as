package molehill.easy.ui3d
{
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.clearInterval;
	import flash.utils.setInterval;
	
	import molehill.core.events.Input3DEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Sprite3D;
	import molehill.core.render.Sprite3DContainer;
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
			
			textureID = _normalTextureData.textureID;
			textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
			setSize(_normalTextureData.width, _normalTextureData.height);
			
			addEventListener(Input3DEvent.MOUSE_OVER, onSpriteMouseOver);
			addEventListener(Input3DEvent.MOUSE_OUT, onSpriteMouseOut);
			addEventListener(Input3DEvent.MOUSE_MOVE, onSpriteMouseMove);
			addEventListener(Input3DEvent.MOUSE_DOWN, onSpriteMouseDown);
			addEventListener(Input3DEvent.MOUSE_UP, onSpriteMouseUp);
		}
		
		protected function onSpriteMouseOver(event:Input3DEvent):void
		{
			Mouse.cursor = MouseCursor.BUTTON;
			
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_OVER;
			updateState();
			
		}
		
		private function onSpriteMouseOut(event:Input3DEvent):void
		{
			Mouse.cursor = MouseCursor.AUTO;
			
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_NORMAL;
			updateState();
		}
		
		private function onSpriteMouseMove(event:Input3DEvent):void
		{
			
		}
		
		private function onSpriteMouseDown(event:Input3DEvent):void
		{
			if (_isBlinking)
			{
				return;
			}
			
			_currentState = STATE_DOWN;
			updateState();
		}
		
		private function onSpriteMouseUp(event:Input3DEvent):void
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
							textureID = _normalTextureData.textureID;
							textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
							setSize(_normalTextureData.width, _normalTextureData.height);
						}
						break;
					
					case STATE_OVER:
						if (textureID != _overTextureData.textureID)
						{
							textureID = _overTextureData.textureID;
							textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
							setSize(_overTextureData.width, _overTextureData.height);
						}
						break;
					
					case STATE_DOWN:
						if (textureID != _downTextureData.textureID)
						{
							textureID = _downTextureData.textureID;
							textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
							setSize(_downTextureData.width, _downTextureData.height);
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
						textureID = _disabledTextureData.textureID;
						textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
						setSize(_disabledTextureData.width, _disabledTextureData.height);
					}
				}
				else
				{
					if (textureID != _normalTextureData.textureID)
					{
						textureID = _normalTextureData.textureID;
						textureRegion = tm.getTextureRegion(_normalTextureData.textureID);
						setSize(_normalTextureData.width, _normalTextureData.height);
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
				addEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
				addEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
				addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			}
			else
			{
				removeEventListener(MouseEvent.MOUSE_OVER, onMouseOver);
				removeEventListener(MouseEvent.MOUSE_OUT, onMouseOut);
				removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
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