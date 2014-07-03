package molehill.easy.ui3d.effects.bottom
{
	import fl.motion.easing.Linear;
	
	import flash.geom.Point;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.easy.ui3d.WindowManager3D;
	import molehill.easy.ui3d.effects.TweenCameraEffect;

	public class ShowFromBottomCenterEffect extends TweenCameraEffect
	{
		public function ShowFromBottomCenterEffect()
		{
			super();
		}
		
		override protected function get tweening():Function
		{
			return Linear.easeOut;
		}
		
		override protected function get effectTime():Number
		{
			return 0.2;
		}
		
		override public function placeTarget(customTarget:Sprite3D = null):void
		{
			var target:Sprite3D = customTarget == null ? _target : customTarget;
			WindowManager3D.getInstance().centerPopUp(target);
			WindowManager3D.getInstance().alignToBottom(target);
		}
		
		override protected function get startPosition():Point
		{
			return new Point(0, -_target.height - 100);
		}
	}
}