package molehill.core.input
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	
	public class InputManager
	{
		private static var _instance:InputManager;
		public static function getInstance():InputManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new InputManager();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function InputManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use InputManager::getInstance()");
			}
			
			_hashEventListeners = new Object();
			_objectsUnderMouse = new Dictionary();
		}
		
		private var _mouseListener:InteractiveObject;
		public function init(mouseListener:InteractiveObject):void
		{
			_mouseListener = mouseListener;
			
			mouseListener.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			mouseListener.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			mouseListener.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			mouseListener.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			mouseListener.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		}
		
		private var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			if (value == _enabled)
			{
				return;
			}
			
			if (value)
			{
				_mouseListener.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_mouseListener.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				_mouseListener.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				_mouseListener.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
				_mouseListener.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				
				_objectsUnderMouse = new Dictionary();
			}
			else
			{
				_mouseListener.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_mouseListener.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				_mouseListener.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				_mouseListener.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
				_mouseListener.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				
				_objectsUnderMouse = null;
			}
			
			_enabled = value;
		}
		
		private function updateObjectsUnderCursor(listObjects:Array):void
		{
			var i:int = 0;
			while (listObjects.length > i)
			{
				var child:DisplayObject = listObjects[i] as DisplayObject;
				while (
					!(child is IMouseTransparent) && 
					child.parent != null && 
					child.parent != _mouseListener &&
					(!(child is IMouseDynamicTransparent) || !(child as IMouseDynamicTransparent).isTransparent)
				)
				{
					child = child.parent;
				}
				
				if (
					child == null || 
					(child is IMouseTransparent) || 
					!(child is InteractiveObject) || 
					(child as InteractiveObject).mouseEnabled == false ||
					((child is IMouseDynamicTransparent) && (child as IMouseDynamicTransparent).isTransparent)
				)
				{
					listObjects.splice(i, 1);
				}
				else 
				{
					i++;
				}
			}
			
		}
		
		private function onMouseUp(event:MouseEvent):void
		{
			if (_mouseListener.stage == null)
			{
				return;
			}
			
			var objectsUnderPoint:Array = _mouseListener.stage.getObjectsUnderPoint(new Point(event.stageX, event.stageY));
			updateObjectsUnderCursor(objectsUnderPoint);
			
			if (objectsUnderPoint.length > 0)
			{
				return;
			}
			
			var listener:InteractiveSprite3D;
			var mouseUpListeners:Vector.<InteractiveSprite3D> = _hashEventListeners[MouseEvent.MOUSE_UP];
			var mousePoint:Point = new Point(event.stageX, event.stageY);
			var cameraPositionX:Number;
			var cameraPositionY:Number;
			var currentScene:Scene3D;
			for each (listener in mouseUpListeners)
			{
				if (listener.getScene() == null)
				{
					continue;
				}
				
				if (currentScene != listener.getScene())
				{
					currentScene = listener.getScene();
					cameraPositionX = currentScene.cameraX;
					cameraPositionY = currentScene.cameraY;
				}
				
				if (listener.hitTestPoint(mousePoint))
				{
					listener.onMouseUp(
						event.stageX,
						event.stageY,
						event.stageX - cameraPositionX,
						event.stageY - cameraPositionY
					);
				}
			}
		}
		
		private function onMouseDown(event:MouseEvent):void
		{
			if (_mouseListener.stage == null)
			{
				return;
			}
			
			var objectsUnderPoint:Array = _mouseListener.stage.getObjectsUnderPoint(new Point(event.stageX, event.stageY));
			updateObjectsUnderCursor(objectsUnderPoint);
			
			if (objectsUnderPoint.length > 0)
			{
				return;
			}
			
			var listener:InteractiveSprite3D;
			var mouseDownListeners:Vector.<InteractiveSprite3D> = _hashEventListeners[MouseEvent.MOUSE_DOWN];
			var mousePoint:Point = new Point(event.stageX, event.stageY);
			var cameraPositionX:Number;
			var cameraPositionY:Number;
			var currentScene:Scene3D;
			for each (listener in mouseDownListeners)
			{
				if (listener.getScene() == null)
				{
					continue;
				}
				
				if (currentScene != listener.getScene())
				{
					currentScene = listener.getScene();
					cameraPositionX = currentScene.cameraX;
					cameraPositionY = currentScene.cameraY;
				}
				
				if (listener.hitTestPoint(mousePoint))
				{
					listener.onMouseDown(
						event.stageX,
						event.stageY,
						event.stageX - cameraPositionX,
						event.stageY - cameraPositionY
					);
				}
			}
		}
		
		private var _objectsUnderMouse:Dictionary;
		private function onMouseMove(event:MouseEvent):void
		{
			if (_mouseListener.stage == null)
			{
				return;
			}
			
			var objectsUnderPoint:Array = _mouseListener.stage.getObjectsUnderPoint(new Point(event.stageX, event.stageY));
			var listener:InteractiveSprite3D;
			
			var mouseMoveListeners:Vector.<InteractiveSprite3D> = _hashEventListeners[MouseEvent.MOUSE_MOVE];
			var mouseOverListeners:Vector.<InteractiveSprite3D> = _hashEventListeners[MouseEvent.MOUSE_OVER];
			var mouseOutListeners:Vector.<InteractiveSprite3D> = _hashEventListeners[MouseEvent.MOUSE_OUT];
			
			var mousePoint:Point = new Point(event.stageX, event.stageY);
			var cameraPositionX:Number;
			var cameraPositionY:Number;
			var currentScene:Scene3D;
			
			updateObjectsUnderCursor(objectsUnderPoint);
			
			if (objectsUnderPoint.length > 0)
			{
				for (var listenerObj:Object in _objectsUnderMouse)
				{
					listener = listenerObj as InteractiveSprite3D;
					if (mouseOutListeners != null && mouseOutListeners.indexOf(listener) != -1 && _objectsUnderMouse[listener] != null)
					{
						if (listener.getScene() == null)
						{
							continue;
						}
						
						if (currentScene != listener.getScene())
						{
							currentScene = listener.getScene();
							cameraPositionX = currentScene.cameraX;
							cameraPositionY = currentScene.cameraY;
						}
						
						listener.onMouseOut(
							event.stageX,
							event.stageY,
							event.stageX - cameraPositionX,
							event.stageY - cameraPositionY
						);
						_objectsUnderMouse[listener] = null;
					}
				}
				
				return;
			}
			
			for each (listener in mouseMoveListeners)
			{
				if (listener.getScene() == null)
				{
					continue;
				}
				
				if (currentScene != listener.getScene())
				{
					currentScene = listener.getScene();
					cameraPositionX = currentScene.cameraX;
					cameraPositionY = currentScene.cameraY;
				}
				
				if (listener.visible == false)
				{
					continue;
				}
				
				if (listener.hitTestPoint(mousePoint))
				{
					listener.onMouseMove(
						event.stageX,
						event.stageY,
						event.stageX - cameraPositionX,
						event.stageY - cameraPositionY
					);
					if (mouseOverListeners == null || mouseOverListeners != null && mouseOverListeners.indexOf(listener) == -1)
					{
						_objectsUnderMouse[listener] = true;
					}
				}
			}
			
			for (listenerObj in _objectsUnderMouse)
			{
				listener = listenerObj as InteractiveSprite3D;
				
				if (listener.getScene() == null)
				{
					continue;
				}
				
				if (currentScene != listener.getScene())
				{
					currentScene = listener.getScene();
					cameraPositionX = currentScene.cameraX;
					cameraPositionY = currentScene.cameraY;
				}
				
				if (!listener.hitTestPoint(mousePoint))
				{
					if (mouseOutListeners != null && mouseOutListeners.indexOf(listener) != -1 && _objectsUnderMouse[listener] != null)
					{
						listener.onMouseOut(
							event.stageX,
							event.stageY,
							event.stageX - cameraPositionX,
							event.stageY - cameraPositionY
						);
						_objectsUnderMouse[listener] = null;
					}
				}
			}
			
			for each (listener in mouseOverListeners)
			{
				if (listener.getScene() == null)
				{
					continue;
				}
				
				if (currentScene != listener.getScene())
				{
					currentScene = listener.getScene();
					cameraPositionX = currentScene.cameraX;
					cameraPositionY = currentScene.cameraY;
				}
				
				if (listener.hitTestPoint(mousePoint))
				{
					if (_objectsUnderMouse[listener] == null)
					{
						listener.onMouseOver(
							event.stageX,
							event.stageY,
							event.stageX - cameraPositionX,
							event.stageY - cameraPositionY
						);
						_objectsUnderMouse[listener] = true;
					}
				}
			}
			
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			
		}
		
		private var _hashEventListeners:Object;
		public function registerSprite(type:String, sprite:InteractiveSprite3D):void
		{
			if (_hashEventListeners[type] == null)
			{
				_hashEventListeners[type] = new Vector.<InteractiveSprite3D>();
			}
			else if (_hashEventListeners[type].indexOf(sprite) != -1)
			{
				return;
			}
			
			_hashEventListeners[type].push(sprite);
		}
		
		public function unregisterSprite(type:String, sprite:InteractiveSprite3D):void
		{
			if (_hashEventListeners[type] == null)
			{
				return;
			}
			
			var listenerIndex:int = _hashEventListeners[type].indexOf(sprite);
			if (listenerIndex == -1)
			{
				return;
			}
			
			_hashEventListeners[type].splice(listenerIndex, 1);
			if (_hashEventListeners[type].length == 0)
			{
				delete _hashEventListeners[type];
			}
		}
	}
}