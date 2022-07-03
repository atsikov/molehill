package atlas_compositor.config
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	
	public class TextureBitmapData extends BitmapData
	{
		public function TextureBitmapData(width:int, height:int, transparent:Boolean = false, fillColor:uint = 0xFFFFFFFF)
		{
			super(width, height, transparent, fillColor);
		}
		
		private var _textureID:String;
		public function get textureID():String
		{
			return _textureID;
		}
		
		public function set textureID(value:String):void
		{
			_textureID = value;
		}

		
	}
}