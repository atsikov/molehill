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
		private var _atlasData:TextureAtlasData;
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
		
		private const TEXTURE_GAP:int = 1;
		
		private var _hashNodesByTextureID:Object;
		public function insert(bitmapData:BitmapData, textureID:String, nextNode:TextureAtlasDataNode = null):TextureAtlasDataNode
		{
			if (nextNode == null)
			{
				nextNode = _root;
			}
			
			if (nextNode.textureID == "")
			{
				if (bitmapData.width > nextNode.rc.width || bitmapData.height > nextNode.rc.height)
				{
					return null;
				}
				
				if (bitmapData.width + nextNode.rc.x > this.width || bitmapData.height + nextNode.rc.y > this.height)
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
				copyPixels(
					bitmapData,
					bitmapData.rect,
					new Point(nextNode.rc.x, nextNode.rc.y)
				);
				
				nextNode.child = new Vector.<TextureAtlasDataNode>(2);
				
				var dw:int = nextNode.rc.width - bitmapData.width;
				var dh:int = nextNode.rc.height - bitmapData.height;
				
				nextNode.child[0] = new TextureAtlasDataNode();
				nextNode.child[1] = new TextureAtlasDataNode();
				
				if (dw > dh)
				{
					(nextNode.child[0] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x,
						nextNode.rc.y + TEXTURE_GAP + bitmapData.height,
						bitmapData.width,
						nextNode.rc.height - bitmapData.height - TEXTURE_GAP
					);
					
					(nextNode.child[1] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x + TEXTURE_GAP + bitmapData.width,
						nextNode.rc.y,
						nextNode.rc.width - bitmapData.width - TEXTURE_GAP,
						nextNode.rc.height
					);
				}
				else
				{
					(nextNode.child[0] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x + TEXTURE_GAP + bitmapData.width,
						nextNode.rc.y,
						nextNode.rc.width - bitmapData.width - TEXTURE_GAP,
						bitmapData.height
					);
					
					(nextNode.child[1] as TextureAtlasDataNode).rc = new Rectangle(
						nextNode.rc.x,
						nextNode.rc.y + TEXTURE_GAP + bitmapData.height,
						nextNode.rc.width,
						nextNode.rc.height - bitmapData.height - TEXTURE_GAP
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
				
				nextNode.rc.width = bitmapData.width;
				nextNode.rc.height = bitmapData.height;
				
				_atlasData.addTextureDesc(
					textureID,
					nextNode.rc.left,
					nextNode.rc.top,
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
			
			var newNode:TextureAtlasDataNode = insert(bitmapData, textureID, nextNode.child[0]);
			if (newNode == null)
			{
				newNode = insert(bitmapData, textureID, nextNode.child[1]);
			}
			
			return newNode;
		}

		public function get atlasData():TextureAtlasData
		{
			return _atlasData;
		}

	}
}
