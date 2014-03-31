package molehill.core.input
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import molehill.core.Scene3DManager;
	import molehill.core.events.Input3DEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
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
			
			_hashListenersByType = new Dictionary();
			_hashTypeByListeners = new Dictionary();
			_objectsUnderMouse = new Dictionary();
		}
		
		private var _mouseListener:InteractiveObject;
		public function init(mouseListener:InteractiveObject):void
		{
			_mouseListener = mouseListener;
			
			_mouseStageX = mouseListener.stage != null ? mouseListener.stage.mouseX : mouseListener.mouseX;
			_mouseStageY = mouseListener.stage != null ? mouseListener.stage.mouseY : mouseListener.mouseY;
			
			mouseListener.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			mouseListener.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			mouseListener.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			mouseListener.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			mouseListener.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			mouseListener.addEventListener(Event.ENTER_FRAME, onListenerEnterFrame, false, int.MAX_VALUE);
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
		
		private function updateNativeObjectsUnderCursor(listObjects:Array):void
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
			
			_mouseKeyPressed = false;
			_mouseKeyStateChanged = true;
		}
		
		private var _listObjectsMouseDown:Array;
		private function onMouseDown(event:MouseEvent):void
		{
			if (_mouseListener.stage == null)
			{
				return;
			}
			
			_mouseKeyPressed = true;
			_mouseKeyStateChanged = true;
		}
		
		private var _objectsUnderMouse:Dictionary;
		private function onMouseMove(event:MouseEvent):void
		{
			if (_mouseListener.stage == null)
			{
				return;
			}
			
			_mouseStageX = event.stageX;
			_mouseStageY = event.stageY;
			_mouseCoordsChanged = true;
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			
		}
		
		private var _mouseStageX:Number = 0;
		private var _mouseStageY:Number = 0;
		private var _mouseKeyPressed:Boolean = false;
		private var _mouseKeyStateChanged:Boolean = false;
		private var _mouseCoordsChanged:Boolean = false;
		private var _lastMouseDownObject:Sprite3D;
		private function onListenerEnterFrame(event:Event):void
		{
			if (!_mouseCoordsChanged && !_mouseKeyStateChanged)
			{
				return;
			}
			
			var listener:InteractiveSprite3D;
			var mousePoint:Point = new Point(_mouseStageX, _mouseStageY);
			var nativeObjects:Array = _mouseListener.stage.getObjectsUnderPoint(mousePoint);
			updateNativeObjectsUnderCursor(nativeObjects);
			
			var parent:Sprite3DContainer;
			var localShiftX:Number = 0;
			var localShiftY:Number = 0;
			// Display List objects overlap our 3d scene
			// Dispatching MOUSE_OUT for previous objects under mouse
			var listMouseOutListeners:Array = _hashListenersByType[Input3DEvent.MOUSE_OUT];
			if (nativeObjects.length > 0)
			{
				for (var objectUnderMouse:Object in _objectsUnderMouse)
				{
					listener = objectUnderMouse as InteractiveSprite3D;
					
					localShiftX = 0;
					localShiftY = 0;
					
					parent = listener.parent;
					while (parent != null)
					{
						if (parent.scrollRect != null)
						{
							localShiftX += parent.scrollRect.x;
							localShiftY += parent.scrollRect.y;
						}
						
						parent = parent.parent;
					}
					
					if (listMouseOutListeners != null && listMouseOutListeners.indexOf(listener) != -1)
					{
						listener.onMouseOut(
							_mouseStageX,
							_mouseStageY,
							_mouseStageX + localShiftX,
							_mouseStageY + localShiftY
						);
					}
					
					_objectsUnderMouse[listener] = null;
				}
				
				return;
			}
			
			var activeScene:Scene3D = Scene3DManager.getInstance().activeScene;
			var molehillObjects:Vector.<Sprite3D> = activeScene.getObjectsUnderPoint(mousePoint);
			var numObjects:Number = molehillObjects.length;
			
			for (var i:int = numObjects - 1; i >= 0; i--)
			{
				var candidate:Sprite3D = molehillObjects[i] as Sprite3D;
				if (candidate == null)
				{
					continue;
				}
				
				if (!candidate.mouseEnabled)
				{
					parent = candidate.parent;
					while (parent != null && !parent.mouseEnabled) 
					{
						parent = parent.parent;
					}
					
					if (parent == null)
					{
						continue;
					}
				}
				
				if (_hashTypeByListeners[candidate] == null)
				{
					parent = candidate.parent;
					while (parent != null && _hashTypeByListeners[parent] == null) 
					{
						parent = parent.parent;
					}
					
					if (parent != null)
					{
						candidate = parent;
					}
					else
					{
						//continue;
					}
				}
				
				var localPoint:Point = new Point(_mouseStageX, _mouseStageY);
 				candidate.globalToLocal(localPoint);
				localShiftX = localPoint.x;
				localShiftY = localPoint.y;
				/*
				parent = candidate is Sprite3DContainer ? candidate as Sprite3DContainer : candidate.parent;
				while (parent != null)
				{
					if (parent.scrollRect != null)
					{
						localShiftX += parent.scrollRect.x;
						localShiftY += parent.scrollRect.y;
					}
					
					parent = parent.parent;
				}
				*/
				var eventTypes:Array = _hashTypeByListeners[candidate];
				if (eventTypes != null)
				{
					for (var j:int = 0; j < eventTypes.length; j++)
					{
						var eventType:String = eventTypes[j];
						switch (eventType)
						{
							case Input3DEvent.MOUSE_OVER:
								if (_mouseCoordsChanged && _objectsUnderMouse[candidate] == null)
								{
									if ((candidate as InteractiveSprite3D).onMouseOver(
										_mouseStageX,
										_mouseStageY,
										localShiftX,
										localShiftY
									))
									{
										_objectsUnderMouse[candidate] = true;
									}
								}
								break;
							case Input3DEvent.CLICK:
								if (_mouseKeyStateChanged && !_mouseKeyPressed && _lastMouseDownObject === candidate)
								{
									if ((candidate as InteractiveSprite3D).onMouseClick(
										_mouseStageX,
										_mouseStageY,
										localShiftX,
										localShiftY
									))
									{
										_objectsUnderMouse[candidate] = true;
									}
								}
								break;
							case Input3DEvent.MOUSE_UP:
								if (_mouseKeyStateChanged && !_mouseKeyPressed)
								{
									if ((candidate as InteractiveSprite3D).onMouseUp(
										_mouseStageX,
										_mouseStageY,
										localShiftX,
										localShiftY
									))
									{
										_objectsUnderMouse[candidate] = true;
									}
								}
								break;
							case Input3DEvent.MOUSE_DOWN:
								if (_mouseKeyStateChanged && _mouseKeyPressed)
								{
									if ((candidate as InteractiveSprite3D).onMouseDown(
										_mouseStageX,
										_mouseStageY,
										localShiftX,
										localShiftY
									))
									{
										_objectsUnderMouse[candidate] = true;
									}
								}
								break;
							case Input3DEvent.MOUSE_MOVE:
								if (_mouseCoordsChanged)
								{
									if ((candidate as InteractiveSprite3D).onMouseMove(
										_mouseStageX,
										_mouseStageY,
										localShiftX,
										localShiftY
									))
									{
										_objectsUnderMouse[candidate] = true;
									}
								}
								break;
						}
					}
				}
				
				if (_mouseKeyStateChanged)
				{
					_lastMouseDownObject = _mouseKeyPressed ? candidate : null;
				}
				
				
				break;
			}
			
			for (objectUnderMouse in _objectsUnderMouse)
			{
				listener = objectUnderMouse as InteractiveSprite3D;
				if (_objectsUnderMouse[listener] == null)
				{
					continue;
				}
				
				if (listener === candidate)
				{
					continue;
				}
				
				localShiftX = 0;
				localShiftY = 0;
				
				parent = listener.parent;
				while (parent != null)
				{
					if (parent.scrollRect != null)
					{
						localShiftX += parent.scrollRect.x;
						localShiftY += parent.scrollRect.y;
					}
					
					parent = parent.parent;
				}
				
				if (listMouseOutListeners != null && listMouseOutListeners.indexOf(listener) != -1)
				{
					listener.onMouseOut(
						_mouseStageX,
						_mouseStageY,
						_mouseStageX + localShiftX,
						_mouseStageY + localShiftY
					);
				}
				
				_objectsUnderMouse[listener] = null;
			}
			
			_mouseKeyStateChanged = false;
			_mouseCoordsChanged = false;
		}
		
		private var _hashListenersByType:Dictionary;
		private var _hashTypeByListeners:Dictionary;
		public function registerSprite(type:String, sprite:InteractiveSprite3D):void
		{
			if (_hashTypeByListeners[sprite] == null)
			{
				_hashTypeByListeners[sprite] = new Array();
			}
			if (_hashTypeByListeners[sprite].indexOf(type) == -1)
			{
				_hashTypeByListeners[sprite].push(type);
			}
			
			if (_hashListenersByType[type] == null)
			{
				_hashListenersByType[type] = new Array();
			}
			if (_hashListenersByType[type].indexOf(sprite) == -1)
			{
				_hashListenersByType[type].push(sprite);
			}
			
		}
		
		public function unregisterSprite(type:String, sprite:InteractiveSprite3D):void
		{
			if (_hashTypeByListeners[sprite] != null)
			{
				var listenerIndex:int = _hashTypeByListeners[sprite].indexOf(type);
				if (listenerIndex != -1)
				{
					_hashTypeByListeners[sprite].splice(listenerIndex, 1);
					if (_hashTypeByListeners[sprite].length == 0)
					{
						delete _hashTypeByListeners[sprite];
					}
				}
			}
			
			if (_hashListenersByType[type] != null)
			{
				listenerIndex = _hashListenersByType[type].indexOf(sprite);
				if (listenerIndex != -1)
				{
					_hashListenersByType[type].splice(listenerIndex, 1);
					if (_hashListenersByType[type].length == 0)
					{
						delete _hashListenersByType[type];
					}
				}
			}
		}
	}
}