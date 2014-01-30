package molehill.core.render
{
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
			if (index0 == -1 || _listVerticesY[index0] != y0)
			{
				index0 = _listVerticesX.push(x0) - 1;
				_listVerticesY.push(y0);
				_listTextureU.push(u0);
				_listTextureW.push(w0);
				_listColors.push(rgba0);
			}
			_listIndices.writeShort(index0);
			
			var index1:int = _listVerticesX.indexOf(x1);
			if (index1 == -1 || _listVerticesY[index1] != y1)
			{
				index1 = _listVerticesX.push(x1) - 1;
				_listVerticesY.push(y1);
				_listTextureU.push(u1);
				_listTextureW.push(w1);
				_listColors.push(rgba1);
			}
			_listIndices.writeShort(index1);
			
			var index2:int = _listVerticesX.indexOf(x2);
			if (index2 == -1 || _listVerticesY[index2] != y2)
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
			if (index3 == -1 || _listVerticesY[index3] != y3)
			{
				index3 = _listVerticesX.push(x3) - 1;
				_listVerticesY.push(y3);
				_listTextureU.push(u3);
				_listTextureW.push(w3);
				_listColors.push(rgba3);
			}
			_listIndices.writeShort(index3);
		}
		
		private var _vertexData:ByteArray;
		public function getVerticesData():ByteArray
		{
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
				
				var argb:uint = _listColors[i];
				//trace(argb >>> 24);
				_vertexData.writeFloat((argb >>> 24) / 0xFF);
				_vertexData.writeFloat(((argb >>> 16) & 0xFF) / 0xFF);
				_vertexData.writeFloat(((argb >>> 8) & 0xFF) / 0xFF);
				_vertexData.writeFloat(uint(argb & 0xFF) / 0xFF);
				
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
				var shift:int = passedVertices / 9;
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
			_textureAtlasID = TextureManager.getInstance().getAtlasIDByTexture(
				TextureManager.getInstance().getTextureByID(textureID)
			);
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
	}
}