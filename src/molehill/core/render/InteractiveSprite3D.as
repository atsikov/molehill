package molehill.core.render
{
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import molehill.core.events.Sprite3DEvent;
	import molehill.core.input.InputManager;

	public class InteractiveSprite3D extends Sprite3D
	{
		public function InteractiveSprite3D()
		{
			super();
		}
		
		public function onMouseDown(stageX:int, stageY:int, localX:int, localY:int):void
		{
			dispatchEvent(
				new Sprite3DEvent(
					Sprite3DEvent.MOUSE_DOWN,
					stageX,
					stageY,
					localX,
					localY
				)
			);
		}
		
		public function onMouseUp(stageX:int, stageY:int, localX:int, localY:int):void
		{
			dispatchEvent(
				new Sprite3DEvent(
					Sprite3DEvent.MOUSE_UP,
					stageX,
					stageY,
					localX,
					localY
				)
			);
		}
		
		public function onMouseMove(stageX:int, stageY:int, localX:int, localY:int):void
		{
			dispatchEvent(
				new Sprite3DEvent(
					Sprite3DEvent.MOUSE_MOVE,
					stageX,
					stageY,
					localX,
					localY
				)
			);
		}
		
		public function onMouseOut(stageX:int, stageY:int, localX:int, localY:int):void
		{
			dispatchEvent(
				new Sprite3DEvent(
					Sprite3DEvent.MOUSE_OUT,
					stageX,
					stageY,
					localX,
					localY
				)
			);
		}
		
		public function onMouseOver(stageX:int, stageY:int, localX:int, localY:int):void
		{
			dispatchEvent(
				new Sprite3DEvent(
					Sprite3DEvent.MOUSE_OVER,
					stageX,
					stageY,
					localX,
					localY
				)
			);
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
			
			InputManager.getInstance().registerSprite(type, this);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			super.removeEventListener(type, listener, useCapture);
			
			InputManager.getInstance().unregisterSprite(type, this);
		}
	}
}