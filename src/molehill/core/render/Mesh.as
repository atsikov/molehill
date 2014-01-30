package molehill.core.render
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import molehill.core.texture.TextureManager;

	public class Mesh extends Sprite3D implements IVertexBatcher
	{
		private var _listVerticesX:Vector.<Number>;
		private var _listVerticesY:Vector.<Number>;
		private var _listTextureU:Vector.<Number>;
		private var _listTextureW:Vector.<Number>;
		private var _listColors:Vector.<uint>;
		
		private var _listIndices:ByteArray;
		public function Mesh()
		{
			_listVerticesX = new Vector.<Number>();
			_listVerticesY = new Vector.<Number>();
			_listTextureU = new Vector.<Number>();
			_listTextureW = new Vector.<Number>();
			
			_listColors = new Vector.<uint>();
			
			_listIndices = new ByteArray();
			_listIndices.endian = Endian.LITTLE_ENDIAN;
		}
		
		/**
		 *  should be passed as 0,1,2,0,2,3
		 **/ 
		protected var _reuseVertices:Boolean = true;
		public function addTile(
			x0:Number, y0:Number,
			x1:Number, y1:Number,
			x2:Number, y2:Number,
			x3:Number, y3:Number,
			u0:Number, w0:Number,
			u1:Number, w1:Number,
			u2:Number, w2:Number,
			u3:Number, w3:Number,
			rgba0:uint = 0xFFFFFFFF,
			rgba1:uint = 0xFFFFFFFF,
			rgba2:uint = 0xFFFFFFFF,
			rgba3:uint = 0xFFFFFFFF
		):void
		{
			_vertexData = null;
			var index0:int = _listVerticesX.indexOf(x0);
			if (!_reuseVertices || index0 == -1 || _listVerticesY[index0] != y0)
			{
				index0 = _listVerticesX.push(x0) - 1;
				_listVerticesY.push(y0);
				_listTextureU.push(u0);
				_listTextureW.push(w0);
				_listColors.push(rgba0);
			}
			_listIndices.writeShort(index0);
			
			var index1:int = _listVerticesX.indexOf(x1);
			if (!_reuseVertices || index1 == -1 || _listVerticesY[index1] != y1)
			{
				index1 = _listVerticesX.push(x1) - 1;
				_listVerticesY.push(y1);
				_listTextureU.push(u1);
				_listTextureW.push(w1);
				_listColors.push(rgba1);
			}
			_listIndices.writeShort(index1);
			
			var index2:int = _listVerticesX.indexOf(x2);
			if (!_reuseVertices || index2 == -1 || _listVerticesY[index2] != y2)
			{
				index2 = _listVerticesX.push(x2) - 1;
				_listVerticesY.push(y2);
				_listTextureU.push(u2);
				_listTextureW.push(w2);
				_listColors.push(rgba2);
			}
			_listIndices.writeShort(index2);
			
			_listIndices.writeShort(index0);
			_listIndices.writeShort(index2);
			
			var index3:int = _listVerticesX.indexOf(x3);
			if (!_reuseVertices || index3 == -1 || _listVerticesY[index3] != y3)
			{
				index3 = _listVerticesX.push(x3) - 1;
				_listVerticesY.push(y3);
				_listTextureU.push(u3);
				_listTextureW.push(w3);
				_listColors.push(rgba3);
			}
			_listIndices.writeShort(index3);
			
			if (x0 < _left)
			{
				_left = x0;
			}
			if (x1 < _left)
			{
				_left = x1;
			}
			if (x2 < _left)
			{
				_left = x2;
			}
			if (x3 < _left)
			{
				_left = x3;
			}
			
			if (x0 > _right)
			{
				_right = x0;
			}
			if (x1 > _right)
			{
				_right = x1;
			}
			if (x2 > _right)
			{
				_right = x2;
			}
			if (x3 > _right)
			{
				_right = x3;
			}
			
			if (y0 < _top)
			{
				_top = y0;
			}
			if (y1 < _top)
			{
				_top = y1;
			}
			if (y2 < _top)
			{
				_top = y2;
			}
			if (y3 < _top)
			{
				_top = y3;
			}
			
			if (y0 > _bottom)
			{
				_bottom = y0;
			}
			if (y1 > _bottom)
			{
				_bottom = y1;
			}
			if (y2 > _bottom)
			{
				_bottom = y2;
			}
			if (y3 > _bottom)
			{
				_bottom = y3;
			}
		}
		
		private var _vertexData:ByteArray;
		public function getVerticesData():ByteArray
		{
			updateScrollableContainerValues();
			if (_vertexData != null)
			{
				return _vertexData;
			}
			
			_vertexData = new ByteArray();
			_vertexData.endian = Endian.LITTLE_ENDIAN;
			
			for (var i:int = 0; i < _listVerticesX.length; i++)
			{
				_vertexData.writeFloat(_listVerticesX[i]);
				_vertexData.writeFloat(_listVerticesY[i]);
				_vertexData.writeFloat(0);
				
				var rgba:uint = _listColors[i];
				_vertexData.writeFloat((rgba >>> 24) / 0xFF);
				_vertexData.writeFloat(((rgba >>> 16) & 0xFF) / 0xFF);
				_vertexData.writeFloat(((rgba >>> 8) & 0xFF) / 0xFF);
				_vertexData.writeFloat(uint(rgba & 0xFF) / 0xFF);
				
				_vertexData.writeFloat(_listTextureU[i]);
				_vertexData.writeFloat(_listTextureW[i]);
			}
			
			return _vertexData;
		}
		
		private var _lastPassedVertices:uint = 0;
		public function getIndicesData(passedVertices:uint):ByteArray
		{
			if (passedVertices != _lastPassedVertices)
			{
				_listIndices.position = 0;
				var shift:int = passedVertices / 9 - _lastPassedVertices / 9;
				for (var i:int = 0; i < _listIndices.length / 2; i++)
				{
					var index:int = _listIndices.readShort();
					_listIndices.position -= 2;
					_listIndices.writeShort(index + shift);
				}
				
				_lastPassedVertices = passedVertices;
			}
			
			return _listIndices;
		}
		
		override public function set textureID(value:String):void
		{
			super.textureID = value;
			_textureAtlasID = TextureManager.getInstance().getAtlasDataByTextureID(textureID).atlasID;
		}
		
		// IVertexBatcher
		public function get numTriangles():uint
		{
			return visible ? _listIndices.length / 3 / 2 : 0;
		}
		
		private var _textureAtlasID:String;
		public function get textureAtlasID():String
		{
			return _textureAtlasID;
		}
		
		public function set textureAtlasID(value:String):void
		{
			_textureAtlasID = value;
		}
		
		private var _scrollRect:Rectangle;
		public function get scrollRect():Rectangle
		{
			if (_scrollRect == null)
			{
				_scrollRect = new Rectangle();
			}
			
			return _scrollRect;
		}
		
		private var _scrollRectOwner:Sprite3DContainer;
		public function get scrollRectOwner():Sprite3DContainer
		{
			return _scrollRectOwner;
		}
		
		public function set scrollRectOwner(value:Sprite3DContainer):void
		{
			if (_scrollRectOwner === value)
			{
				return;
			}
			
			_scrollRectOwner = value;
			
			if (_scrollRectOwner == null)
			{
				_scrollRect = null;
				return;
			}
			
			updateScrollableContainerValues();
		}
		
		private function updateScrollableContainerValues():void
		{
			if (_scrollRectOwner == null || _scrollRectOwner != null && _scrollRectOwner.scrollRect == null)
			{
				return;
			}
			
			if (_scrollRect == null)
			{
				_scrollRect = new Rectangle();
			}
			
			_scrollRect.x = _scrollRectOwner.scrollRect.x;
			_scrollRect.y = _scrollRectOwner.scrollRect.y;
			_scrollRect.width = _scrollRectOwner.width;
			_scrollRect.height = _scrollRectOwner.height;
			var parent:Sprite3DContainer = _scrollRectOwner.parent;
			while (parent != null)
			{
				if (parent.scrollRect != null)
				{
					_scrollRect.x += parent.scrollRect.x;
					_scrollRect.y += parent.scrollRect.y;
				}
				
				parent = parent.parent;
			}
		}
		
		private var _left:Number = int.MAX_VALUE;

		public function get left():Number
		{
			return _left;
		}

		private var _right:Number = int.MIN_VALUE;

		public function get right():Number
		{
			return _right;
		}

		private var _top:Number = int.MAX_VALUE;

		public function get top():Number
		{
			return _top;
		}

		private var _bottom:Number = int.MIN_VALUE;

		public function get bottom():Number
		{
			return _bottom;
		}
		
		public function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>
		{
			return null;
		}
		
		public function getCustomIndexBuffer(context:Context3D):IndexBuffer3D
		{
			return null;
		}
		
		public function get indexBufferOffset():int
		{
			return -1;
		}
	}
}