package molehill.core.render
{
	import easy.collections.LinkedList;
	import easy.collections.LinkedListElement;
	import easy.collections.TreeNode;
	
	import flash.display.Shader;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	use namespace molehill_internal;
	
	/**
	 * 
	 *  Class to combine sprites with the same texture into one vertex buffer
	 * 
	 **/
	internal class SpriteBatcher implements IVertexBatcher
	{
		private var _parent:Scene3D;
		public function SpriteBatcher(parent:Scene3D)
		{
			_listSprites = new LinkedList();
			_parent = parent;
		}
		
		private var _blendMode:String;

		public function get blendMode():String
		{
			return _blendMode;
		}

		public function set blendMode(value:String):void
		{
			_blendMode = value;
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
		
		private var _needUpdateBuffers:Boolean = false;
		private var _listSprites:LinkedList;
		private var _numSprites:int = 0;
		internal function get numSprites():uint
		{
			return _numSprites;
		}
		
		internal function addChild(sprite:Sprite3D):void
		{
			_listSprites.enqueue(sprite);
			_needUpdateBuffers = true;
			_numSprites++;
			
			if (_totalVertexBuffer != null)
			{
				_totalVertexBuffer.dispose();
				_totalVertexBuffer = null;
			}
			if (_totalIndexBuffer != null)
			{
				_totalIndexBuffer.dispose();
				_totalIndexBuffer = null;
			}
		}
		
		internal function addChildBefore(child1:Sprite3D, child2:Sprite3D):void
		{
			var cursor:LinkedListElement = _listSprites.head;
			while (cursor != null && cursor.data !== child1)
			{
				cursor = cursor.next;
			}
			
			if (cursor == null)
			{
				_listSprites.enqueue(child2);
			}
			else
			{
				var element:LinkedListElement = new LinkedListElement();
				element.data = child2;
				
				if (cursor.prev == null)
				{
					_listSprites.addElementToHead(element);
				}
				else
				{
					_listSprites.insertElementAfter(cursor.prev, element);
				}
			}
			_needUpdateBuffers = true;
			_numSprites++;
			
			if (_totalVertexBuffer != null)
			{
				_totalVertexBuffer.dispose();
				_totalVertexBuffer = null;
			}
			if (_totalIndexBuffer != null)
			{
				_totalIndexBuffer.dispose();
				_totalIndexBuffer = null;
			}
		}
		
		
		internal function addChildAfter(child1:Sprite3D, child2:Sprite3D):void
		{
			var cursor:LinkedListElement = _listSprites.head;
			while (cursor != null && cursor.data !== child1)
			{
				cursor = cursor.next;
			}
			
			if (cursor == null)
			{
				_listSprites.enqueue(child2);
			}
			else
			{
				var element:LinkedListElement = new LinkedListElement();
				element.data = child2;
				_listSprites.insertElementAfter(cursor, element);
			}
			_needUpdateBuffers = true;
			_numSprites++;
			
			if (_totalVertexBuffer != null)
			{
				_totalVertexBuffer.dispose();
				_totalVertexBuffer = null;
			}
			if (_totalIndexBuffer != null)
			{
				_totalIndexBuffer.dispose();
				_totalIndexBuffer = null;
			}
		}
		
		internal function reset():void
		{
			while (!_listSprites.empty)
			{
				var child:Sprite3D = _listSprites.dequeue() as Sprite3D;
				if (child is AnimatedSprite3D)
				{
					(child as AnimatedSprite3D).stop();
				}
			}
			
			_numSprites = 0;
			_numVisibleSprites = 0;
			
			if (_totalVertexBuffer != null)
			{
				_totalVertexBuffer.dispose();
				_totalVertexBuffer = null;
			}
			
			if (_totalIndexBuffer != null)
			{
				_totalIndexBuffer.dispose();
				_totalIndexBuffer = null;
			}
			
			if (_vertexBufferData != null)
			{
				_vertexBufferData.length = 0;
				_vertexBufferData = null;
			}
			
			if (_indexBufferData != null)
			{
				_indexBufferData.length = 0;
				_indexBufferData = null;
			}
		}
		
		internal function pushSpriteContainerTree(container:Sprite3DContainer):void
		{
			var root:TreeNode = container.localTreeRoot.firstChild;
			
			while (root != null)
			{
				if (root.value is Sprite3DContainer)
				{
					pushSpriteContainerTree(root.value as Sprite3DContainer);
				}
				
				addChild(root.value as Sprite3D);
				
				root = root.nextSibling;
			}
		}
		
		internal function getFirstChild():Sprite3D
		{
			return _listSprites.head == null ? null : _listSprites.head.data as Sprite3D;
		}
		
		internal function getLastChild():Sprite3D
		{
			return _listSprites.tail == null ? (_listSprites.head == null ? null : _listSprites.head.data as Sprite3D) : _listSprites.tail.data as Sprite3D;
		}
		
		internal function removeChild(sprite:Sprite3D):void
		{
			var cursor:LinkedListElement = _listSprites.head;
			while (cursor != null && cursor.data != sprite)
			{
				cursor = cursor.next;
			}
			
			if (cursor == null)
			{
				return;
			}
			
			_listSprites.removeElement(cursor);
			_numSprites--;
			
			if (cursor.data is AnimatedSprite3D)
			{
				(cursor.data as AnimatedSprite3D).stop();
			}
			
			if (_totalVertexBuffer != null)
			{
				_totalVertexBuffer.dispose();
				_totalVertexBuffer = null;
			}
			
			if (_totalIndexBuffer != null)
			{
				_totalIndexBuffer.dispose();
				_totalIndexBuffer = null;
			}
			
			if (_vertexBufferData != null)
			{
				_vertexBufferData.length = 0;
				_vertexBufferData = null;
			}
			
			if (_indexBufferData != null)
			{
				_indexBufferData.length = 0;
				_indexBufferData = null;
			}
			
			_needUpdateBuffers = true;
		}
		
		internal function splitAfterChild(child:Sprite3D):SpriteBatcher
		{
			var element:LinkedListElement = _listSprites.head;
			var childIndex:int = 0;
			while (element != null && element.data !== child)
			{
				element = element.next;
				childIndex++;
			}
			
			element = element == null ? null : element.next;
			
			if (element == null)
			{
				return null;
			}
			
			childIndex++;
			
			var result:SpriteBatcher = new SpriteBatcher(_parent);
			result._textureAtlasID = _textureAtlasID;
			result._blendMode = _blendMode;
			result._scrollRectOwner = _scrollRectOwner;
			result._shader = shader;
			result._listSprites = _listSprites.splitAtElement(element);
			result._numSprites = _numSprites - childIndex;
			result._numVisibleSprites = result._numSprites;
			result._needUpdateBuffers = true;
			
			_indexBufferData = null;
			_vertexBufferData = null;
			
			_needUpdateBuffers = true;
			_numSprites = childIndex;
			_numVisibleSprites = childIndex;
			
			return result;
		}
		
		internal function contains(child:Sprite3D):Boolean
		{
			// TODO: implement search from both head and tail
			
			var cursorHead:LinkedListElement = _listSprites.head;
			while (cursorHead != null && cursorHead.data != child)
			{
				cursorHead = cursorHead.next;
			}
			
			return cursorHead != null;
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
			updateScrollableContainerValues();
		}
		
		private function updateScrollableContainerValues():void
		{
			if (_scrollRectOwner.scrollRect == null)
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
		
		private var _numVisibleSprites:int;
		public function get numVisibleSprites():int
		{
			return _numVisibleSprites;
		}
		
		public function get numTriangles():uint
		{
			return _numVisibleSprites * 2;
		}
		
		private var _totalVertexBuffer:VertexBuffer3D;
		private var _totalIndexBuffer:IndexBuffer3D;
		
		private var _vertexBufferData:ByteArray;
		public function getVerticesData():ByteArray
		{
			prepareSprites();
			return _vertexBufferData;
		}

		private var _indexBufferData:ByteArray;
		private var _lastPassedVertices:uint;
		public function getIndicesData(passedVertices:uint):ByteArray
		{
			if (passedVertices != _lastPassedVertices)
			{
				_indexBufferData.position = 0;
				var shift:int = passedVertices / 9 - _lastPassedVertices / 9;
				for (var i:int = 0; i < _indexBufferData.length / 2; i++)
				{
					var index:int = _indexBufferData.readShort();
					_indexBufferData.position -= 2;
					_indexBufferData.writeShort(index + shift);
				}
				
				_lastPassedVertices = passedVertices;
			}
			
			return _indexBufferData;
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
		
		private function updateBuffers():void
		{
			if (_numSprites == 0)
			{
				return;
			}
			
			var sprite:Sprite3D;
			var cursor:LinkedListElement;
			var hasChanges:Boolean = false;
			if (!_needUpdateBuffers)
			{
				cursor = _listSprites.head;
				while (cursor != null)
				{
					sprite = cursor.data as Sprite3D;
					if (sprite._hasChanged || sprite._textureChanged)
					{
						hasChanges = true;
					}
					if (sprite._visibilityChanged)
					{
						_needUpdateBuffers = true;
						break;
					}
					cursor = cursor.next;
				}
				
				if (cursor == null && !hasChanges)
				{
					return;
				}
			}
			
			var currentNumVisibleSprites:int = _numVisibleSprites;
			_numVisibleSprites = 0;
			
			if (_vertexBufferData == null)
			{
				_vertexBufferData = new ByteArray();
				_vertexBufferData.endian = Endian.LITTLE_ENDIAN;
			}
			
			if (_indexBufferData == null)
			{
				_indexBufferData = new ByteArray();
				_indexBufferData.endian = Endian.LITTLE_ENDIAN;
			}
			
			var indexNum:int = 0;
			var nextIndexNum:int;
			
			var v0:int = 0;
			var v1:int = Sprite3D.NUM_ELEMENTS_PER_VERTEX;
			var v2:int = 2 * Sprite3D.NUM_ELEMENTS_PER_VERTEX;
			var v3:int = 3 * Sprite3D.NUM_ELEMENTS_PER_VERTEX;
			
			var i:int = 0;
			cursor = _listSprites.head;
			while (cursor != null)
			{
				sprite = cursor.data as Sprite3D;
				
				indexNum = numSprites - 1 - i;
				
				var j:int;
				
				if (!sprite.visible)
				{
					sprite.hasChanged = false;
					sprite._textureChanged = false;
				}
				else
				{
					nextIndexNum = _numVisibleSprites * Sprite3D.NUM_ELEMENTS_PER_SPRITE;
					
					if (sprite._hasChanged || _needUpdateBuffers)
					{
						//sprite.updateValues();
						
						_vertexBufferData.position = (nextIndexNum + v0) * 4;
						_vertexBufferData.writeFloat(sprite._vertexX0);
						_vertexBufferData.writeFloat(sprite._vertexY0);
						_vertexBufferData.writeFloat(sprite._z0);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v1) * 4;
						_vertexBufferData.writeFloat(sprite._vertexX1);
						_vertexBufferData.writeFloat(sprite._vertexY1);
						_vertexBufferData.writeFloat(sprite._z1);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v2) * 4;
						_vertexBufferData.writeFloat(sprite._vertexX2);
						_vertexBufferData.writeFloat(sprite._vertexY2);
						_vertexBufferData.writeFloat(sprite._z2);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v3) * 4;
						_vertexBufferData.writeFloat(sprite._vertexX3);
						_vertexBufferData.writeFloat(sprite._vertexY3);
						_vertexBufferData.writeFloat(sprite._z3);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						var topCandidate:Number;
						var bottomCandidate:Number;
						if (sprite._vertexY0 > sprite._vertexY1)
						{
							topCandidate = sprite._vertexY1;
							bottomCandidate = sprite._vertexY0;
						}
						else
						{
							topCandidate = sprite._vertexY0;
							bottomCandidate = sprite._vertexY1;
						}
						
						if (_top > topCandidate)
						{
							_top = topCandidate;
						}
						if (_bottom < bottomCandidate)
						{
							_bottom = bottomCandidate;
						}
						
						if (_left > sprite._vertexX0)
						{
							_left = sprite._vertexX0;
						}
						if (_right < sprite._vertexX2)
						{
							_right = sprite._vertexX2;
						}
						
						sprite.hasChanged = false;
					}
					
					if (sprite._textureChanged || _needUpdateBuffers)
					{
						_vertexBufferData.position = (nextIndexNum + v0 + Sprite3D.TEXTURE_OFFSET) * 4;
						_vertexBufferData.writeFloat(sprite._textureU0);
						_vertexBufferData.writeFloat(sprite._textureW0);
						
						_vertexBufferData.position = (nextIndexNum + v1 + Sprite3D.TEXTURE_OFFSET) * 4;
						_vertexBufferData.writeFloat(sprite._textureU1);
						_vertexBufferData.writeFloat(sprite._textureW1);
						
						_vertexBufferData.position = (nextIndexNum + v2 + Sprite3D.TEXTURE_OFFSET) * 4;
						_vertexBufferData.writeFloat(sprite._textureU2);
						_vertexBufferData.writeFloat(sprite._textureW2);
						
						_vertexBufferData.position = (nextIndexNum + v3 + Sprite3D.TEXTURE_OFFSET) * 4;
						_vertexBufferData.writeFloat(sprite._textureU3);
						_vertexBufferData.writeFloat(sprite._textureW3);
						
						sprite._textureChanged = false;
					}
					
					if (_needUpdateBuffers)
					{
						nextIndexNum = _numVisibleSprites * 6;
						
						indexNum = _numVisibleSprites * 4 + _lastPassedVertices / 9;
						
						_indexBufferData.position = _numVisibleSprites * 6 * 2;
						_indexBufferData.writeShort(indexNum);
						_indexBufferData.writeShort(indexNum + 1);
						_indexBufferData.writeShort(indexNum + 2);
						_indexBufferData.writeShort(indexNum);
						_indexBufferData.writeShort(indexNum + 2);
						_indexBufferData.writeShort(indexNum + 3);
						
					}
					_numVisibleSprites++;
				}
				
				sprite.resetVisibilityChanged();
				
				cursor = cursor.next;
				i++;
			}
			
			if (currentNumVisibleSprites != _numVisibleSprites)
			{
				_indexBuffer = null;
				_vertexBuffer = null;
			}
			
			_needUpdateBuffers = false;
		}
		
		internal function prepareSprites():void
		{
			updateBuffers();
			
			if (_scrollRectOwner != null)
			{
				updateScrollableContainerValues();
			}
		}
		
		private var _shader:Shader3D;
		public function get shader():Shader3D
		{
			return _shader;
		}
		
		public function set shader(value:Shader3D):void
		{
			_shader = value;
		}
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _listOrderedBuffers:Vector.<OrderedVertexBuffer>;
		public function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>
		{
			if (_vertexBuffer == null)
			{
				_vertexBuffer = context.createVertexBuffer(numTriangles * 2, Sprite3D.NUM_ELEMENTS_PER_VERTEX);
			}
			_vertexBuffer.uploadFromByteArray(_vertexBufferData, 0, 0, numTriangles * 2);
			
			if (_listOrderedBuffers == null)
			{
				_listOrderedBuffers = new Vector.<OrderedVertexBuffer>();
			}
			
			if (_listOrderedBuffers.length == 0)
			{
				_listOrderedBuffers.push(
					new OrderedVertexBuffer(0, _vertexBuffer, Sprite3D.VERTICES_OFFSET, Context3DVertexBufferFormat.FLOAT_3),
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
			}
			_indexBuffer.uploadFromByteArray(_indexBufferData, 0, 0, numTriangles * 3);
			
			return _indexBuffer;
		}
		
		public function get indexBufferOffset():int
		{
			return 0;
		}
	}
}