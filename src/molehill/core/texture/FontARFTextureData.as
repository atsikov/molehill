package molehill.core.texture
{
	import flash.utils.ByteArray;
	
	public class FontARFTextureData extends ARFTextureData
	{
		public function FontARFTextureData(rawData:ByteArray)
		{
			super(rawData);
			
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
						_textureAtlasData = FontTextureData.fromRawData(chunkData.readObject());
						break;
				}
				rawData.position += chunkSize;
			}
		}
	}
}