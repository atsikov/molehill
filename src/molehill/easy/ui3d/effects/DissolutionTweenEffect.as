package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Quadratic;
	
	import flash.display.DisplayObject;
	
	import molehill.core.sprite.Sprite3D;
	
	import org.opentween.OpenTween;

	public class DissolutionTweenEffect extends Effect
	{
		private var _originalAlpha:Number = 1;
		override public function showEffect(target:Sprite3D, completeCallback:Function = null):void
		{
			super.showEffect(target, completeCallback);
			_timer.stop();
			
			_originalAlpha = target.alpha;
			
			OpenTween.go(
				_target,
				{
					alpha: 0
				},
				0.3,
				0,
				Quadratic.easeOut,
				completeEffect
			);
		}
		
		override public function restoreNormal():void
		{
			_target.alpha = _originalAlpha;
		}
		
		override protected function completeEffect():void
		{
			if (_completeCallback != null)
			{
				_completeCallback();
			}
			
			_target = null;
			_completeCallback = null;
		}
		
		override public function clone():Effect
		{
			return new DissolutionTweenEffect();
		}
	}
}