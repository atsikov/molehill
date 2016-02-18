package molehill.core.animation
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.CustomAnimatedSprite3D;
	
	use namespace molehill_internal;

	public class SpriteAnimationUpdater
	{
		private static var _instance:SpriteAnimationUpdater
		public static function getInstance():SpriteAnimationUpdater
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new SpriteAnimationUpdater();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		private var _timePerFrame:int;
		public function SpriteAnimationUpdater()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use SpriteAnimationUpdater::getInstance()");
			}
			
			_timePerFrame = 1000 / _fps;
		}
		
		private var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}

		public function set enabled(value:Boolean):void
		{
			_enabled = value;
		}

		
		private var _fps:Number = 24;
		public function get fps():Number
		{
			return _fps;
		}
		
		/**
		 *  FPS is limited to 60
		 **/
		public function set fps(value:Number):void
		{
			if (value > 60)
			{
				value = 60;
			}
			
			_fps = value;
			_timePerFrame = 1000 / _fps;
		}
		
		private var _listAnimations:Vector.<AnimatedSprite3D> = new Vector.<AnimatedSprite3D>();
		private var _listCustomAnimations:Vector.<CustomAnimatedSprite3D> = new Vector.<CustomAnimatedSprite3D>();
		molehill_internal function addAnimation(value:AnimatedSprite3D):void
		{
			if (_listAnimations.indexOf(value) != -1 || _listCustomAnimations.indexOf(value as CustomAnimatedSprite3D) != -1)
			{
				return;
			}
			
			if (value is CustomAnimatedSprite3D)
			{
				_listCustomAnimations.push(value);
			}
			else
			{
				_listAnimations.push(value);
			}
			
			startUpdates();
		}
		
		molehill_internal function hasAnimation(value:AnimatedSprite3D):Boolean
		{
			return _listAnimations.indexOf(value) != -1 || _listCustomAnimations.indexOf(value as CustomAnimatedSprite3D) != -1;
		}
		
		molehill_internal function removeAnimation(value:AnimatedSprite3D):void
		{
			if (_listAnimations.indexOf(value) == -1 || _listCustomAnimations.indexOf(value as CustomAnimatedSprite3D) == -1)
			{
				return;
			}
			
			if (value is CustomAnimatedSprite3D)
			{
				_listCustomAnimations.splice(_listCustomAnimations.indexOf(value as CustomAnimatedSprite3D), 1);
			}
			else
			{
				_listAnimations.splice(_listAnimations.indexOf(value), 1);
			}
			
			if (_listAnimations.length == 0 && _listCustomAnimations.length == 0)
			{
				stopUpdates();
			}
		}
		
		private var _enterFrameListener:Sprite;
		private function startUpdates():void
		{
			if (_enterFrameListener == null)
			{
				_enterFrameListener = new Sprite();
			}
			
			if (!_enterFrameListener.hasEventListener(Event.ENTER_FRAME))
			{
				_enterFrameListener.addEventListener(Event.ENTER_FRAME, onTimerEvent);
			}
		}
		
		private function stopUpdates():void
		{
			_enterFrameListener.removeEventListener(Event.ENTER_FRAME, onTimerEvent);
		}
		
		private var _dropFrames:Boolean = false;
		public function get dropFrames():Boolean
		{
			return _dropFrames;
		}

		public function set dropFrames(value:Boolean):void
		{
			_dropFrames = value;
		}

		
		private var _lastTimerValue:uint = 0;
		private var _timerRemainedValue:uint = 0;
		private function update():void
		{
			if (!_enabled)
			{
				return;
			}
			
			_timerRemainedValue += getTimer() - _lastTimerValue;
			var frameSwitched:Boolean = false;
			while (_timePerFrame > 0 && _timerRemainedValue > _timePerFrame)
			{
				if (_dropFrames || !frameSwitched)
				{
					for each (var animation:AnimatedSprite3D in _listAnimations)
					{
						if (!animation.isOnScreen)
						{
							continue;
						}
						
						animation.nextFrame();
						frameSwitched = true;
					}
				}
				
				_timerRemainedValue -= _timePerFrame;
			}
			
			for each (animation in _listCustomAnimations)
			{
				if (animation.scene == null || !animation.scene.isActive)
				{
					continue;
				}
				
				if (!animation.isOnScreen)
				{
					continue;
				}
				
				animation.nextFrame();
			}
			
			_lastTimerValue = getTimer();
		}
		
		private function onTimerEvent(event:Event):void
		{
			update();
		}
	}
}