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
			
			_originalWidth = width;
			_originalHeight = height;
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

		private var _originalWidth:uint;
		public function get originalWidth():uint
		{
			return _originalWidth;
		}
		
		public function set originalWidth(value:uint):void
		{
			_originalWidth = value;
		}
		
		private var _originalHeight:uint;
		public function get originalHeight():uint
		{
			return _originalHeight;
		}
		
		public function set originalHeight(value:uint):void
		{
			_originalHeight = value;
		}
		
		private var _blankOffsetX:uint;
		public function get blankOffsetX():uint
		{
			return _blankOffsetX;
		}

		public function set blankOffsetX(value:uint):void
		{
			_blankOffsetX = value;
		}

		private var _blankOffsetY:uint;
		public function get blankOffsetY():uint
		{
			return _blankOffsetY;
		}

		public function set blankOffsetY(value:uint):void
		{
			_blankOffsetY = value;
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