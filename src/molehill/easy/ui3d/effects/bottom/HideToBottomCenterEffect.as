package molehill.easy.ui3d.effects.bottom
{
	import flash.geom.Point;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	import molehill.easy.ui3d.effects.TweenCameraEffect;

	public class HideToBottomCenterEffect extends TweenCameraEffect
	{
		public function HideToBottomCenterEffect()
		{
			super();
		}
		
		override public function placeTarget(customTarget:Sprite3D = null):void
		{
			var target:Sprite3D = customTarget == null ? _target : customTarget;
			WindowManager3D.getInstance().centerPopUp(target);
			WindowManager3D.getInstance().alignToBottom(target);
		}
		
		override protected function get targetPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}