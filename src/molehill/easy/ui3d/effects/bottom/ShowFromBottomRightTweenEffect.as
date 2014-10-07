package molehill.easy.ui3d.effects.bottom
{
	import flash.geom.Point;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	import molehill.easy.ui3d.effects.TweenCameraEffect;
	
	public class ShowFromBottomRightTweenEffect extends TweenCameraEffect
	{
		public function ShowFromBottomRightTweenEffect()
		{
			super();
		}
		
		override public function placeTarget(customTarget:Sprite3D = null):void
		{
			var target:Sprite3D = customTarget == null ? _target : customTarget;
			WindowManager3D.getInstance().alignToBottom(target);
			WindowManager3D.getInstance().alignToRight(target);
		}
		
		override protected function get startPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}