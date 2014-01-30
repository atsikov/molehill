package molehill.core.texture
{
	import easy.ui.RasterizedSprite;
	
	import flash.display.BitmapData;
	import flash.display.MovieClip;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.geom.Transform;

	public class SpriteSheet extends BitmapData
	{
		public static const KEY_FRAME:String = "k";
		public static const NORMAL_FRAME:String = "n";
		
		public function SpriteSheet(movieClip:MovieClip, maxMidth:int = 2048, skipFrames:int = 0)
		{
			var listKeyFrames:Array = new Array();
			var shiftKeyFrames:Array = new Array();
			
			var maxRectangle:Rectangle = new Rectangle();
			var listRasterizedSprites:Array = new Array();
			
			for (var i:int = 0; i < movieClip.totalFrames; i++)
			{
				movieClip.gotoAndStop(i + 1);
				
				var sprite:RasterizedSprite = new RasterizedSprite(movieClip, true, true);
				var frameRect:Rectangle = sprite.bitmapData.rect;
				if (frameRect.left > maxRectangle.left)
				{
					maxRectangle.left = frameRect.left;
				}
				if (frameRect.right > maxRectangle.right)
				{
					maxRectangle.right = frameRect.right;
				}
				if (frameRect.top > maxRectangle.top)
				{
					maxRectangle.top = frameRect.top;
				}
				if (frameRect.bottom > maxRectangle.bottom)
				{
					maxRectangle.bottom = frameRect.bottom;
				}
				
				var isKeyFrame:Boolean = true;
				if (listRasterizedSprites.length > 0) 
				{
					var prevBitmapData:BitmapData = (listRasterizedSprites[listRasterizedSprites.length - 1] as RasterizedSprite).bitmapData;
					if (prevBitmapData.compare(sprite.bitmapData) === 0)
					{
						listKeyFrames.push(NORMAL_FRAME);
						isKeyFrame = false;
					}
				}
				
				
				if (isKeyFrame)
				{
					listRasterizedSprites.push(sprite);
					listKeyFrames.push(KEY_FRAME);
					shiftKeyFrames.push(frameRect);
				}
				
				if (i < movieClip.totalFrames - 1)
				{
					for (var j:int = 0; j < skipFrames; j++)
					{
						listKeyFrames.push(NORMAL_FRAME);
						i++;
						
						if (i == movieClip.totalFrames - 1)
						{
							break;
						}
					}
				}
			}
			
			var totalSquare:int = maxRectangle.width * maxRectangle.height * listRasterizedSprites.length;
			var side:Number = Math.min(maxMidth, Math.sqrt(totalSquare));
			
			maxMidth = side;
			
			var w:int;
			var h:int;
			var cols:int = int(maxMidth / maxRectangle.width);
			var rows:int = int((listRasterizedSprites.length - 1) / cols) + 1;
			if (rows > 1)
			{
				w = cols * maxRectangle.width;
				h = rows * maxRectangle.height;
			}
			else
			{
				w = maxRectangle.width * listRasterizedSprites.length;
				h = maxRectangle.height;
			}
			
			super(w, h, true, 0x00000000);
			
			for (i = 0; i < listRasterizedSprites.length; i++)
			{
				copyPixels(
					(listRasterizedSprites[i] as RasterizedSprite).bitmapData,
					(listRasterizedSprites[i] as RasterizedSprite).bitmapData.rect,
					new Point(
						(i % cols) * maxRectangle.width + (shiftKeyFrames[i].left - maxRectangle.left),
						int(i / cols) * maxRectangle.height + (shiftKeyFrames[i].top - maxRectangle.top)
					)
				);
			}
			
			_spriteSheetData = new SpriteSheetData(
				maxRectangle.width,
				maxRectangle.height,
				listKeyFrames.length,
				cols,
				listKeyFrames
			);
			
			//TODO: add support for rectangles with various pivot points
			
		}
		
		private var _spriteSheetData:SpriteSheetData;
		public function get spriteSheetData():SpriteSheetData
		{
			return _spriteSheetData;
		}
	}
}