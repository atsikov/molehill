package molehill.core.events
{
	import flash.events.Event;
	
	public class Font3DManagerEvent extends Event
	{
		public static const FONT_READY:String = "fontReady";
		public static const FONT_LOAD_ERROR:String = "fontLoadError";
		
		public function Font3DManagerEvent(type:String, fontName:String = "")
		{
			super(type);
			_fontName = fontName;
		}
		
		private var _fontName:String;
		public function get fontName():String
		{
			return _fontName;
		}
		
	}
}