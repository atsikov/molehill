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
		
		override protected function get targetPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(-Math.round(windowContentRect.width / 2 + _target.width) - 200, 0);
		}
	}
}