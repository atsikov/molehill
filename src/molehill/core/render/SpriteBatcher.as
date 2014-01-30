package molehill.core.render
{
	import easy.collections.LinkedList;
	import easy.collections.LinkedListElement;
	
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
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

		
		private var _atlasID:String;
		internal function getTextureAtlasID():String
		{
			return _atlasID;
		}
		
		internal function setTextureAtlasID(value:String):void
		{
			_atlasID = value;
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
			//addChildAt(sprite, numSprites - 1);
			_listSprites.enqueue(sprite);
			_needUpdateBuffers = true;
			_numSprites++;
			
			//sprite.addEventListener(Sprite3DEvent.CHANGE, onSpriteChanged);
			
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
		/*
		internal function addChildAt(sprite:Sprite3D, index:int):void
		{
			if (index >= _listSprites.length)
			{
				_listSprites.push(sprite);
			}
			else
			{
				_listSprites.splice(index, 0, sprite);
			}
			
			if (sprite.visible)
			{
				_numVisibleSprites++;
			}
			
			_needUpdateBuffers = true;
			
			sprite.addEventListener(Sprite3DEvent.CHANGE, onSpriteChanged);
		}
		*/
		/*
		internal function getChildAt(index:int):Sprite3D
		{
			if (index > numSprites)
			{
				return null;
			}
			
			return _listSprites[index];
		}
		*/
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
				_vertexBufferData = null;
			}
			
			if (_indexBufferData != null)
			{
				_indexBufferData = null;
			}
			
			_needUpdateBuffers = true;
		}
		/*
		internal function setChildIndex(child:Sprite3D, index:int):void
		{
			var childCurrentIndex:int = _listSprites.indexOf(child);
			if (childCurrentIndex == -1)
			{
				return;
			}
			
			_listSprites.splice(childCurrentIndex, 1);
			_listSprites.splice(index, 0, child);
		}
		*/
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
					//_totalIndexBufferData.push(_indexBufferData[i] + _numVertices / 9);
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
					if (sprite.hasChanged || sprite._textureChanged)
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
			/*
			var left:int = -_parent.cameraX;
			var top:int = -_parent.cameraY;
			var right:int = left + _parent.renderEngine.getViewportWidth();
			var bottom:int = top + _parent.renderEngine.getViewportHeight();
			*/
			while (cursor != null)
			{
				sprite = cursor.data as Sprite3D;
				
				indexNum = numSprites - 1 - i;
				/*
				if (sprite.hasChanged && sprite.visible)
				{
					sprite.updateValues();
				}
				
				if (sprite._x2 < left ||
					sprite._x0 > right ||
					sprite._y0 < top ||
					sprite._y1 > bottom)
				{
					cursor = cursor.next;
					continue;
				}
				*/
				var j:int;
				
				if (!sprite.visible)
				{
					sprite.hasChanged = false;
					sprite._textureChanged = false;
					/*
					nextIndexNum = (numSprites - 1 - indexNum + _numVisibleSprites) * Sprite3D.NUM_ELEMENTS_PER_VERTEX * Sprite3D.NUM_VERTICES_PER_SPRITE;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.VERTICES_OFFSET] = sprite.x0;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.VERTICES_OFFSET] = sprite.x1;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.VERTICES_OFFSET] = sprite.x2;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.VERTICES_OFFSET] = sprite.x3;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.VERTICES_OFFSET + 1] = sprite.y0;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.VERTICES_OFFSET + 1] = sprite.y1;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.VERTICES_OFFSET + 1] = sprite.y2;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.VERTICES_OFFSET + 1] = sprite.y3;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.VERTICES_OFFSET + 2] = sprite.z0;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.VERTICES_OFFSET + 2] = sprite.z1;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.VERTICES_OFFSET + 2] = sprite.z2;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.VERTICES_OFFSET + 2] = sprite.z3;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.COLOR_OFFSET] = sprite.redMultiplier;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.COLOR_OFFSET] = sprite.redMultiplier;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.COLOR_OFFSET] = sprite.redMultiplier;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.COLOR_OFFSET] = sprite.redMultiplier;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.COLOR_OFFSET + 1] = sprite.greenMultiplier;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.COLOR_OFFSET + 1] = sprite.greenMultiplier;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.COLOR_OFFSET + 1] = sprite.greenMultiplier;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.COLOR_OFFSET + 1] = sprite.greenMultiplier;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.COLOR_OFFSET + 2] = sprite.blueMultiplier;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.COLOR_OFFSET + 2] = sprite.blueMultiplier;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.COLOR_OFFSET + 2] = sprite.blueMultiplier;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.COLOR_OFFSET + 2] = sprite.blueMultiplier;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.COLOR_OFFSET + 3] = sprite.alpha;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.COLOR_OFFSET + 3] = sprite.alpha;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.COLOR_OFFSET + 3] = sprite.alpha;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.COLOR_OFFSET + 3] = sprite.alpha;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.TEXTURE_OFFSET] = sprite.textureU0;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.TEXTURE_OFFSET] = sprite.textureU1;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.TEXTURE_OFFSET] = sprite.textureU2;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.TEXTURE_OFFSET] = sprite.textureU3;
					
					_vertexBufferData[nextIndexNum + v0 + Sprite3D.TEXTURE_OFFSET + 1] = sprite.textureW0;
					_vertexBufferData[nextIndexNum + v1 + Sprite3D.TEXTURE_OFFSET + 1] = sprite.textureW1;
					_vertexBufferData[nextIndexNum + v2 + Sprite3D.TEXTURE_OFFSET + 1] = sprite.textureW2;
					_vertexBufferData[nextIndexNum + v3 + Sprite3D.TEXTURE_OFFSET + 1] = sprite.textureW3;
					
					indexNum = numSprites - 1 - indexNum + _numVisibleSprites;
					nextIndexNum = indexNum * 6;
					
					indexNum *= 4;
					
					_indexBufferData[nextIndexNum + 0] = indexNum;
					_indexBufferData[nextIndexNum + 1] = indexNum + 1;
					_indexBufferData[nextIndexNum + 2] = indexNum + 2;
					_indexBufferData[nextIndexNum + 3] = indexNum;
					_indexBufferData[nextIndexNum + 4] = indexNum + 2;
					_indexBufferData[nextIndexNum + 5] = indexNum + 3;
					*/
				}
				else
				{
					nextIndexNum = _numVisibleSprites * Sprite3D.NUM_ELEMENTS_PER_SPRITE;
					/*
					spriteVertexData = sprite.vertexData;
					for (j = 0; j < Sprite3D.NUM_ELEMENTS_PER_VERTEX * Sprite3D.NUM_VERTICES_PER_SPRITE; j++)
					{
					_vertexBufferData[nextIndexNum + j] = sprite.vertexData[j];
					}
					*/
					if (sprite.hasChanged || _needUpdateBuffers)
					{
						sprite.updateValues();
						//sprite.updateParentShiftAndScale();
						
						_vertexBufferData.position = (nextIndexNum + v0) * 4;
						_vertexBufferData.writeFloat(sprite._x0/* + sprite._parentShiftX*/);
						_vertexBufferData.writeFloat(sprite._y0/* + sprite._parentShiftY*/);
						_vertexBufferData.writeFloat(sprite._z0);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v1) * 4;
						_vertexBufferData.writeFloat(sprite._x1/* + sprite._parentShiftX*/);
						_vertexBufferData.writeFloat(sprite._y1/* + sprite._parentShiftY*/);
						_vertexBufferData.writeFloat(sprite._z1);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v2) * 4;
						_vertexBufferData.writeFloat(sprite._x2/* + sprite._parentShiftX*/);
						_vertexBufferData.writeFloat(sprite._y2/* + sprite._parentShiftY*/);
						_vertexBufferData.writeFloat(sprite._z2);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferData.position = (nextIndexNum + v3) * 4;
						_vertexBufferData.writeFloat(sprite._x3/* + sprite._parentShiftX*/);
						_vertexBufferData.writeFloat(sprite._y3/* + sprite._parentShiftY*/);
						_vertexBufferData.writeFloat(sprite._z3);
						_vertexBufferData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						var topCandidate:Number;
						var bottomCandidate:Number;
						if (sprite._y0 > sprite._y1)
						{
							topCandidate = sprite._y1;
							bottomCandidate = sprite._y0;
						}
						else
						{
							topCandidate = sprite._y0;
							bottomCandidate = sprite._y1;
						}
						
						if (_top > topCandidate)
						{
							_top = topCandidate;
						}
						if (_bottom < bottomCandidate)
						{
							_bottom = bottomCandidate;
						}
						
						if (_left > sprite._x0)
						{
							_left = sprite._x0;
						}
						if (_right < sprite._x2)
						{
							_right = sprite._x2;
						}
						/*
						if (_top > _bottom)
						{
							var tmp:Number = _bottom;
							_bottom = _top;
							_top = tmp;
						}
						*/
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
			
			_needUpdateBuffers = false;
		}
		
		internal function prepareSprites():void
		{
			updateBuffers();
		}
		
		private var _preRenderFunction:Function;
		public function get preRenderFunction():Function
		{
			return _preRenderFunction;
		}

		public function set preRenderFunction(value:Function):void
		{
			_preRenderFunction = value;
		}

		private var _postRenderFunction:Function;
		public function get postRenderFunction():Function
		{
			return _postRenderFunction;
		}

		public function set postRenderFunction(value:Function):void
		{
			_postRenderFunction = value;
		}

	}
}