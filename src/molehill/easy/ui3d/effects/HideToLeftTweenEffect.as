package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Back;
	import fl.motion.easing.Elastic;
	import fl.motion.easing.Quadratic;
	
	import flash.display.DisplayObject;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	
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
			if (target.camera == null)
			{
				target.camera = new CustomCamera();
			}
			
			target.camera.scrollX = startPosition.x;
			target.camera.scrollY = startPosition.y;
			
			var effectTime:Number = 0.3;
			_tween = OpenTween.go(
				target.camera,
				{
					scrollX: targetPosition.x,
					scrollY: targetPosition.y
				},
				effectTime,
				0,
				tweening,
				completeEffect
			);
		}
		
		protected function get startPosition():Point
		{
			return new Point(0, 0);
		}
		
		protected function get targetPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(Math.round(windowContentRect.width / 2 + _target.width) + 200, 0);
		}
		
		protected function get tweening():Function
		{
			return Quadratic.easeIn;
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
				_target.camera.scrollX = Math.round(_target.camera.scrollX);
				_target.camera.scrollY = Math.round(_target.camera.scrollY);
			}
			
			_target = null;
			_completeCallback = null;
		}
		
		override public function restoreNormal():void
		{
			_target.camera.scrollX = targetPosition.x;
			_target.camera.scrollY = targetPosition.y;
		}
	}
}