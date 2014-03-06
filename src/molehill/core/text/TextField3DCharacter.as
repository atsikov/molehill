package molehill.core.text
{
	import flash.geom.Rectangle;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;
	
	internal class TextField3DCharacter extends Sprite3D
	{
		public function TextField3DCharacter()
		{
			super();
		}
		
		override protected function updateParent():void
		{
			
		}
		
		internal var _silentChange:Boolean = false;
		override molehill_internal function set hasChanged(value:Boolean):void
		{
			if (_silentChange)
			{
				return;
			}
			
			super.hasChanged = value;
		}
	}
}