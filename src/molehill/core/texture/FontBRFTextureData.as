package molehill.core.texture
{
	import flash.display.BitmapData;
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class FontBRFTextureData extends TextureAtlasBitmapData
	{
		public function FontBRFTextureData(bitmapData:BitmapData, fontTextureData:FontTextureData)
		{
			super(bitmapData.width, bitmapData.height);
			copyPixels(bitmapData, bitmapData.rect, new Point());
			
			_atlasData = fontTextureData;
			
			createAtlasSpaceMap();
		}
		
		private var _listTexturesByPosition:Array;
		private function createAtlasSpaceMap():void
		{
			var hashTexturesByCoords:Object = new Object();
			for each (var textureData:TextureData in _atlasData._hashTextures)
			{
				var textureRegion:Rectangle = textureData.textureRect;
				if (hashTexturesByCoords[textureRegion.left] == null)
				{
					hashTexturesByCoords[textureRegion.left] = new Object();
				}
				hashTexturesByCoords[textureRegion.left][textureRegion.top] = textureData;
			}
			
			_listTexturesByPosition = new Array();
			for each (var hashTexturesByTop:Object in hashTexturesByCoords)
			{
				var row:Array = new Array();
				_listTexturesByPosition.push(row);
				for each (textureData in hashTexturesByTop)
				{
					row.push(textureData);
				}
				row.sort(sortTexturesByY);
			}
			
			_listTexturesByPosition.sort(sortTexturesByX);
			
			var firstTexture:TextureData = _listTexturesByPosition[0][0];
			var gap:int = 0;
			var nearestTexture:TextureData = _listTexturesByPosition[1][0];
			if (nearestTexture != null)
			{
				gap = nearestTexture.textureRect.left - firstTexture.textureRect.right;
			}
			else
			{
				nearestTexture = _listTexturesByPosition[0][1];
				if (nearestTexture != null)
				{
					gap = nearestTexture.textureRect.top - firstTexture.textureRect.bottom;
				}
			}
			
			var extrude:Boolean = firstTexture.textureRect.x != 0;
			
			insertRect(new Point(), gap);
		}
		
		private function insertRect(point:Point, textureGap:int = 1, nextNode:TextureAtlasDataNode = null):TextureAtlasDataNode
		{
			if (nextNode == null)
			{
				nextNode = _root;
			}
			
			if (point == null)
			{
				return null;
			}
			
			var textureData:TextureData = _listTexturesByPosition[point.x][point.y];
			var rect:Rectangle = textureData.textureRect;
			var textureID:String = textureData.textureID;
			
			var newNode:TextureAtlasDataNode;
			if (nextNode.textureID == "")
			{
				var bitmapWidth:int = rect.width;
				var bitmapHeight:int = rect.height;
				
				if (bitmapWidth > nextNode.rc.width || bitmapHeight > nextNode.rc.height)
				{
					//trace(
					//	'cannot put ' + bitmapWidth + ' x ' + bitmapHeight +
					//	' into ' + nextNode.rc.width + ' x ' + nextNode.rc.height
					//);
					return null;
				}
				
				if (bitmapWidth + nextNode.rc.x > this.width || bitmapHeight + nextNode.rc.y > this.height)
				{
					//trace(rect + ' out of atlas');
					return null;
				}
				
				nextNode.textureID = textureID;
				
				nextNode.child = new Vector.<TextureAtlasDataNode>(2);
				
				var dw:int = nextNode.rc.width - bitmapWidth;
				var dh:int = nextNode.rc.height - bitmapHeight;
				
				nextNode.child[0] = new TextureAtlasDataNode();
				nextNode.child[1] = new TextureAtlasDataNode();
				
				var nextPoint0:Point;
				var nextPoint1:Point;
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
					
					//trace('inserted ' + point + ' ' + rect + '; by y next');
					
					nextPoint0 = getNeighborYPoint(point);
					nextPoint1 = getNeighborXPoint(point);
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
					
					//trace('inserted ' + point + ' ' + rect + '; by x next');
					
					nextPoint0 = getNeighborXPoint(point);
					nextPoint1 = getNeighborYPoint(point);
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
				nextNode.rc.width = rect.width;
				nextNode.rc.height = rect.height;
				
				_atlasData.addTextureDesc(
					textureID,
					nextNode.rc.x,
					nextNode.rc.y,
					nextNode.rc.width,
					nextNode.rc.height
				);
				
				_hashNodesByTextureID[textureID] = nextNode;
				
				insertRect(nextPoint0, textureGap, nextNode.child[0]);
				insertRect(nextPoint1, textureGap, nextNode.child[1]);
				
				return nextNode;
			}
			else
			{
				newNode = insertRect(point, textureGap, nextNode.child[0]);
				if (newNode == null)
				{
					newNode = insertRect(point, textureGap, nextNode.child[1]);
				}
			}
			
			return newNode;
		}
		
		private function getNeighborXPoint(point:Point):Point
		{
			var textureData:TextureData = _listTexturesByPosition[point.x][point.y];
			var textureY:int = textureData.textureRect.y;
			for (var i:int = point.x + 1; i < _listTexturesByPosition.length; i++)
			{
				var listTexturesByTop:Array = _listTexturesByPosition[i];
				for (var j:int = 0; j < listTexturesByTop.length; j++)
				{
					textureData = _listTexturesByPosition[i][j];
					if (textureData.textureRect.y == textureY)
					{
						return new Point(i, j);
					}
				}
			}
			
			return null;
		}
		
		private function getNeighborYPoint(point:Point):Point
		{
			if (_listTexturesByPosition[point.x][point.y + 1] != null)
			{
				return new Point(point.x, point.y + 1);
			}
			
			return null;
		}
		
		private function sortTexturesByX(listTexturesA:Array, listTexturesB:Array):int
		{
			return listTexturesA[0].textureRect.left - listTexturesB[0].textureRect.left;
		}
		
		private function sortTexturesByY(textureDataA:TextureData, textureDataB:TextureData):int
		{
			return textureDataA.textureRect.top - textureDataB.textureRect.top;
		}
	}
}