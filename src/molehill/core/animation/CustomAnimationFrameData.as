package molehill.core.animation
{
	public class CustomAnimationFrameData
	{
		public function CustomAnimationFrameData(textureName:String, repeatCount:int = 1)
		{
			_textureName = textureName;
			_repeatCount = repeatCount;
		}
		
		private var _textureName:String;
		public function get textureName():String
		{
			return _textureName;
		}
		
		public function set textureName(value:String):void
		{
			_textureName = value;
		}
		
		private var _repeatCount:int = 1;
		public function get repeatCount():int
		{
			return _repeatCount;
		}
		
		public function set repeatCount(value:int):void
		{
			_repeatCount = value;
		}
	}
}