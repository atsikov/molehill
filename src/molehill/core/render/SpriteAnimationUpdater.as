package molehill.core.render
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.utils.getTimer;

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
		public function SpriteAnimationUpdater()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use SpriteAnimationUpdater::getInstance()");
			}
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
		internal function addAnimation(value:AnimatedSprite3D):void
		{
			if (_listAnimations.indexOf(value) != -1)
			{
				return;
			}
			
			_listAnimations.push(value);
			
			if (_listAnimations.length == 1)
			{
				startUpdates();
			}
		}
		
		internal function hasAnimation(value:AnimatedSprite3D):Boolean
		{
			return _listAnimations.indexOf(value) != -1;
		}
		
		internal function removeAnimation(value:AnimatedSprite3D):void
		{
			if (_listAnimations.indexOf(value) == -1)
			{
				return;
			}
			
			_listAnimations.splice(_listAnimations.indexOf(value), 1);
			
			if (_listAnimations.length == 0)
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
			
			_enterFrameListener.addEventListener(Event.ENTER_FRAME, onTimerEvent);
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
		private var _timePerFrame:int;
		private function update():void
		{
			if (!_enabled)
			{
				return;
			}
			
			_timerRemainedValue += getTimer() - _lastTimerValue;
			var frameSwitched:Boolean = false;
			while (_timerRemainedValue > _timePerFrame)
			{
				if (_dropFrames || !frameSwitched)
				{
					for each (var animation:AnimatedSprite3D in _listAnimations)
					{
						animation.nextFrame();
						frameSwitched = true;
					}
				}
				
				_timerRemainedValue -= _timePerFrame;
			}
			
			_lastTimerValue = getTimer();
		}
		
		private function onTimerEvent(event:Event):void
		{
			update();
		}
	}
}