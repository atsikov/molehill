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
			
			updateOnRender = true;
			snapToPixels = true;
		}
		
		override public function toString():String
		{
			var value:String = super.toString();
			var charCode:int = textureID == null ? 0 : int(textureID.substr(textureID.lastIndexOf('_') + 1));
			value += "; character == " + String.fromCharCode(charCode);
			
			return value;
		}
	}
}