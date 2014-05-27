package molehill.core.events
{
	import flash.events.Event;
	
	public class Font3DManagerEvent extends Event
	{
		/**
		 * @eventType fontReady
		 **/
		public static const FONT_READY:String = "fontReady";
		/**
		 * @eventType fontLoadError
		 **/
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