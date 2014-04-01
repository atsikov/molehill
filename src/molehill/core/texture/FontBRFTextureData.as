package molehill.core.texture
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.utils.ByteArray;

	public class FontBRFTextureData extends TextureAtlasBitmapData
	{
		public function FontBRFTextureData(bitmapData:BitmapData, fontTextureData:FontTextureData)
		{
			super(bitmapData.width, bitmapData.height);
			copyPixels(bitmapData, bitmapData.rect, new Point());
			
			_atlasData = fontTextureData;
		}
		
		override public function insert(bitmapData:BitmapData, textureID:String, textureGap:int = 1, nextNode:TextureAtlasDataNode = null):TextureAtlasDataNode
		{
			return null;
		}
	}
}