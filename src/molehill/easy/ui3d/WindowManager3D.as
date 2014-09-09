package molehill.easy.ui3d
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.easy.ui3d.effects.TweenCameraEffect;
	import molehill.easy.ui3d.effects.WindowEffectsSet;
	
	[Event(name="change", type="flash.events.Event")]
	[Event(name="close", type="flash.events.Event")]

	public class WindowManager3D extends EventDispatcher
	{	
		static private var _instance:WindowManager3D;

		static public function getInstance():WindowManager3D
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new WindowManager3D();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		static private var _allowInstantion:Boolean = false;
		public function WindowManager3D()
		{
			if (!_allowInstantion)
			{
				throw new Error('Use WindowManager3D::getInstance()');
			}
		}
		
		private var _contentLayer:Sprite3DContainer = new Sprite3DContainer();
		
		public function get contentLayer():Sprite3DContainer
		{
			return _contentLayer;
		}
		
		private var _contentRegion:Rectangle = new Rectangle(0, 0, 760, 690);
		
		public function get contentRegion():Rectangle
		{
			return _contentRegion;
		}
		
		public function set contentRegion(value:Rectangle):void
		{
			_contentRegion = value;
			
			resize();
		}
		
		private var _blurLayer:Sprite3D;
		
		public function get blurLayer():Sprite3D
		{
			return _blurLayer;
		}
		
		public function set blurLayer(value:Sprite3D):void
		{
			_blurLayer = value;
		}
		
		private var _modalBGColor:uint = 0xffffff;
		
		public function get modalBGColor():uint
		{
			return _modalBGColor;
		}
		
		public function set modalBGColor(value:uint):void
		{
			_modalBGColor = value;
		}
		
		private var _modalBGAlpha:Number = .5;
		
		public function get modalBGAlpha():Number
		{
			return _modalBGAlpha;
		}
		
		public function set modalBGAlpha(value:Number):void
		{
			_modalBGAlpha = value;
		}
		
		public function addPopUp(popUp:Sprite3D, modal:Boolean = false, effectsSet:WindowEffectsSet = null):void
		{
			if (_contentLayer.contains(popUp))
			{
				bringToFront(popUp);
				return;
			}
			
			var modalBG:Sprite3D = null;
			
			if (modal)
			{
				setNumModals(_numModals + 1);
				
				modalBG = getModalBG();
				_contentLayer.addChild(modalBG);
			}
			
			_contentLayer.addChild(popUp);
			_openedWindows.push(popUp);
			
			if (popUp.hasEventListener(Event.OPEN))
			{
				popUp.dispatchEvent(
					new Event(Event.OPEN)
				);
			}
			
			var executor:PopUpExecutor = new PopUpExecutor(
				popUp,
				modalBG,
				effectsSet,
				_contentLayer
			);
			executor.show();

			dispatchEvent(
				new Event(Event.CHANGE)
			);
		}
		
		public function removePopUp(popUp:Sprite3D):Boolean
		{
			if (!_contentLayer.contains(popUp))
			{
				return false;
			}
			
			var executor:PopUpExecutor = PopUpExecutor.getByPopUp(popUp);
			
			if (executor == null)
			{
				return false;
			}
			
			executor.close(onPopUpClosed);
			
			var index:int = _openedWindows.indexOf(popUp);
			if (index > -1)
				_openedWindows.splice(index, 1);
			
			dispatchEvent(
				new Event(Event.CHANGE)
			);

			return true;
		}
		
		private function getModalBG():Sprite3D
		{
			var sprite:Sprite3D = new InteractiveSprite3D();
			sprite.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, false, Shader3D.TEXTURE_DONT_USE_TEXTURE);
			sprite.moveTo(contentRegion.x, contentRegion.y);
			sprite.setSize(contentRegion.width, contentRegion.height);
			sprite.darkenColor = _modalBGColor;
			sprite.mouseEnabled = true;
			sprite.ignoreTransparentPixels = false;
			sprite.alpha = _modalBGAlpha;
			return sprite;
		}
		
		private function onPopUpClosed(executor:PopUpExecutor):void
		{
			var popUp:Sprite3D = executor.popUp;
			if (_contentLayer.contains(popUp))
			{
				_contentLayer.removeChild(popUp);
			}
			
			var modalBG:Sprite3D = executor.modalBG; 
			if ((modalBG != null) && (modalBG.parent != null))
			{
				modalBG.parent.removeChild(modalBG);
				
				setNumModals(_numModals - 1);
			}
			
			dispatchEvent(
				new Event(Event.CLOSE)
			);
			
			if (popUp.hasEventListener(Event.CLOSE))
			{
				popUp.dispatchEvent(
					new Event(Event.CLOSE)
				);
			}
			
			if (popUp.hasEventListener(Event.COMPLETE))
			{
				popUp.dispatchEvent(
					new Event(Event.COMPLETE)
				);
			}
		}
		
		public function resize():void
		{
			for (var i:int = 0; i < _openedWindows.length; i++) 
			{
				var executor:PopUpExecutor = PopUpExecutor.getByPopUp(_openedWindows[i]);
				
				if (executor.effectsSet != null && executor.effectsSet.show is TweenCameraEffect)
				{
					(executor.effectsSet.show as TweenCameraEffect).placeTarget(_openedWindows[i]);
				}
				else
				{
					centerPopUp(_openedWindows[i]);
				}
				
				var modalBG:Sprite3D = executor != null ? executor.modalBG as Sprite3D : null; 
				if (modalBG != null)
				{
					modalBG.moveTo(contentRegion.x, contentRegion.y);
					modalBG.setSize(contentRegion.width, contentRegion.height);
					centerPopUp(modalBG);
				}
			}
			
		}
		
		public function bringToFront(popUp:Sprite3D):void
		{
			if ( _contentLayer.contains(popUp) )
			{
				_contentLayer.removeChild(popUp);
				//return;
			}
			
			var executor:PopUpExecutor = PopUpExecutor.getByPopUp(popUp);
			var modalBG:Sprite3D = executor != null ? executor.modalBG : null; 
			if (modalBG != null)
			{
				_contentLayer.removeChild(modalBG);
				_contentLayer.addChild(modalBG);
			}
			
			_contentLayer.addChild(popUp);
		}
		
		public function centerPopUp(popUp:Sprite3D):void
		{
			popUp.moveTo(
				int(contentRegion.x + (contentRegion.width - popUp.width) / 2),
				int(contentRegion.y + (contentRegion.height - popUp.height) / 2)
			);
		}
		
		public function alignToBottom(popUp:Sprite3D):void
		{
			popUp.y = contentRegion.y + contentRegion.height - popUp.height;
		}
		
		public function alignToTop(popUp:Sprite3D):void
		{
			popUp.y = contentRegion.y;
		}
		
		public function alignToLeft(popUp:Sprite3D):void
		{
			popUp.x = contentRegion.x;
		}
		
		public function alignToRight(popUp:Sprite3D):void
		{
			popUp.x = contentRegion.x + contentRegion.width + popUp.width;
		}
		
		private var _openedWindows:Vector.<Sprite3D> = new Vector.<Sprite3D>();
		public function get numWindows():uint
		{
			return _openedWindows.length;
		}
		
		public function get hasWindows():Boolean
		{
			return numWindows > 0;
		}
		
		public function hasWindowOpenedByClass(popupClass:Class):Boolean
		{
			for (var i:int = 0; i < _openedWindows.length; i++)
				if (_openedWindows[i] is popupClass)
					return true;
			return false;
		}
		
		private function setNumModals(value:int):void
		{
			var oldValue:int = _numModals;
			_numModals = value;
			
			if (value < oldValue && value == 0 || value > oldValue && oldValue == 0)
			{
				dispatchEvent(new Event(Event.CHANGE));
			}
		}
		
		private var _numModals:int = 0;
		
		public function get hasModalPopUps():Boolean
		{
			return _numModals > 0;
		}
	}
}
import easy.ui.ISnapshotable;

