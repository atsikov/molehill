package molehill.easy.ui3d.effects
{
	import flash.geom.Point;
	
	import molehill.easy.ui3d.WindowManager3D;

	public class HideToBottomLeftTweenEffect extends TweenCameraEffect
	{
		public function HideToBottomLeftTweenEffect()
		{
			super();
		}
		
		override protected function placeTarget():void
		{
			WindowManager3D.getInstance().alignToBottom(_target);
			WindowManager3D.getInstance().alignToLeft(_target);
		}
		
		override protected function get targetPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}