package molehill.easy.ui3d.effects
{
	import easy.ui.WindowManager;
	
	import fl.motion.easing.Back;
	import fl.motion.easing.Elastic;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	
	import org.goasap.interfaces.IPlayable;
	import org.opentween.OpenTween;
	
	public class ShowFromLeftTweenEffect extends Effect
	{
		public function ShowFromLeftTweenEffect()
		{
			super();
		}
		
		private var _tween:IPlayable;
		private var _tweenTarget:Object;
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
			
			var effectTime:Number = 0.4;
			_tween = OpenTween.go(
				_tweenTarget,
				{
					x: targetPosition.x,
					y: targetPosition.y
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
			var windowContentRect:Rectangle = WindowManager.getInstance().contentRegion;
			return new Point(Math.round(-_target.width) - 200, Math.round((windowContentRect.height - _target.height) / 2 * targetPosition.y));
		}
		
		protected function get targetPosition():Point
		{
			return new Point(1, 1);
		}
		
		protected function get tweening():Function
		{
			return Back.easeOut;
		}
		
		private function onTweenUpdate():void
		{
			if (_target == null)
				return;
			
			var startPos:Point = startPosition;
			var targetPos:Point = targetPosition;
			
			var windowContentRect:Rectangle = WindowManager.getInstance().contentRegion;
			
			_target.x = startPos.x + Math.round(((windowContentRect.width - _target.width) / 2 * targetPos.x - startPos.x) * _tweenTarget.x);
			_target.y = startPos.y + Math.round(((windowContentRect.height - _target.height) / 2 * targetPos.y - startPos.y) * _tweenTarget.y);
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
			_tweenTarget.x = targetPosition.x;
			_tweenTarget.y = targetPosition.y;
			onTweenUpdate();
		}
	}
}