package molehill.core.texture
{
	import flash.utils.ByteArray;

	public class ARFTextureData
	{
		protected var _rawATFData:ByteArray;
		private var _rawSpriteAnimationData:Object;
		public function ARFTextureData(rawData:ByteArray, textureID:String = null)
		{
			rawData.position = 0;
			
			while (rawData.bytesAvailable)
			{
				var header:String = rawData.readUTFBytes(3);
				var chunkSize:int = 0x10000 * rawData.readUnsignedByte() + 0x100 * rawData.readUnsignedByte() + rawData.readUnsignedByte();
				var chunkData:ByteArray = new ByteArray();
				switch (header)
				{
					case 'ATF': // Adobe Texture Format
						chunkData.writeBytes(rawData, rawData.position - 6, chunkSize + 6);
						_rawATFData = chunkData;
						break;
					
					case 'TAD': // Texture Atlas Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_textureAtlasData = TextureAtlasData.fromRawData(chunkData.readObject());
						break;
					
					case 'NAC': // Normalized Alpha Channel
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_textureAtlasData.addNormalizedAplhaData(chunkData);
						break;
					
					case 'SAD': // Sprite Animation Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_rawSpriteAnimationData = chunkData.readObject();
						break;
				}
				rawData.position += chunkSize;
			}
			
			if (_textureAtlasData == null)
			{
				_textureAtlasData = new TextureAtlasData(width, height);
				_textureAtlasData.addTextureDesc(textureID, 0, 0, width, height);
			}
		}

		public function get rawATFData():ByteArray
		{
			return _rawATFData;
		}
		
		public function isCompressed():Boolean
		{
			_rawATFData.position = 6;
			var type:int = _rawATFData.readByte();
			
			return (type & 2) != 0;
		}
		
		public function get width():uint
		{
			_rawATFData.position = 7;
			var log2Width:uint = _rawATFData.readByte();
			return Math.pow(2, log2Width);
		}
		
		public function get height():uint
		{
			_rawATFData.position = 8;
			var log2Height:uint = _rawATFData.readByte();
			return Math.pow(2, log2Height);
		}
		
		public function get numTextures():uint
		{
			_rawATFData.position = 9;
			return _rawATFData.readByte();
		}
		
		protected var _textureAtlasData:TextureAtlasData;
		public function get textureAtlasData():TextureAtlasData
		{
			return _textureAtlasData;
		}
		
		public function get rawSpriteAnimationData():Object
		{
			return _rawSpriteAnimationData;
		}
	}
}