import flash.utils.Dictionary;

import molehill.core.sprite.Sprite3D;
import molehill.core.sprite.Sprite3DContainer;
import molehill.easy.ui3d.effects.WindowEffectsSet;

class PopUpExecutor
{
	private static var _executorByPopUp:Dictionary = new Dictionary();
	
	public static function getByPopUp(popUp:Sprite3D):PopUpExecutor
	{
		return _executorByPopUp[popUp];
	}
	
	public function PopUpExecutor(
		popUp:Sprite3D,
		modalBG:Sprite3D,
		effectsSet:WindowEffectsSet,
		contentLayer:Sprite3DContainer
	)
	{
		_executorByPopUp[popUp] = this;
		
		_popUp = popUp;
		_modalBG = modalBG;
		_effectsSet = effectsSet;
		_contentLayer = contentLayer;
	}
	
	private var _popUp:Sprite3D;
	
	public function get popUp():Sprite3D
	{
		return _popUp;
	}
	
	private var _modalBG:Sprite3D;
	
	public function get modalBG():Sprite3D
	{
		return _modalBG;
	}
	
	private var _effectsSet:WindowEffectsSet;
	public function get effectsSet():WindowEffectsSet
	{
		return _effectsSet;
	}
	
	private var _contentLayer:Sprite3DContainer;
	
