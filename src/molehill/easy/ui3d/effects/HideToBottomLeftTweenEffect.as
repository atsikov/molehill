package molehill.easy.ui3d.effects
{
	import flash.geom.Point;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;

	public class HideToBottomLeftTweenEffect extends TweenCameraEffect
	{
		public function HideToBottomLeftTweenEffect()
		{
			super();
		}
		
		override public function placeTarget(customTarget:Sprite3D = null):void
		{
			var target:Sprite3D = customTarget == null ? _target : customTarget;
			WindowManager3D.getInstance().alignToBottom(target);
			WindowManager3D.getInstance().alignToLeft(target);
		}
		
		override protected function get targetPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}