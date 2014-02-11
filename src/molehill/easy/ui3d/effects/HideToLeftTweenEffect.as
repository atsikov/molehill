package molehill.easy.ui3d.effects
{
	import easy.ui.WindowManager;
	
	import fl.motion.easing.Back;
	import fl.motion.easing.Elastic;
	import fl.motion.easing.Quadratic;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	
	import org.goasap.interfaces.IPlayable;
	import org.opentween.OpenTween;
	
	public class HideToLeftTweenEffect extends Effect
	{
		public function HideToLeftTweenEffect()
		{
			super();
		}
		
		private var _tweenTarget:Object;
		private var _tween:IPlayable;
		override public function showEffect(target:Sprite3D, completeCallback:Function = null):void
		{
			super.showEffect(target, completeCallback);
			_timer.stop();
			
			_tweenTarget = new Object();
			_tweenTarget.x = 0;
			_tweenTarget.y = 1;
			
			target.alpha = 1;
			target.scaleX = 1;
			target.scaleY = 1;
			
			var effectTime:Number = 0.2;
			_tween = OpenTween.go(
				_tweenTarget,
				{
					x: 1,
					y: 1
				},
				effectTime,
				0,
				tweening,
				completeEffect,
				onTweenUpdate
			);
			
			onTweenUpdate();
		}
		
		protected function get startPosition():Point
		{
			return new Point(1, 1);
		}
		
		protected function get targetPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager.getInstance().contentRegion;
			return new Point(Math.round(-_target.width) - 200, Math.round((windowContentRect.height - _target.height) / 2 * startPosition.y));
		}
		
		protected function get tweening():Function
		{
			return Quadratic.easeIn;
		}
		
		private function onTweenUpdate():void
		{
			if (_target == null)
				return;
			
			var startPos:Point = startPosition;
			var targetPos:Point = targetPosition;
			
			var windowContentRect:Rectangle = WindowManager.getInstance().contentRegion;
			
			_target.x = targetPos.x + Math.round(((windowContentRect.width - _target.width) / 2 * startPos.x - targetPos.x) * (1 - _tweenTarget.x));
			_target.y = targetPos.y + Math.round(((windowContentRect.height - _target.height) / 2 * startPos.y - targetPos.y) * (1 - _tweenTarget.y));
		}
		
		override protected function completeEffect():void
		{
			if (_tween != null)
			{
				_tween.stop();
				_tween = null;
			}
			
			if (_completeCallback != null)
			{
				_completeCallback();
			}
			
			if (_target != null)
			{
				_target.x = Math.round(_target.x);
				_target.y = Math.round(_target.y);
			}
			
			_target = null;
			_completeCallback = null;
		}
		
		override public function restoreNormal():void
		{
/*			_tweenTarget.x = 1;
			_tweenTarget.y = 1;
			onTweenUpdate();*/
		}
	}
}