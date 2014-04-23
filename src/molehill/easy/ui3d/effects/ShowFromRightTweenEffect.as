package molehill.easy.ui3d.effects
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.easy.ui3d.WindowManager3D;
	
	public class ShowFromRightTweenEffect extends ShowFromLeftTweenEffect
	{
		public function ShowFromRightTweenEffect()
		{
			super();
		}
		
		override protected function get startPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(Math.round(windowContentRect.width) + 200, Math.round((windowContentRect.height - _target.height) / 2 * targetPosition.y));
		}
	}
}