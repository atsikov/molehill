package molehill.easy.ui3d.effects
{
	import fl.motion.easing.Bounce;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.easy.ui3d.WindowManager3D;

	public class ShowFromBottomLeftTweenEffect extends TweenCameraEffect
	{
		public function ShowFromBottomLeftTweenEffect()
		{
			super();
		}
		
		override protected function get tweening():Function
		{
			return Bounce.easeOut;
		}
		
		override protected function placeTarget():void
		{
			WindowManager3D.getInstance().alignToBottom(_target);
			WindowManager3D.getInstance().alignToLeft(_target);
		}
		
		override protected function get startPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}