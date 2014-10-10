package molehill.core.input
{
	import flash.display.DisplayObject;
	import flash.display.InteractiveObject;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import molehill.core.Scene3DManager;
	import molehill.core.events.Input3DKeyboardEvent;
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.molehill_input_internal;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	use namespace molehill_input_internal;
	
	[Event(name="keyDown", type="molehill.core.events.Input3DKeyboardEvent")]
	
	[Event(name="keyUp", type="molehill.core.events.Input3DKeyboardEvent")]
	
	public class InputManager extends EventDispatcher
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
		
		private var _stage:Stage;
		public function init(stage:Stage):void
		{
			_stage = stage;
			
			_mouseStageX = stage.mouseX;
			_mouseStageY = stage.mouseY;
			
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
			
			stage.addEventListener(Event.ENTER_FRAME, onListenerEnterFrame, false, int.MAX_VALUE);
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
				_stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_stage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				_stage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				_stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp);
				_stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				
				_objectsUnderMouse = new Dictionary();
			}
			else
			{
				_stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				_stage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				_stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyUp);
				_stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
				
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
					child.parent != _stage &&
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
			if (_stage.stage == null)
			{
				return;
			}
			
			_mouseKeyPressed = false;
			_mouseKeyStateChanged = true;
		}
		
		private var _listObjectsMouseDown:Array;
		private function onMouseDown(event:MouseEvent):void
		{
			if (_stage.stage == null)
			{
				return;
			}
			
			_mouseKeyPressed = true;
			_mouseKeyStateChanged = true;
		}
		
		private var _objectsUnderMouse:Dictionary;
		molehill_input_internal function isObjectUnderMouse(object:InteractiveSprite3D):Boolean
		{
			return _objectsUnderMouse[object] != null && _objectsUnderMouse[object];
		}
		
		private function onMouseMove(event:MouseEvent):void
		{
			if (_stage.stage == null)
			{
				return;
			}
			
			_mouseStageX = event.stageX;
			_mouseStageY = event.stageY;
			_mouseCoordsChanged = true;
		}
		
		public function get mouseStageX():int
		{
			return _mouseStageX;
		}
		
		public function get mouseStageY():int
		{
			return _mouseStageY;
		}
		
		private function onKeyUp(event:KeyboardEvent):void
		{
			dispatchEvent(
				new Input3DKeyboardEvent(
					Input3DKeyboardEvent.KEY_UP,
					event.charCode,
					event.keyCode,
					event.keyLocation,
					event.ctrlKey,
					event.altKey,
					event.shiftKey
				)
			);
		}
		
		private function onKeyDown(event:KeyboardEvent):void
		{
			dispatchEvent(
				new Input3DKeyboardEvent(
					Input3DKeyboardEvent.KEY_DOWN,
					event.charCode,
					event.keyCode,
					event.keyLocation,
					event.ctrlKey,
					event.altKey,
					event.shiftKey
				)
			);
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
			var nativeObjects:Array = _stage.stage.getObjectsUnderPoint(mousePoint);
			updateNativeObjectsUnderCursor(nativeObjects);
			
			var parent:Sprite3D;
			var localShiftX:Number = 0;
			var localShiftY:Number = 0;
			// Display List objects overlap our 3d scene
			// Dispatching MOUSE_OUT for previous objects under mouse
			var listMouseOutListeners:Array = _hashListenersByType[Input3DMouseEvent.MOUSE_OUT];
			if (nativeObjects.length > 0)
			{
				for (var objectUnderMouse:Object in _objectsUnderMouse)
				{
					listener = objectUnderMouse as InteractiveSprite3D;
					
					localShiftX = 0;
					localShiftY = 0;
					
					parent = listener;
					while (parent != null)
					{
						if (parent.camera != null)
						{
							localShiftY /= parent.camera.scale;
							localShiftY /= parent.camera.scale;
							
							localShiftX += parent.camera.scrollX;
							localShiftY += parent.camera.scrollY;
						}
						
						parent = parent.parent;
					}
					
					if (listMouseOutListeners != null && listMouseOutListeners.indexOf(listener) != -1)
					{
						listener.onMouseOut(
							_mouseStageX,
							_mouseStageY,
							_mouseStageX + localShiftX,
							_mouseStageY + localShiftY,
							listener
						);
					}
					
					_objectsUnderMouse[listener] = null;
				}
				
				return;
			}
			
			var sceneManager:Scene3DManager = Scene3DManager.getInstance();
			for (var i:int = 0; i < sceneManager.numScenes; i++)
			{
				var molehillObjects:Vector.<Sprite3D> = sceneManager.getSceneAt(i).getObjectsUnderPoint(mousePoint, molehillObjects);
			}
			var numObjects:Number = molehillObjects == null ? 0 : molehillObjects.length;
			
			var firstInteractiveContainer:Sprite3DContainer;
			var topInteractiveParent:InteractiveSprite3D;
			var eventsProcessed:Boolean = false;
			var triggerSprite:Sprite3D;
			for (i = numObjects - 1; i >= 0; i--)
			{
				var candidate:Sprite3D = molehillObjects[i] as Sprite3D;
				
				if (topInteractiveParent == null)
				{
					topInteractiveParent = candidate.scene;
				}
				
				if (!candidate.mouseEnabled)
				{
					var candidateParent:Sprite3DContainer = candidate.parent;
					while (candidateParent != null && !candidateParent.mouseEnabled)
					{
						candidateParent = candidateParent.parent;
					}
					
					if (candidateParent == topInteractiveParent)
					{
						continue;
					}
					
					firstInteractiveContainer = candidateParent;
					while (candidateParent != null && candidateParent !== topInteractiveParent)
					{
						candidateParent = candidateParent.parent;
					}
					
					if (candidateParent == null)
					{
						continue;
					}
					else
					{
						topInteractiveParent = firstInteractiveContainer;
						triggerSprite = candidate;
						
						continue;
					}
				}
				else
				{
					if (!(topInteractiveParent is Scene3D))
					{
						candidateParent = candidate.parent;
						while (candidateParent != null && candidateParent !== topInteractiveParent)
						{
							candidateParent = candidateParent.parent;
						}
						
						if (candidateParent == topInteractiveParent)
						{
							triggerSprite = candidate;
							topInteractiveParent = triggerSprite is InteractiveSprite3D ? triggerSprite as InteractiveSprite3D : triggerSprite.parent;
						}
						else
						{
							continue;
						}
					}
					
					triggerSprite = candidate;
					topInteractiveParent = triggerSprite is InteractiveSprite3D ? triggerSprite as InteractiveSprite3D : triggerSprite.parent;
					
					break;
				}
			}
			
			if (numObjects > 0)
			{
				if (triggerSprite == null)
				{
					triggerSprite = molehillObjects[numObjects - 1];
				}
				processEvents(topInteractiveParent, triggerSprite);
				
				if (_mouseKeyStateChanged)
				{
					_lastMouseDownObject = _mouseKeyPressed ? topInteractiveParent : null;
				}
			}
			
			for (objectUnderMouse in _objectsUnderMouse)
			{
				listener = objectUnderMouse as InteractiveSprite3D;
				
				if (_objectsUnderMouse[listener] == null)
				{
					continue;
				}
				
				if (listener === topInteractiveParent)
				{
					continue;
				}
				
				localShiftX = 0;
				localShiftY = 0;
				
				parent = listener.parent;
				while (parent != null)
				{
					if (parent.camera != null)
					{
						localShiftY /= parent.camera.scale;
						localShiftY /= parent.camera.scale;
						
						localShiftX += parent.camera.scrollX;
						localShiftY += parent.camera.scrollY;
					}
					
					parent = parent.parent;
				}
				
				listener.onMouseOut(
					_mouseStageX,
					_mouseStageY,
					_mouseStageX + localShiftX,
					_mouseStageY + localShiftY,
					listener
				);
				
				_objectsUnderMouse[listener] = null;
			}
			
			_mouseKeyStateChanged = false;
			_mouseCoordsChanged = false;
		}
		
		private function processEvents(candidate:InteractiveSprite3D, triggerSprite:Sprite3D):void
		{
			var localPoint:Point = new Point(_mouseStageX, _mouseStageY);
			candidate.globalToLocal(localPoint);
			
			if (_mouseCoordsChanged && _objectsUnderMouse[candidate] == null)
			{
				if (candidate.onMouseOver(
					_mouseStageX,
					_mouseStageY,
					localPoint.x,
					localPoint.y,
					triggerSprite
				))
				{
					_objectsUnderMouse[candidate] = true;
				}
			}
			
			if (_mouseKeyStateChanged && !_mouseKeyPressed && _lastMouseDownObject === candidate)
			{
				if (candidate.onMouseClick(
					_mouseStageX,
					_mouseStageY,
					localPoint.x,
					localPoint.y,
					triggerSprite
				))
				{
					_objectsUnderMouse[candidate] = true;
				}
			}
			
			if (_mouseKeyStateChanged && !_mouseKeyPressed)
			{
				if (candidate.onMouseUp(
					_mouseStageX,
					_mouseStageY,
					localPoint.x,
					localPoint.y,
					triggerSprite
				))
				{
					_objectsUnderMouse[candidate] = true;
				}
			}
			
			if (_mouseKeyStateChanged && _mouseKeyPressed)
			{
				if (candidate.onMouseDown(
					_mouseStageX,
					_mouseStageY,
					localPoint.x,
					localPoint.y,
					triggerSprite
				))
				{
					_objectsUnderMouse[candidate] = true;
				}
			}
			
			if (_mouseCoordsChanged)
			{
				if ((candidate as InteractiveSprite3D).onMouseMove(
					_mouseStageX,
					_mouseStageY,
					localPoint.x,
					localPoint.y,
					triggerSprite
				))
				{
					_objectsUnderMouse[candidate] = true;
				}
			}
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