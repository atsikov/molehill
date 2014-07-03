package molehill.easy.ui3d.effects.top
{
	import flash.geom.Point;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	import molehill.easy.ui3d.effects.TweenCameraEffect;
	
	public class HideToTopCenterEffect extends TweenCameraEffect
	{
		public function HideToTopCenterEffect()
		{
			super();
		}
		
		override public function placeTarget(customTarget:Sprite3D = null):void
		{
			var target:Sprite3D = customTarget == null ? _target : customTarget;
			WindowManager3D.getInstance().centerPopUp(target);
			WindowManager3D.getInstance().alignToTop(target);
		}
		
		override protected function get targetPosition():Point
		{
			return new Point(0, _target.height + 100);
		}
	}
}