package model.events
{
	import flash.events.Event;
	
	public class TextureExplorerEvent extends Event
	{
		public static const TEXTURE_SELECTED:String = "textureSelected";
		
		private var _textureName:String;
		public function TextureExplorerEvent(type:String, textureName:String)
		{
			_textureName = textureName;
			super(type);
		}
		
		public function get textureName():String
		{
			return _textureName;
		}
	}
}