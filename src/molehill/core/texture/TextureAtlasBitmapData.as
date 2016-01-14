package molehill.core.texture
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;

	public class TextureAtlasBitmapData extends BitmapData
	{
		private var _root:TextureAtlasDataNode;
		private var _maxWidth:int = 0;
		private var _maxHeight:int = 0;
		protected var _atlasData:TextureAtlasData;
		public function TextureAtlasBitmapData(maxWidth:int, maxHeight:int)
		{
			_maxWidth = maxWidth;
			_maxHeight = maxHeight;
			super(maxWidth, maxHeight, true, 0x00000000);
			
			_root = new TextureAtlasDataNode();
			_root.rc = new Rectangle(0, 0, maxWidth, maxHeight);
			
			_atlasData = new TextureAtlasData(maxWidth, maxHeight);
			
			_hashNodesByTextureID = {};
		}
		
		private var _locked:Boolean = false;
		public function set locked(value:Boolean):void
		{
			_locked = value;
		}
		
		private var _hashNodesByTextureID:Object;
		public function insert(bitmapData:BitmapData, textureID:String, textureGap:int = 1, extrudeEdges:Boolean = false, nextNode:TextureAtlasDataNode = null):TextureAtlasDataNode
		{
			if (_locked)
			{
				return null;
			}
			
			if (nextNode == null)
			{
				nextNode = _root;
			}
			
			if (nextNode.textureID == "")
			{
				var bitmapWidth:int = bitmapData.width + (extrudeEdges ? 2 : 0);
				var bitmapHeight:int = bitmapData.height + (extrudeEdges ? 2 : 0);
				
				if (bitmapWidth > nextNode.rc.width || bitmapHeight > nextNode.rc.height)
				{
					return null;
				}
				
				if (bitmapWidth + nextNode.rc.x > this.width || bitmapHeight + nextNode.rc.y > this.height)
				{
					return null;
				}
				/*
				var a:int;
				var b:int;
				for (a = nextNode.rc.x, b = nextNode.rc.y; a < nextNode.rc.x + bitmapData.width / 2, b < nextNode.rc.y + bitmapData.height / 2; a++, b++)
				{
					if (getPixel32(a, b) > 0)
					{
						throw new Error("trying to put bitmap to not empty place!");
					}
				}
				*/
				nextNode.textureID = textureID;
				if (extrudeEdges)
				{
					copyPixels(
						bitmapData,
						new Rectangle(0, 0, bitmapData.width, 1),
						new Point(nextNode.rc.x + 1, nextNode.rc.y)
					);
					
					copyPixels(
						bitmapData,
						new Rectangle(0, 0, 1, bitmapData.height),
						new Point(nextNode.rc.x, nextNode.rc.y + 1)
					);
					
					copyPixels(
						bitmapData,
						new Rectangle(0, bitmapData.height - 1, bitmapData.width, 1),
						new Point(nextNode.rc.x + 1, nextNode.rc.y + bitmapHeight - 1)
					);
					
					copyPixels(
						bitmapData,
						new Rectangle(bitmapData.width - 1, 0, 1, bitmapData.height),
						new Point(nextNode.rc.x + bitmapWidth - 1, nextNode.rc.y + 1)
					);
				}
				
				var bitmapPoint:Point = new Point(nextNode.rc.x, nextNode.rc.y);
				if (extrudeEdges)
				{
					bitmapPoint.offset(1, 1);
				}
				
				copyPixels(
					bitmapData,
					bitmapData.rect,
					bitmapPoint
				);
				
				nextNode.child = new Vector.<TextureAtlasDataNode>(2);
				
				var dw:int = nextNode.rc.width - bitmapWidth;
				var dh:int = nextNode.rc.height - bitmapHeight;
				
				nextNode.child[0] = new TextureAtlasDataNode();
				nextNode.child[1] = new TextureAtlasDataNode();
				
				if (dw > dh)
				{
					(nextNode.child[0] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x,
						nextNode.rc.y + textureGap + bitmapHeight,
						bitmapWidth,
						nextNode.rc.height - bitmapHeight - textureGap
					);
					
					(nextNode.child[1] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x + textureGap + bitmapWidth,
						nextNode.rc.y,
						nextNode.rc.width - bitmapWidth - textureGap,
						nextNode.rc.height
					);
				}
				else
				{
					(nextNode.child[0] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x + textureGap + bitmapWidth,
						nextNode.rc.y,
						nextNode.rc.width - bitmapWidth - textureGap,
						bitmapHeight
					);
					
					(nextNode.child[1] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x,
						nextNode.rc.y + textureGap + bitmapHeight,
						nextNode.rc.width,
						nextNode.rc.height - bitmapHeight - textureGap
					);
 				}
				
				if ((nextNode.child[1] as TextureAtlasDataNode).rc.intersects(
					(nextNode.child[0] as TextureAtlasDataNode).rc
				))
				{
					throw new Error((nextNode.child[1] as TextureAtlasDataNode).rc.intersection(
						(nextNode.child[0] as TextureAtlasDataNode).rc
					));
				}
				
				// nextNode.rc represents texture size to be used in render
				nextNode.rc.width = bitmapData.width;
				nextNode.rc.height = bitmapData.height;
				
				_atlasData.addTextureDesc(
					textureID,
					bitmapPoint.x,
					bitmapPoint.y,
					nextNode.rc.width,
					nextNode.rc.height
				);
				
				_hashNodesByTextureID[textureID] = nextNode;
				
				return nextNode;
			}
			
			if (nextNode.child == null)
			{
				return null;
			}
			
			var newNode:TextureAtlasDataNode = insert(bitmapData, textureID, textureGap, extrudeEdges, nextNode.child[0]);
			if (newNode == null)
			{
				newNode = insert(bitmapData, textureID, textureGap, extrudeEdges, nextNode.child[1]);
			}
			
			return newNode;
		}

		public function get textureAtlasData():TextureAtlasData
		{
			return _atlasData;
		}

	}
}
