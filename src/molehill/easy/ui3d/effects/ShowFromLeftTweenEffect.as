package molehill.easy.ui3d.effects
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	
	public class ShowFromLeftTweenEffect extends TweenCameraEffect
	{
		public function ShowFromLeftTweenEffect()
		{
			super();
		}
		
		override protected function get startPosition():Point
		{
			var windowContentRect:Rectangle = WindowManager3D.getInstance().contentRegion;
			return new Point(Math.round(windowContentRect.width / 2 + _target.width) + 200, 0);
		}
	}
}