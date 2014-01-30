package molehill.core.texture
{

	public class FontTextureData extends TextureAtlasData
	{
		public static function fromRawData(rawData:Object):FontTextureData
		{
			var atlasData:FontTextureData = new FontTextureData(rawData.width, rawData.height);
			
			var texturesInfo:Object = rawData.info;
			var fontName:String = rawData.fontName;
			atlasData._fontName = fontName;
			for (var size:String in rawData.info)
			{
				var glyphTextures:Object = rawData.info[size];
				atlasData._listSizes.push(int(size));
				for (var glyphCode:String in glyphTextures)
				{
					var textureID:String = fontName + "_" + size + "_" + glyphCode;
					atlasData.addTextureDesc(
						textureID,
						glyphTextures[glyphCode].left,
						glyphTextures[glyphCode].top,
						glyphTextures[glyphCode].width,
						glyphTextures[glyphCode].height
					);
					if (atlasData._listGlyphCodes.indexOf(int(glyphCode)) == -1)
					{
						atlasData._listGlyphCodes.push(int(glyphCode));
					}
				}
			}
			
			return atlasData;
		}
		
		public function FontTextureData(atlasWidth:uint, atlasHeight:uint)
		{
			super(atlasWidth, atlasHeight);
			
			_listSizes = new Array();
			_listGlyphCodes = new Array();
		}
		
		private var _fontName:String;
		public function get fontName():String
		{
			return _fontName;
		}
		
		private var _listSizes:Array;
		public function get listSizes():Array
		{
			return _listSizes;
		}
		
		private var _listGlyphCodes:Array;
		public function get listGlyphCodes():Array
		{
			return _listGlyphCodes;
		}
		
	}
}