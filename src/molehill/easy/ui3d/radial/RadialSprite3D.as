package molehill.easy.ui3d.radial
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.ProgramConstantsData;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;
	
	public class RadialSprite3D extends Sprite3D implements IVertexBatcher
	{
		private var _listTexturePoints:Vector.<Point>;
		
		private var _listIndices:ByteArray;
		
		public var _listPoints:Vector.<Point>;
		
		public var _pointsOrder:Array;/* = [
			8, 9, 0,
			8, 0, 7,
			0, 1, 2,
			0, 2, 3,
			6, 7, 0,
			6, 0, 5,
			0, 3, 4,
			0, 4, 5
		];*/
		
		public function RadialSprite3D()
		{
			_listTexturePoints = new Vector.<Point>();
			
			
			_listPoints = new Vector.<Point>();
			
			for (i = 0; i < 10; i++) 
			{
				_listPoints.push(new Point());
				_listTexturePoints.push(new Point());
			}
			
			super();
			
			
			_listIndices = new ByteArray();
			_listIndices.endian = Endian.LITTLE_ENDIAN;
			
			var i:int;
			
			if (_pointsOrder == null)
			{
				_pointsOrder = new Array();
				for (i = 0; i < 8; i++) 
				{
					_listIndices.writeShort(0);
					_listIndices.writeShort(i + 1);
					_listIndices.writeShort(i + 2);
					
					_pointsOrder.push(0);
					_pointsOrder.push(i + 1);
					_pointsOrder.push(i + 2);
				}
			}
			else
			{
				for (i = 0; i < _pointsOrder.length; i++) 
				{
					_listIndices.writeShort(_pointsOrder[i]);
				}
				
			}
		}
		
		/*
		
		0 and 9 - fixed
		
			8 --9 1-- 2
			| \  |  / |
			|  \ | /  |
			7 -- 0 -- 3
			|  / | \  |
			| /  |  \ |
			6 -- 5 -- 4
		
		*/
		
		molehill_internal override function updateValues():void
		{
			super.updateValues();
			
			updatePoints();
		}
		
		private var _fillMethod:String = "fill";
		public function get fillMethod():String
		{
			return _fillMethod;
		}

		public function set fillMethod(value:String):void
		{
			_fillMethod = value;
		}

		
		private var _progress:Number = 0;
		public function get progress():Number
		{
			return _progress;
		}

		public function set progress(value:Number):void
		{
			_progress = Math.min(1, Math.max(value, 0));
			
			markChanged(true);
		}
		
		private var partWidth:Number;
		private var partHeight:Number;
		private function updatePoints():void
		{
			var fullWidth:Number = this.width * _parentScaleX;
			var fullHeight:Number = this.height * _parentScaleY;
			
			_vertexData = null;
			
			switch(_fillMethod)
			{
				case RadialSprite3DFillMethod.FILL:
					updateFill();
					break;
				
				case RadialSprite3DFillMethod.ERASE:
					updateErase();
					break;
				
				default:
					updateFill();
			}
			
			var i:int;
			
			if (_textureRegion != null)
			{
				for (i = 0; i < _listTexturePoints.length; i++) 
				{
					_listTexturePoints[i].setTo(
						_listPoints[i].x  / fullWidth * _textureRegion.width + _textureRegion.x,
						_listPoints[i].y  / fullHeight * _textureRegion.height + _textureRegion.y
					);
				}
			}
			else
			{
				for (i = 0; i < _listTexturePoints.length; i++) 
				{
					_listTexturePoints[i].setTo(0, 0);
				}
			}
			
			for (i = 0; i < _listPoints.length; i++) 
			{
				_listPoints[i].offset(
					_vertexX1, 
					_vertexY1
				);
			}
			
			_left = _vertexX1;
			_right = _vertexX1 + fullWidth;
			_top = _vertexY1;
			_bottom = _vertexY1 + fullHeight;
		}
		
		private function updateErase():void
		{
			var fullWidth:Number = this.width * _parentScaleX;
			var fullHeight:Number = this.height * _parentScaleY;
			var halfWidth:Number = fullWidth / 2;
			var halfHeight:Number = fullHeight / 2;
			
			var angle:Number = Math.PI * 2 * _progress;
			
			var targetX:Number;
			var targetY:Number;
			
			var a:Number = Math.atan(fullWidth / fullHeight);
			
			partWidth = a / (2 * Math.PI);
			partHeight = (Math.PI / 2 - a) / (2 * Math.PI);
			
			_listPoints[0].setTo(halfWidth, halfHeight);
			_listPoints[9].setTo(halfWidth, 0);
			
			if (_progress < partWidth)
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = halfWidth + halfHeight * Math.tan(angle);
				targetY = 0;
				
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (partWidth + partHeight))
			{
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = fullWidth;
				targetY = halfHeight - halfWidth * Math.tan((Math.PI / 2) - angle);
				
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (partWidth + 2 * partHeight))
			{
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = fullWidth;
				targetY = halfHeight + halfWidth * Math.tan(angle - (Math.PI / 2));
				
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (2 * partWidth + 2 * partHeight))
			{
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = halfWidth + halfHeight * Math.tan(Math.PI - angle);
				targetY = fullHeight;
				
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 2 * partHeight))
			{
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = halfWidth - halfHeight * Math.tan(angle - Math.PI);
				targetY = fullHeight;
				
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 3 * partHeight))
			{
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = 0;
				targetY = halfHeight + halfWidth * Math.tan((3 * Math.PI / 2) - angle);
				
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 4 * partHeight))
			{
				_listPoints[8].setTo(0, 0);
				
				targetX = 0;
				targetY = halfHeight - halfWidth * Math.tan(angle - (3 * Math.PI / 2));
				
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
			else
			{
				targetX = halfWidth - halfHeight * Math.tan((2 * Math.PI) - angle);
				targetY = 0;
				
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[1].setTo(targetX, targetY);
			}
		}		
		
		private function updateFill():void
		{
			var fullWidth:Number = this.width * _parentScaleX;
			var fullHeight:Number = this.height * _parentScaleY;
			var halfWidth:Number = fullWidth / 2;
			var halfHeight:Number = fullHeight / 2;
			
			var angle:Number = Math.PI * 2 * _progress;
			
			var targetX:Number;
			var targetY:Number;
			
			var a:Number = Math.atan(fullWidth / fullHeight);
			
			partWidth = a / (2 * Math.PI);
			partHeight = (Math.PI / 2 - a) / (2 * Math.PI);
			
			_listPoints[0].setTo(halfWidth, halfHeight);
			_listPoints[1].setTo(halfWidth, 0);
			
			if (_progress < partWidth)
			{
				targetX = halfWidth + halfHeight * Math.tan(angle);
				targetY = 0;
				
				_listPoints[2].setTo(targetX, targetY);
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (partWidth + partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				
				targetX = fullWidth;
				targetY = halfHeight - halfWidth * Math.tan((Math.PI / 2) - angle);
				
				_listPoints[3].setTo(targetX, targetY);
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (partWidth + 2 * partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				
				targetX = fullWidth;
				targetY = halfHeight + halfWidth * Math.tan(angle - (Math.PI / 2));
				
				_listPoints[4].setTo(targetX, targetY);
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (2 * partWidth + 2 * partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				
				targetX = halfWidth + halfHeight * Math.tan(Math.PI - angle);
				targetY = fullHeight;
				
				_listPoints[5].setTo(targetX, targetY);
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 2 * partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				
				targetX = halfWidth - halfHeight * Math.tan(angle - Math.PI);
				targetY = fullHeight;
				
				_listPoints[6].setTo(targetX, targetY);
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 3 * partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				
				targetX = 0;
				targetY = halfHeight + halfWidth * Math.tan((3 * Math.PI / 2) - angle);
				
				_listPoints[7].setTo(targetX, targetY);
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else if (_progress < (3 * partWidth + 4 * partHeight))
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				
				targetX = 0;
				targetY = halfHeight - halfWidth * Math.tan(angle - (3 * Math.PI / 2));
				
				_listPoints[8].setTo(targetX, targetY);
				_listPoints[9].setTo(targetX, targetY);
			}
			else
			{
				_listPoints[2].setTo(fullWidth, 0);
				_listPoints[3].setTo(fullWidth, halfHeight);
				_listPoints[4].setTo(fullWidth, fullHeight);
				_listPoints[5].setTo(halfWidth, fullHeight);
				_listPoints[6].setTo(0, fullHeight);
				_listPoints[7].setTo(0, halfHeight);
				_listPoints[8].setTo(0, 0);
				
				targetX = halfWidth - halfHeight * Math.tan((2 * Math.PI) - angle);
				targetY = 0;
				
				_listPoints[9].setTo(targetX, targetY);
			}
		}		
		
		override public function setTexture(textureID:String):void
		{
			_textureAtlasID = TextureManager.getInstance().getAtlasDataByTextureID(textureID).atlasID;
			
			super.setTexture(textureID);
		}
		
		
		// IVertexBatcher
		private var _vertexData:ByteArray;
		public function getVerticesData():ByteArray
		{
			updateScrollableContainerValues();
			if (_vertexData != null)
			{
				return _vertexData;
			}
			
			_needUploadVertexData = true;
			
			_vertexData = new ByteArray();
			_vertexData.endian = Endian.LITTLE_ENDIAN;
			
			for (var i:int = 0; i < _listPoints.length; i++)
			{
				_vertexData.writeFloat(_listPoints[i].x);
				_vertexData.writeFloat(_listPoints[i].y);
				
				_vertexData.writeFloat(_redMultiplier * _parentRed);
				_vertexData.writeFloat(_greenMultiplier * _parentGreen);
				_vertexData.writeFloat(_blueMultiplier * _parentBlue);
				_vertexData.writeFloat(_alpha * _parentAlpha);
				
				_vertexData.writeFloat(_listTexturePoints[i].x);
				_vertexData.writeFloat(_listTexturePoints[i].y);
			}
			
			return _vertexData;
		}
		
		private var _lastPassedVertices:uint = 0;
		public function getIndicesData(passedVertices:uint):ByteArray
		{
			passedVertices = 0;
			if (passedVertices != _lastPassedVertices)
			{
				_needUploadIndexData = true;
				
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
		
		private var _batcherCamera:CustomCamera;
		public function get batcherCamera():CustomCamera
		{
			return _batcherCamera;
		}
		
		private var _cameraOwner:Sprite3D;
		public function get cameraOwner():Sprite3D
		{
			return _cameraOwner;
		}
		
		public function set cameraOwner(value:Sprite3D):void
		{
			if (_cameraOwner === value)
			{
				return;
			}
			
			_cameraOwner = value;
			updateScrollableContainerValues();
		}
		
		private function updateScrollableContainerValues():void
		{
			if (_cameraOwner == null || _cameraOwner.camera == null)
			{
				if (_batcherCamera != null)
				{
					_batcherCamera.reset();
				}
				
				return;
			}
			
			if (_batcherCamera == null)
			{
				_batcherCamera = new CustomCamera();
			}
			
			var referenceCamera:CustomCamera = _cameraOwner.camera;
			
			_batcherCamera.scrollX = referenceCamera.scrollX;
			_batcherCamera.scrollY = referenceCamera.scrollY;
			_batcherCamera.scale = referenceCamera.scale;
			
			var parent:Sprite3DContainer = _cameraOwner.parent;
			while (parent != null)
			{
				referenceCamera = parent.camera;
				if (referenceCamera != null)
				{
					_batcherCamera.scrollX += referenceCamera.scrollX;
					_batcherCamera.scrollY += referenceCamera.scrollX;
					_batcherCamera.scale *= referenceCamera.scale;
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
		
		private var _needUploadVertexData:Boolean = true;
		private var _needUploadIndexData:Boolean = true;
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _listOrderedBuffers:Vector.<OrderedVertexBuffer>;
		public function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>
		{
			if (_vertexBuffer == null)
			{
				_vertexBuffer = context.createVertexBuffer(10, Sprite3D.NUM_ELEMENTS_PER_VERTEX);
				_needUploadVertexData = true;
			}
			if (_needUploadVertexData)
			{
				_vertexBuffer.uploadFromByteArray(_vertexData, 0, 0, 10);
				_needUploadVertexData = false;
			}
			
			if (_listOrderedBuffers == null)
			{
				_listOrderedBuffers = new Vector.<OrderedVertexBuffer>();
			}
			
			if (_listOrderedBuffers.length == 0)
			{
				_listOrderedBuffers.push(
					new OrderedVertexBuffer(0, _vertexBuffer, Sprite3D.VERTICES_OFFSET, Context3DVertexBufferFormat.FLOAT_2),
					new OrderedVertexBuffer(1, _vertexBuffer, Sprite3D.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4),
					new OrderedVertexBuffer(2, _vertexBuffer, Sprite3D.TEXTURE_OFFSET, Context3DVertexBufferFormat.FLOAT_2)
				);
				_listOrderedBuffers.fixed = true;
			}
			else
			{
				_listOrderedBuffers[0].buffer = _vertexBuffer;
				_listOrderedBuffers[1].buffer = _vertexBuffer;
				_listOrderedBuffers[2].buffer = _vertexBuffer;
			}
			
			return _listOrderedBuffers;
		}
		
		private var _indexBuffer:IndexBuffer3D;
		public function getCustomIndexBuffer(context:Context3D):IndexBuffer3D
		{
			if (_indexBuffer == null)
			{
				_indexBuffer = context.createIndexBuffer(numTriangles * 3);
				_needUploadIndexData = true;
			}
			if (_needUploadIndexData)
			{
				_indexBuffer.uploadFromByteArray(_listIndices, 0, 0, numTriangles * 3);
				_needUploadIndexData = false;
			}
			
			return _indexBuffer;
		}
		
		public function get indexBufferOffset():int
		{
			return 0;
		}
		
		public function clearBatcher():void
		{
			onContextRestored();
		}
		
		public function onContextRestored():void
		{
			if (_vertexBuffer != null)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null;
			}
			
			_needUploadVertexData = true;
			
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			
			_needUploadIndexData = true;
		}
		
		public function getProgramConstantsData():Vector.<ProgramConstantsData>
		{
			return null;
		}
	}
}