package molehill.core.texture
{
	import flash.geom.Rectangle;

	public class TextureAtlasDataNode
	{
		internal var child:Vector.<TextureAtlasDataNode>;
		internal var rc:Rectangle;
		internal var textureID:String = "";
	}
}