	public function show():void
	{
		if (_effectsSet != null)
		{
			if (_effectsSet.show != null)
			{
				makeEffectsObject();
				_effectsSet.show.showEffect(_effectsObject, onShowComplete);
			}
			if (_modalBG != null && _effectsSet.showModalBG != null)
			{
				_effectsSet.showModalBG.showEffect(_modalBG);
			}
		}
	}
	
	private function onShowComplete():void
	{
		removeEffectsObject();
	}
	
	private var _closeCallback:Function;
	
	public function close(closeCallback:Function):void
	{
		_closeCallback = closeCallback;
		
		if (_effectsSet != null && _effectsSet.close != null)
		{
			makeEffectsObject();
			
			_effectsSet.close.showEffect(_effectsObject, onCloseComplete);
		}
		else
		{
			_isCloseComplete = true;
		}
		
		if (_effectsSet != null && _effectsSet.closeModalBG != null && _modalBG != null)
		{
			_effectsSet.closeModalBG.showEffect(_modalBG, onCloseModalBGComplete);
		}
		else
		{
			_isCloseModalBGComplete = true;
		}
		
		check();
	}
	
	private var _isCloseComplete:Boolean = false;
	
	private function onCloseComplete():void
	{
		_isCloseComplete = true;
		if (_effectsSet != null && _effectsSet.close != null)
		{
			_effectsSet.close.restoreNormal();
		}
		removeEffectsObject();
		check();
	}
	
	private var _isCloseModalBGComplete:Boolean = false;
	
	private function onCloseModalBGComplete():void
	{
		_isCloseModalBGComplete = true;
		check();
	}
	
	private function check():void
	{
		if (_isCloseComplete && _isCloseModalBGComplete)
		{
			// в начале удалить привязку _executorByPopUp[_popUp];
			// т.к. этот же PopUp может в этом же обработчике появиться обновлёным
			dispose();
			
			if (_closeCallback != null)
			{
				_closeCallback(this);
			}
		}
	}
	
	private var _effectsObject:Sprite3D;
	
	private function makeEffectsObject():void
	{
		if (_popUp is ISnapshotable)
		{
			// на случай, если на форме присутствуют картинки которые
			// политика безопасности запрещает отрисовывать на BitmapData
			/*
			try
			{
				_effectsObject = (_popUp as ISnapshotable).snapshot;
			}
			catch (e:Error)
			{
				_effectsObject = _popUp;
			}
			*/
			if (_effectsObject !== _popUp)
			{
				var index:int = _contentLayer.getChildIndex(_popUp);
				_contentLayer.addChildAt(_effectsObject, index);
				_popUp.visible = false;
			}
		}
		else
		{
			_effectsObject = _popUp;
		}
	}
	
	private function removeEffectsObject():void
	{
		if (_popUp is ISnapshotable)
		{
			if (_effectsObject != null && _popUp !== _effectsObject)
			{
				if ( _contentLayer.contains(_effectsObject) )
				{
					_contentLayer.removeChild(_effectsObject);
				}
				_popUp.visible = true;
			}
		}
		_effectsObject = null;
	}
	
	public function dispose():void
	{
		delete _executorByPopUp[_popUp];
	}
}