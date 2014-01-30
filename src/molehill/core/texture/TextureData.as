package molehill.core.texture
{
	import flash.geom.Rectangle;

	public class TextureData
	{
		private var _textureID:String;
		private var _left:uint;
		private var _top:uint;
		private var _width:uint;
		private var _height:uint;
		private var _spriteSheetData:SpriteSheetData;
		public function TextureData(
			textureID:String,
			left:uint,
			top:uint,
			width:uint,
			height:uint,
			spriteSheetData:SpriteSheetData = null
		)
		{
			_textureID = textureID;
			_left = left;
			_top = top;
			_width = width;
			_height = height;
			_spriteSheetData = spriteSheetData;
		}

		public function get textureID():String
		{
			return _textureID;
		}

		internal function rename(value:String):void
		{
			_textureID = value;
		}
		
		public function get left():uint
		{
			return _left;
		}

		public function get top():uint
		{
			return _top;
		}

		public function get width():uint
		{
			return _width;
		}

		public function get height():uint
		{
			return _height;
		}

		public function get spriteSheetData():SpriteSheetData
		{
			return _spriteSheetData;
		}

		public function set spriteSheetData(value:SpriteSheetData):void
		{
			_spriteSheetData = value;
		}
		
		private var _textureRegion:Rectangle;
		public function get textureRect():Rectangle
		{
			if (_textureRegion == null)
			{
				_textureRegion = new Rectangle(left, top, width, height);
			}
			
			return _textureRegion;
		}
		
		private var _normalizedAlphaChannel:NormalizedAlphaChannel;
		public function getNormalizedAlpha():NormalizedAlphaChannel
		{
			return _normalizedAlphaChannel;
		}
		
		public function setNormalizedAlpha(value:NormalizedAlphaChannel):void
		{
			_normalizedAlphaChannel = value;
		}
	}
}