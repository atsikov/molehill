package molehill.easy.ui3d.effects
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import molehill.core.sprite.Sprite3D;

	public class Effect
	{
		protected var _timer:Timer;
		
		public function Effect()
		{
			_timer = new Timer(40);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
		}
		
		public static var cacheAsBitmap:Boolean = true;
		
		protected var _target:Sprite3D;
		protected var _completeCallback:Function;
		
		public function showEffect(target:Sprite3D, completeCallback:Function = null):void
		{
			_target = target;
			_completeCallback = completeCallback;
			
			_timer.start();
			_target.visible = true;
			onTimer(null);
		}
		
		public function restoreNormal():void
		{
			
		}
		
		protected function completeEffect():void
		{
			if (_completeCallback != null)
			{
				_completeCallback();
			}
			
			_target = null;
			_completeCallback = null;
			_timer.stop();
		}
		
		protected function onTimer(event:Event):void
		{
			
		}
		
		public function clone():Effect
		{
			return new Effect();
		}
	}
}