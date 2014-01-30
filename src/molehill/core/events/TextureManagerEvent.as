package molehill.core.events
{
	import flash.events.Event;
	
	public class TextureManagerEvent extends Event
	{
		public static const TEXTURE_READY:String = "textureReady";
		
		private var _textureID:String
		public function TextureManagerEvent(type:String, textureID:String = "")
		{
			_textureID = textureID;
			super(type);
		}
		
		public function get textureID():String
		{
			return _textureID;
		}
	}
}