package molehill.core.texture
{
	import flash.utils.ByteArray;
	
	import molehill.core.animation.CustomAnimationManager;

	public class ARFTextureData
	{
		protected var _rawATFData:ByteArray;
		private var _rawSpriteAnimationData:Object;
		private var _atfFormatOffset:int = 0;
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
						chunkData.position = 6;
						
						if (chunkData.readUnsignedByte() == 0xFF)
						{
							_atfFormatOffset = 6;
							
							chunkData.position = 0;
							rawData.position += 2;
							chunkSize = 0x1000000 * rawData.readUnsignedByte() + 0x10000 * rawData.readUnsignedByte() + 0x100 * rawData.readUnsignedByte() + rawData.readUnsignedByte();
							chunkData.writeBytes(rawData, rawData.position - 12, chunkSize + 12);
						}
						
						_rawATFData = chunkData;
						break;
					
					case 'TAD': // Texture Atlas Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_textureAtlasData = TextureAtlasData.fromRawData(chunkData.readObject());
						break;
					
					case 'NA_': // Normalized Alpha Channel with LZMA compression
					case 'NAC': // Normalized Alpha Channel
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						
						if (header == 'NA_')
						{
							chunkData.uncompress('lzma');
						}
						
						_textureAtlasData.addNormalizedAplhaData(chunkData);
						break;
					
					case 'SAD': // Sprite Animation Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_rawSpriteAnimationData = chunkData.readObject();
						break;
					
					case 'SAP': // Sprite Animation Package
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						CustomAnimationManager.getInstance().registerAnimations(chunkData);
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
			_rawATFData.position = 6 + _atfFormatOffset;
			var type:uint = _rawATFData.readUnsignedByte();
			
			return (type & 0xFF) >= 2;
		}
		
		public function get width():uint
		{
			_rawATFData.position = 7 + _atfFormatOffset;
			var log2Width:uint = _rawATFData.readUnsignedByte();
			return Math.pow(2, log2Width);
		}
		
		public function get height():uint
		{
			_rawATFData.position = 8 + _atfFormatOffset;
			var log2Height:uint = _rawATFData.readUnsignedByte();
			return Math.pow(2, log2Height);
		}
		
		public function get numTextures():uint
		{
			_rawATFData.position = 9 + _atfFormatOffset;
			return _rawATFData.readUnsignedByte();
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