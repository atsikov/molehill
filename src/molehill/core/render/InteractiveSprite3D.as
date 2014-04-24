package molehill.core.render
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.input.InputManager;
	import molehill.core.molehill_input_internal;
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.texture.NormalizedAlphaChannel;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;
	use namespace molehill_input_internal;

	public class InteractiveSprite3D extends Sprite3D
	{
		public function InteractiveSprite3D()
		{
			super();
		}
		
		override protected function onAddedToScene():void
		{
			super.onAddedToScene();
			
			//InputManager.getInstance().sortListeners();
		}
		
		molehill_input_internal function onMouseDown(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			if (ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.MOUSE_DOWN,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		molehill_input_internal function onMouseUp(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			if (ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.MOUSE_UP,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		molehill_input_internal function onMouseClick(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			if (ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				return false;
			}
			
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.CLICK,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		molehill_input_internal function onMouseMove(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			if (ignoreTransparentPixels)
			{
				if (isPixelTransparent(localX, localY))
				{
					if (_mouseIsOver)
					{
						onMouseOut(stageX, stageY, localX, localY, eventInitiator);
					}
					return false;
				}
				else
				{
					if (!_mouseIsOver)
					{
						onMouseOver(stageX, stageY, localX, localY, eventInitiator);
					}
				}
			}
			
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.MOUSE_MOVE,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		molehill_input_internal function onMouseOut(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			_mouseIsOver = false;
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.MOUSE_OUT,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		private var _mouseIsOver:Boolean = false;
		molehill_input_internal function onMouseOver(stageX:int, stageY:int, localX:int, localY:int, eventInitiator:Sprite3D):Boolean
		{
			if (ignoreTransparentPixels && isPixelTransparent(localX, localY))
			{
				if (_mouseIsOver)
				{
					onMouseOut(stageX, stageY, localX, localY, eventInitiator);
				}
				return false;
			}
			
			_mouseIsOver = true;
			dispatchEvent(
				new Input3DMouseEvent(
					Input3DMouseEvent.MOUSE_OVER,
					stageX,
					stageY,
					localX,
					localY,
					eventInitiator
				)
			);
			
			return true;
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			switch (type)
			{
				case Input3DMouseEvent.CLICK:
				case Input3DMouseEvent.MOUSE_DOWN:
				case Input3DMouseEvent.MOUSE_MOVE:
				case Input3DMouseEvent.MOUSE_OUT:
				case Input3DMouseEvent.MOUSE_OVER:
				case Input3DMouseEvent.MOUSE_UP:
					InputManager.getInstance().registerSprite(type, this);
					break;
			}
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			super.removeEventListener(type, listener, useCapture);
			
			InputManager.getInstance().unregisterSprite(type, this);
		}
		
		override public function dispatchEvent(event:Event):Boolean
		{
			var result:Boolean = false;
			if (willTrigger(event.type))
			{
				result = super.dispatchEvent(event);
				
				if (!result)
				{
					return result;
				}
			}
			
			var currentParent:Sprite3D = parent;
			while (currentParent != null)
			{
				if (currentParent.hasEventListener(event.type))
				{
					result = currentParent.dispatchEvent(event);
				}
				
				currentParent = currentParent.parent;
			}
			
			return result;
		}
	}
}