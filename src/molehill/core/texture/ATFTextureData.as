package molehill.core.texture
{
	import flash.utils.ByteArray;

	public class ATFTextureData
	{
		private var _rawATFData:ByteArray;
		public function ATFTextureData(rawData:ByteArray)
		{
			_rawATFData = rawData;
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
	}
}