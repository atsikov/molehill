package molehill.core.render
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import molehill.core.events.Input3DEvent;
	import molehill.core.input.InputManager;
	import molehill.core.molehill_internal;
	import molehill.core.texture.NormalizedAlphaChannel;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	import molehill.core.sprite.Sprite3D;
	
	use namespace molehill_internal;

	public class InteractiveSprite3D extends Sprite3D
	{
		public function InteractiveSprite3D()
		{
			super();
		}
		
		private var _ignoreTransparentPixels:Boolean = false;
		public function get ignoreTransparentPixels():Boolean
		{
			return _ignoreTransparentPixels;
		}
		
		override protected function onAddedToScene():void
		{
			super.onAddedToScene();
			
			//InputManager.getInstance().sortListeners();
		}
		
		/**
		 * If set to true, mouse won't be detected over transparent pixels 
		 **/
		public function set ignoreTransparentPixels(value:Boolean):void
		{
			_ignoreTransparentPixels = value;
		}
		
		private function isPixelTransparent(localX:int, localY:int):Boolean
		{
			localX -= _parentShiftX + _shiftX;
			localY -= _parentShiftY + _shiftY;
			
			var textureData:TextureData = TextureManager.getInstance().getTextureDataByID(textureID);
			var alphaData:NormalizedAlphaChannel = textureData.getNormalizedAlpha();
			
			if (alphaData == null)
			{
				return false;
			}
			
			return !alphaData.hitTestPoint(localX, localY);
		}
		
		public function onMouseDown(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			if (_ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.MOUSE_DOWN,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		public function onMouseUp(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			if (_ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.MOUSE_UP,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		public function onMouseClick(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			if (_ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.CLICK,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		public function onMouseMove(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			if (_ignoreTransparentPixels)
			{
				if (isPixelTransparent(localX, localY))
				{
					if (_mouseIsOver)
					{
						onMouseOut(stageX, stageY, localX, localY);
					}
					return false;
				}
				else
				{
					if (!_mouseIsOver)
					{
						onMouseOver(stageX, stageY, localX, localY);
					}
				}
			}
			
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.MOUSE_MOVE,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		public function onMouseOut(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			_mouseIsOver = false;
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.MOUSE_OUT,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		private var _mouseIsOver:Boolean = false;
		public function onMouseOver(stageX:int, stageY:int, localX:int, localY:int):Boolean
		{
			if (_ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				if (_mouseIsOver)
				{
					onMouseOut(stageX, stageY, localX, localY);
				}
				return false;
			}
			
			_mouseIsOver = true;
			dispatchEvent(
				new Input3DEvent(
					Input3DEvent.MOUSE_OVER,
					stageX,
					stageY,
					localX,
					localY
				)
			);
			
			return true;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			switch (type)
			{
				case Input3DEvent.CLICK:
				case Input3DEvent.MOUSE_DOWN:
				case Input3DEvent.MOUSE_MOVE:
				case Input3DEvent.MOUSE_OUT:
				case Input3DEvent.MOUSE_OVER:
				case Input3DEvent.MOUSE_UP:
					InputManager.getInstance().registerSprite(type, this);
					break;
			}
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			super.removeEventListener(type, listener, useCapture);
			
			InputManager.getInstance().unregisterSprite(type, this);
		}
	}
}