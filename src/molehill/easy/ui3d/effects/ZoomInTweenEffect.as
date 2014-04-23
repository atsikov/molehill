package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Elastic;
	import fl.motion.easing.Quadratic;
	import fl.motion.easing.Quartic;
	
	import flash.display.DisplayObject;
	
	import molehill.core.sprite.Sprite3D;
	
	import org.opentween.OpenTween;

	public class ZoomInTweenEffect extends Effect
	{
		private var _srcCenterX:Number;
		private var _srcCenterY:Number;
		private var _srcWidth:Number;
		private var _srcHeight:Number;
		
		override public function showEffect(target:Sprite3D, completeCallback:Function = null):void
		{
			super.showEffect(target, completeCallback);
			_timer.stop();
			
			target.scaleX = 0.0;
			target.scaleY = 0.0;
			
			_target.alpha = 1;
			
			_srcWidth = target.width;
			_srcHeight = target.height;
			_srcCenterX = target.x + _srcWidth / 2;
			_srcCenterY = target.y + _srcHeight / 2;
			
			OpenTween.go(
				_target,
				{
					scaleX: 1,
					scaleY: 1
				},
				0.3,
				0,
				Quadratic.easeOut,
				completeEffect,
				onTweenUpdate
			);
		}
		
		private function onTweenUpdate():void
		{
			_target.x = _srcCenterX - _target.width * _target.scaleX / 2;
			_target.y = _srcCenterY - _target.height * _target.scaleY / 2;
		}
		
		override public function restoreNormal():void
		{
			_target.scaleX = 1;
			_target.scaleY = 1;
			
			_target.x = _srcCenterX - _target.width / 2;
			_target.y = _srcCenterY - _target.height / 2;
			
			_target.alpha = 1;
		}
		
		override protected function completeEffect():void
		{
			if (_completeCallback != null)
			{
				_completeCallback();
			}
			
			if (_target != null)
			{
				_target.cacheAsBitmap = _targetCacheAsBitmap;
			}
			
			_target = null;
			_completeCallback = null;
		}
		
		override public function clone():Effect
		{
			return new ZoomInTweenEffect();
		}
	}
}