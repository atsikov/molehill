package molehill.core.utils
{
	import flash.utils.ByteArray;
	
	import molehill.core.texture.ARFTextureData;
	import molehill.core.texture.BRFTextureData;

	public class TextureUtils
	{
		public static function createCompressedTexture(rawData:ByteArray):*
		{
			var result:*;
			rawData.position = 0;
			
			while (rawData.bytesAvailable && result == null)
			{
				var header:String = rawData.readUTFBytes(3);
				var chunkSize:int = 0x10000 * rawData.readUnsignedByte() + 0x100 * rawData.readUnsignedByte() + rawData.readUnsignedByte();
				var chunkData:ByteArray = new ByteArray();
				switch (header)
				{
					case 'ATF':
						result = new ARFTextureData(rawData);
						break;
					
					case 'IMG':
					case 'IAD':
						result = new BRFTextureData(rawData);
						break;
				}
			}
			
			return result;
		}
	}
}