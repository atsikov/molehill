package molehill.core.texture
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class FontBRFTextureData extends TextureAtlasBitmapData
	{
		public function FontBRFTextureData(bitmapData:BitmapData, fontTextureData:FontTextureData)
		{
			super(bitmapData.width, bitmapData.height);
			copyPixels(bitmapData, bitmapData.rect, new Point());
			
			_atlasData = fontTextureData;
			
			createAtlasSpaceMap();
		}
		
		private function createAtlasSpaceMap():void
		{
			var hashTexturesByCoords:Object = new Object();
			for each (var textureData:TextureData in _atlasData._hashTextures)
			{
				var textureRegion:Rectangle = textureData.textureRect;
				if (hashTexturesByCoords[textureRegion.left] == null)
				{
					hashTexturesByCoords[textureRegion.left] = new Object();
				}
				hashTexturesByCoords[textureRegion.left][textureRegion.top] = textureData;
			}
			
			var listTexturesByPosition:Array = new Array();
			for each (var hashTexturesByTop:Object in hashTexturesByCoords)
			{
				var row:Array = new Array();
				listTexturesByPosition.push(row);
				for each (textureData in hashTexturesByTop)
				{
					row.push(textureData);
				}
				row.sort(sortTexturesByY);
			}
			
			listTexturesByPosition.sort(sortTexturesByX);
			
			var firstTexture:TextureData = listTexturesByPosition[0][0];
			var gap:int = 0;
			var nearestTexture:TextureData = listTexturesByPosition[1][0];
			if (nearestTexture != null)
			{
				gap = nearestTexture.textureRect.left - firstTexture.textureRect.right;
			}
			else
			{
				nearestTexture = listTexturesByPosition[0][1];
				if (nearestTexture != null)
				{
					gap = nearestTexture.textureRect.top - firstTexture.textureRect.bottom;
				}
			}
		}
		
		private function sortTexturesByY(textureDataA:TextureData, textureDataB:TextureData):int
		{
			return textureDataA.textureRect.top - textureDataB.textureRect.top;
		}
		
		private function sortTexturesByX(listTexturesA:Array, listTexturesB:Array):int
		{
			return listTexturesA[0].textureRect.left - listTexturesB[0].textureRect.left;
		}
	}
}