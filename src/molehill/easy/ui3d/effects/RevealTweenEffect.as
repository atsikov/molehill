package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Quadratic;
	import fl.motion.easing.Quartic;
	
	import flash.display.DisplayObject;
	
	import molehill.core.render.Sprite3D;
	
	import org.opentween.OpenTween;
	
	public class RevealTweenEffect extends Effect
	{
		private var _sourceAlpha:Number = 1;
		override public function showEffect(target:Sprite3D, completeCallback:Function = null):void
		{
			_sourceAlpha = target.alpha;
			
			super.showEffect(target, completeCallback);
			_timer.stop();
			
			_target.alpha = 0.01;
			
			OpenTween.go(
				_target,
				{
					alpha: _sourceAlpha
				},
				0.3,
				0,
				Quadratic.easeOut,
				completeEffect
			);
		}
		
		override public function restoreNormal():void
		{
			_target.alpha = _sourceAlpha;
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
			return new RevealTweenEffect();
		}
	}
}