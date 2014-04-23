package molehill.easy.ui3d.effects
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.easy.ui3d.WindowManager3D;
	
	public class HideToRightTweenEffect extends HideToLeftTweenEffect
	{
		public function HideToRightTweenEffect()
		{
			super();
		}
		
		override protected function get startPosition():Point
		{
			return new Point(1, 1);
		}
		
		override protected function get targetPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(Math.round(windowContentRect.width) + 200, Math.round((windowContentRect.height - _target.height) / 2 * startPosition.y));
		}
	}
}