package molehill.core.texture
{
	import flash.geom.Rectangle;

	public class SpriteSheetData
	{
		public static function fromRawData(rawData:Object):SpriteSheetData
		{
			if (rawData == null)
			{
				return null;
			}
			
			var spriteSheetData:SpriteSheetData = new SpriteSheetData(
				rawData['frameWidth'],
				rawData['frameHeight'],
				rawData['totalFrames'],
				rawData['framesPerRow'],
				rawData['listFramesInfo']
			);
			return spriteSheetData;
		}
		
		private var _frameWidth:int;
		private var _frameHeight:int;
		private var _totalFrames:int;
		private var _framesPerRow:int;
		private var _listFramesInfo:Array;
		public function SpriteSheetData(
			frameWidth:int,
			frameHeight:int,
			totalFrames:int,
			framesPerRow:int,
			listFramesInfo:Array,
			listFrameOffsets:Array = null
		)
		{
			_frameWidth = frameWidth;
			_frameHeight = frameHeight;
			_framesPerRow = framesPerRow;
			_totalFrames = totalFrames;
			_listFramesInfo = listFramesInfo;
		}
		
		public function get frameWidth():int
		{
			return _frameWidth;
		}
		
		public function get frameHeight():int
		{
			return _frameHeight;
		}
		
		public function get totalFrames():int
		{
			return _totalFrames;
		}
		
		public function get framesPerRow():int
		{
			return _framesPerRow;
		}
		
		public function get listFramesInfo():Array
		{
			return _listFramesInfo;
		}
		
		private var _frameRectangle:Rectangle;
		public function getFrameRectangle(frame:int):Rectangle
		{
			if (_frameRectangle == null)
			{
				_frameRectangle = new Rectangle(0, 0, _frameWidth, _frameHeight);
			}
			else
			{
				_frameRectangle.x = 0;
				_frameRectangle.y = 0;
				_frameRectangle.width = _frameWidth;
				_frameRectangle.height = _frameHeight;
			}
			/*
			if (frame == 1 && _listFramesInfo[1] == SpriteSheet.KEY_FRAME)
			{
				rect.x += _frameWidth;
				if (rect.x >= _framesPerRow * _frameWidth)
				{
					rect.x = 0;
					rect.y += _frameHeight;
				}
			}
			*/
			for (var i:int = 1; i <= frame; i++)
			{
				if (_listFramesInfo[i] == SpriteSheet.KEY_FRAME)
				{
					_frameRectangle.x += _frameWidth;
					if (_frameRectangle.x >= _framesPerRow * _frameWidth)
					{
						_frameRectangle.x = 0;
						_frameRectangle.y += _frameHeight;
					}
				}
			}
			
			return _frameRectangle;
		}
	}
}