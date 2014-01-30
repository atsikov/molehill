package molehill.core.texture
{
	import flash.utils.ByteArray;

	public class NormalizedAlphaChannel
	{
		private var _rawData:ByteArray;
		private var _width:int = 0;
		private var _height:int = 0;
		public function NormalizedAlphaChannel(rawData:ByteArray)
		{
			_rawData = rawData;
			_rawData.position = 0;
			
			_width = _rawData.readUnsignedShort();
			_height = _rawData.readUnsignedShort();
		}
		
		public function hitTestPoint(x:int, y:int):Boolean
		{
			if (x < 0 || x >= _width || y < 0 || y >= _height)
			{
				return false;
			}
			
			var bytePosition:int = (y * _width + x - x % 8) / 8 + 4;
			var byteShift:int = 7 - x % 8;
			
			_rawData.position = bytePosition;
			var byte:int = _rawData.readUnsignedByte();
			
			return ((byte >> byteShift) & 1) > 0;
		}
		
		public function hitTestArea(x:int, y:int, areaRadius:int, skipCount:int):Boolean
		{
			var result:Boolean = false;
			
			var startX:int = x - areaRadius;
			var startY:int = y - areaRadius;
			var endX:int = x + areaRadius;
			var endY:int = y + areaRadius;			
			
			skipCount++;
			for (var j:int = startY; j < endY; j += skipCount)
			{
				for (var i:int = startX + j % skipCount; i < endX; i++)
				{
					result = hitTestPoint(i, j);
					
					if (result)
					{
						break;
					}
				}
				
				if (result)
				{
					break;
				}
			}
			
			return result;
		}
	}
}