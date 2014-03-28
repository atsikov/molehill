package molehill.core.sprite
{
	public class CustomAnimationFrameData
	{
		public function CustomAnimationFrameData(textureName:String, repeatCount:int)
		{
			_textureName = textureName;
			_repeatCount = repeatCount;
		}
		
		private var _textureName:String;
		public function get textureName():String
		{
			return _textureName;
		}
		
		private var _repeatCount:int = 1;
		public function get repeatCount():int
		{
			return _repeatCount;
		}
	}
}