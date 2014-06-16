package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Quadratic;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.easy.ui3d.WindowManager3D;
	
	public class HideToRightTweenEffect extends TweenCameraEffect
	{
		public function HideToRightTweenEffect()
		{
			super();
		}
		
		override protected function get tweening():Function
		{
			return Quadratic.easeIn;
		}
		
		override protected function get startPosition():Point
		{
			return new Point(0, 0);
		}
		
		override protected function get targetPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(-Math.round(windowContentRect.width / 2 + _target.width) - 200, 0);
		}
	}
}