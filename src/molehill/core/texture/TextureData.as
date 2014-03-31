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
			
			_croppedWidth = width;
			_croppedHeight = height;
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

		private var _croppedWidth:uint;
		public function get croppedWidth():uint
		{
			return _croppedWidth;
		}
		
		public function set croppedWidth(value:uint):void
		{
			_croppedWidth = value;
		}
		
		private var _croppedHeight:uint;
		public function get croppedHeight():uint
		{
			return _croppedHeight;
		}
		
		public function set croppedHeight(value:uint):void
		{
			_croppedHeight = value;
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
				_textureRegion = new Rectangle(_left, _top, _croppedWidth, _croppedHeight);
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
		
		/**
		 * Updating width and height parameters for cropped texture. Previous <b>width</b> and </b>height</b> values will be copied to <b>croppedWidth</b> and <b>croppedHeight</b>, new values will replace existing.
		 * 
		 * @param offsetX Width of blank field in the left part of cropped texture 
		 * @param offsetY Height of blank field in the top part of cropped texture 
		 * @param width Width of the texture including blank fields 
		 * @param height Height of the texture including blank fields 
		 **/
		public function setBlankRectValues(offsetX:int, offsetY:int, width:int, height:int):void
		{
			_blankOffsetX = offsetX;
			_blankOffsetY = offsetY;
			
			_croppedWidth = _width;
			_croppedHeight = _height;
			
			_width = width;
			_height = height;
			
			_textureRegion = null;
		}
	}
}