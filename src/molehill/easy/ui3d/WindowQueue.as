package molehill.easy.ui3d
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.effects.WindowEffectsSet;

	public class WindowQueue extends EventDispatcher
	{
		private static var _instance:WindowQueue;
		public static function getInstance():WindowQueue
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new WindowQueue();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		//--------------------------------------------------------------------------------------
		private static var _allowInstantion:Boolean = false;
		public function WindowQueue()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use WindowQueue::getInstance()");
			}
		}
		
		private var _queue:Array = new Array();
		private var _formDict:Dictionary = new Dictionary();
		
		private var _currentForm:Sprite3D = null;
		
		public function show(form:Sprite3D, modal:Boolean = false, effectsSet:WindowEffectsSet = null):void
		{
			if (_formDict[form] != null)
			{
				return;
			}
			
			if (_currentForm != null && _currentForm === form && !_currentFormClosed)
			{
				return;
			}
			
			_queue.push(form);
			_formDict[form] = {
				'modal' : modal,
				'effects' : effectsSet
			};
			
			processQueue();
		}
		
		private function processQueue():void
		{
			if (_currentForm != null)
				return;
			
			_currentForm = _queue.shift() as Sprite3D;
			var formData:Object = _formDict[_currentForm];
			
			delete _formDict[_currentForm];
			_currentFormClosed = false;
			
			if (_currentForm != null)
			{
				_currentForm.addEventListener(Event.CLOSE, onCurrentFormClose);
				_currentForm.addEventListener(Event.COMPLETE, onCurrentFormComplete);
				
				
				var windowManager:WindowManager3D = WindowManager3D.getInstance();
				//---
				windowManager.centerPopUp(_currentForm);
				windowManager.addPopUp(
					_currentForm,
					formData['modal'],
					formData['effects']
				);
				//---
				_currentForm.dispatchEvent(
					new Event(Event.OPEN)
				);
				
				dispatchEvent(
					new Event(Event.CHANGE)
				);
			}
		}
		
		private var _currentFormClosed:Boolean = false;
		private function onCurrentFormClose(event:Event):void
		{
			if (_currentForm !== event.target)
				return;
			
			_currentFormClosed = true;
			
			_currentForm.removeEventListener(Event.CLOSE, onCurrentFormClose);
		}
		
		private function onCurrentFormComplete(event:Event):void
		{
			if (_currentForm !== event.target)
				return;
			
			_currentForm.removeEventListener(Event.CLOSE, onCurrentFormClose);
			_currentForm = null;
			
			processQueue();
		}
	}
}