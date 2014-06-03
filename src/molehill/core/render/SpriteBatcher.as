package molehill.core.render
{
	import easy.collections.LinkedList;
	import easy.collections.LinkedListElement;
	import easy.collections.TreeNode;
	
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	
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
			if (value != null && TextureManager.getInstance().getAtlasDataByID(value) == null)
			{
				throw new Error("Bad atlas id!");
			}
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
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(sprite.textureID);
			//trace(StringUtils.getObjectAddress(this) + ' | ' + _textureAtlasID + ' + -> ' + StringUtils.getObjectAddress(sprite) + ' | '+ sprite.textureID + ' | ' + (atlas == null ? 'null' : atlas.atlasID));
			_listSprites.enqueue(sprite);
			_needUpdateBuffers = true;
			_numSprites++;
		}
		
		internal function addChildBefore(child1:Sprite3D, child2:Sprite3D):void
		{
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(child2.textureID);
			//trace(StringUtils.getObjectAddress(this) + ' | ' + _textureAtlasID + ' + -> ' + StringUtils.getObjectAddress(child2) + ' | '+ child2.textureID + ' | ' + (atlas == null ? 'null' : atlas.atlasID));
			
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
		}
		
		
		internal function addChildAfter(child1:Sprite3D, child2:Sprite3D):void
		{
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(child2.textureID);
			//trace(StringUtils.getObjectAddress(this) + ' | ' + _textureAtlasID + ' + -> ' + StringUtils.getObjectAddress(child2) + ' | '+ child2.textureID + ' | ' + (atlas == null ? 'null' : atlas.atlasID));
			
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
			
			if (_vertexBufferVerticesData != null)
			{
				_vertexBufferVerticesData.length = 0;
				_vertexBufferVerticesData = null;
			}
			
			if (_indexBufferData != null)
			{
				_indexBufferData.length = 0;
				_indexBufferData = null;
			}
		}
		
		internal function pushSpriteContainerTree(container:Sprite3DContainer):void
		{
			var root:TreeNode = container.localRenderTree.firstChild;
			
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
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(sprite.textureID);
			//trace(StringUtils.getObjectAddress(this) + ' | ' + _textureAtlasID + ' - -> ' + StringUtils.getObjectAddress(sprite) + ' | ' + sprite.textureID + ' | ' + (atlas == null ? 'null' : atlas.atlasID));
			
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
			
			_needUpdateBuffers = true;
			_numVisibleSprites = 0;
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
			result._batcherCamera = _batcherCamera;
			result._shader = shader;
			result._listSprites = _listSprites.splitAtElement(element);
			result._numSprites = _numSprites - childIndex;
			result._numVisibleSprites = result._numSprites;
			result._needUpdateBuffers = true;
			
			_indexBufferData = null;
			_vertexBufferVerticesData = null;
			
			_needUpdateBuffers = true;
			_numSprites = childIndex;
			_numVisibleSprites = 0;
			
			//trace('splitting batcher: ' + StringUtils.getObjectAddress(this) + ' + ' + StringUtils.getObjectAddress(result));
			
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
			
			_batcherCamera.copyValues(referenceCamera);
			
			var parent:Sprite3DContainer = _cameraOwner.parent;
			while (parent != null)
			{
				referenceCamera = parent.camera;
				if (referenceCamera != null)
				{
					_batcherCamera.scrollX += referenceCamera.scrollX;
					_batcherCamera.scrollY += referenceCamera.scrollY;
					_batcherCamera.scale *= referenceCamera.scale;
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
		
		private var _vertexBufferVerticesData:ByteArray;
		private var _vertexBufferColorData:ByteArray;
		private var _vertexBufferTextureData:ByteArray;
		public function getVerticesData():ByteArray
		{
			prepareSprites();
			return _vertexBufferVerticesData;
		}

		private var _indexBufferData:ByteArray;
		private var _lastPassedVertices:uint = 0;
		public function getIndicesData(passedVertices:uint):ByteArray
		{
			/*
			if (passedVertices != _lastPassedVertices)
			{
				_indexBufferData.position = 0;
				var shift:int = 0; //passedVertices / 9 - _lastPassedVertices / 9;
				for (var i:int = 0; i < _indexBufferData.length / 2; i++)
				{
					var index:int = _indexBufferData.readShort();
					_indexBufferData.position -= 2;
					_indexBufferData.writeShort(index + shift);
				}
				
				_lastPassedVertices = passedVertices;
			}
			*/
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
		
		private var _needUploadVertexData:Boolean = true;
		private var _needUploadColorData:Boolean = true;
		private var _needUploadTextureData:Boolean = true;
		
		private var _needUploadIndexData:Boolean = true;
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
					if (sprite.hasChanged || sprite._colorChanged || sprite._textureChanged)
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
			
			if (_vertexBufferVerticesData == null)
			{
				_vertexBufferVerticesData = new ByteArray();
				_vertexBufferVerticesData.endian = Endian.LITTLE_ENDIAN;
			}
			
			if (_vertexBufferColorData == null)
			{
				_vertexBufferColorData = new ByteArray();
				_vertexBufferColorData.endian = Endian.LITTLE_ENDIAN;
			}
			
			if (_vertexBufferTextureData == null)
			{
				_vertexBufferTextureData = new ByteArray();
				_vertexBufferTextureData.endian = Endian.LITTLE_ENDIAN;
			}
			
			if (_indexBufferData == null)
			{
				_indexBufferData = new ByteArray();
				_indexBufferData.endian = Endian.LITTLE_ENDIAN;
			}
			
			cursor = _listSprites.head;
			while (cursor != null)
			{
				sprite = cursor.data as Sprite3D;
				
				var isOnScreen:Boolean = true;
				if (!sprite.visible)
				{
					sprite.markChanged(false);
					sprite._textureChanged = false;
					sprite._colorChanged = false;
				}
				else
				{
					if (sprite.updateOnRender)
					{
						sprite.updateValues();
					}
					
					if (sprite.hasChanged || _needUpdateBuffers)
					{
						_vertexBufferVerticesData.position = _numVisibleSprites * 32;
						_vertexBufferVerticesData.writeFloat(sprite._vertexX0);
						_vertexBufferVerticesData.writeFloat(sprite._vertexY0);
						//_vertexBufferVerticesData.writeFloat(sprite._z0);
						
						_vertexBufferVerticesData.writeFloat(sprite._vertexX1);
						_vertexBufferVerticesData.writeFloat(sprite._vertexY1);
						//_vertexBufferVerticesData.writeFloat(sprite._z1);
						
						_vertexBufferVerticesData.writeFloat(sprite._vertexX2);
						_vertexBufferVerticesData.writeFloat(sprite._vertexY2);
						//_vertexBufferVerticesData.writeFloat(sprite._z2);
						
						_vertexBufferVerticesData.writeFloat(sprite._vertexX3);
						_vertexBufferVerticesData.writeFloat(sprite._vertexY3);
						//_vertexBufferVerticesData.writeFloat(sprite._z3);
						
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
						
						sprite.markChanged(false);
						
						_needUploadVertexData = true;
					}
					
					if (sprite._colorChanged || _needUpdateBuffers)
					{
						_vertexBufferColorData.position = _numVisibleSprites * 64;
						_vertexBufferColorData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferColorData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferColorData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferColorData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferColorData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferColorData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferColorData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferColorData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferColorData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferColorData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferColorData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferColorData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						_vertexBufferColorData.writeFloat(sprite._redMultiplier * sprite._parentRed);
						_vertexBufferColorData.writeFloat(sprite._greenMultiplier * sprite._parentGreen);
						_vertexBufferColorData.writeFloat(sprite._blueMultiplier * sprite._parentBlue);
						_vertexBufferColorData.writeFloat(sprite._alpha * sprite._parentAlpha);
						
						sprite._colorChanged = false;
						
						_needUploadColorData = true;
					}
					
					if (sprite._textureChanged || _needUpdateBuffers)
					{
						_vertexBufferTextureData.position = _numVisibleSprites * 32;
						_vertexBufferTextureData.writeFloat(sprite._textureU0);
						_vertexBufferTextureData.writeFloat(sprite._textureW0);
						
						_vertexBufferTextureData.writeFloat(sprite._textureU1);
						_vertexBufferTextureData.writeFloat(sprite._textureW1);
						
						_vertexBufferTextureData.writeFloat(sprite._textureU2);
						_vertexBufferTextureData.writeFloat(sprite._textureW2);
						
						_vertexBufferTextureData.writeFloat(sprite._textureU3);
						_vertexBufferTextureData.writeFloat(sprite._textureW3);
						
						sprite._textureChanged = false;
						
						_needUploadTextureData = true;
					}
					
					if (_needUpdateBuffers)
					{
						var indexNum:uint = _numVisibleSprites * 4;
						
						_indexBufferData.position = _numVisibleSprites * 12;
						_indexBufferData.writeShort(indexNum);
						_indexBufferData.writeShort(indexNum + 1);
						_indexBufferData.writeShort(indexNum + 2);
						_indexBufferData.writeShort(indexNum);
						_indexBufferData.writeShort(indexNum + 2);
						_indexBufferData.writeShort(indexNum + 3);
						
					}
					_numVisibleSprites++;
				}
				/*
				if (_numVisibleSprites > _vertexBufferVerticesData.length / 32 || _numVisibleSprites > _vertexBufferTextureData.length / 32)
				{
					throw new Error('Broken batcher');
				}
				*/
				sprite.resetVisibilityChanged();
				
				cursor = cursor.next;
			}
			
			if (currentNumVisibleSprites < _numVisibleSprites)
			{
				if (_vertexBufferVertices != null)
				{
					_vertexBufferVertices.dispose()
				}
				
				if (_vertexBufferColor != null)
				{
					_vertexBufferColor.dispose()
				}
				
				if (_vertexBufferTexture != null)
				{
					_vertexBufferTexture.dispose()
				}
				
				if (_indexBuffer != null)
				{
					_indexBuffer.dispose()
				}
				
				_vertexBufferVertices = null;
				_vertexBufferColor = null;
				_vertexBufferTexture = null;
				
				_indexBuffer = null;
				
				_needUploadVertexData = true;
				_needUploadColorData = true;
				_needUploadTextureData = true;
				
				_needUploadIndexData = true;
			}
			
			_needUpdateBuffers = false;
		}
		
		internal function prepareSprites():void
		{
			updateBuffers();
			
			if (_cameraOwner != null)
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
		
		private var _vertexBufferVertices:VertexBuffer3D;
		private var _vertexBufferColor:VertexBuffer3D;
		private var _vertexBufferTexture:VertexBuffer3D;
		
		private var _listOrderedBuffers:Vector.<OrderedVertexBuffer>;
		public function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>
		{
			var vertexBufferChanged:Boolean = false;
			if (_vertexBufferVertices == null)
			{
				_vertexBufferVertices = context.createVertexBuffer(_numVisibleSprites * 4, 2);
				_vertexBufferColor = context.createVertexBuffer(_numVisibleSprites * 4, 4);
				_vertexBufferTexture = context.createVertexBuffer(_numVisibleSprites * 4, 2);
				
				vertexBufferChanged = true;
			}
			if (_needUploadVertexData)
			{
				/*
				trace("Vertex Data");
				for (var i:int = 0; i < _vertexBufferVerticesData.length; i+= 8)
				{
					_vertexBufferVerticesData.position = i;
					trace("coords: " + _vertexBufferVerticesData.readFloat() + ", " + _vertexBufferVerticesData.readFloat());
				}
				*/
				_vertexBufferVertices.uploadFromByteArray(_vertexBufferVerticesData, 0, 0, _numVisibleSprites * 4);
				_needUploadVertexData = false;
			}
			if (_needUploadColorData)
			{
				/*
				trace("Color Data");
				for (var i:int = 0; i < _vertexBufferColorData.length; i+= 16)
				{
					_vertexBufferColorData.position = i;
					trace("Color components: " + _vertexBufferColorData.readFloat() + ", " + _vertexBufferColorData.readFloat() + ", " + _vertexBufferColorData.readFloat() + ", " + _vertexBufferColorData.readFloat());
				}
				*/
				_vertexBufferColor.uploadFromByteArray(_vertexBufferColorData, 0, 0, _numVisibleSprites * 4);
				_needUploadColorData = false;
			}
			if (_needUploadTextureData)
			{
				/*
				trace("Texture Data");
				for (var i:int = 0; i < _vertexBufferTextureData.length; i+= 8)
				{
					_vertexBufferTextureData.position = i;
					trace("texture coords: " + _vertexBufferTextureData.readFloat() + ", " + _vertexBufferTextureData.readFloat());
				}
				*/
				_vertexBufferTexture.uploadFromByteArray(_vertexBufferTextureData, 0, 0, _numVisibleSprites * 4);
				_needUploadTextureData = false;
			}
			
			if (_listOrderedBuffers == null)
			{
				_listOrderedBuffers = new Vector.<OrderedVertexBuffer>();
			}
			
			if (_listOrderedBuffers.length == 0)
			{
				_listOrderedBuffers.push(
					new OrderedVertexBuffer(0, _vertexBufferVertices, 0, Context3DVertexBufferFormat.FLOAT_2),
					new OrderedVertexBuffer(1, _vertexBufferColor, 0, Context3DVertexBufferFormat.FLOAT_4),
					new OrderedVertexBuffer(2, _vertexBufferTexture, 0, Context3DVertexBufferFormat.FLOAT_2)
				);
				_listOrderedBuffers.fixed = true;
			}
			else if (vertexBufferChanged)
			{
				_listOrderedBuffers[0].buffer = _vertexBufferVertices;
				_listOrderedBuffers[1].buffer = _vertexBufferColor;
				_listOrderedBuffers[2].buffer = _vertexBufferTexture;
			}
			
			return _listOrderedBuffers;
		}
		
		private var _indexBuffer:IndexBuffer3D;
		public function getCustomIndexBuffer(context:Context3D):IndexBuffer3D
		{
			if (_indexBuffer == null)
			{
				_indexBuffer = context.createIndexBuffer(_numVisibleSprites * 6);
			}
			if (_needUploadIndexData)
			{
				/*
				trace("Index Data");
				for (var i:int = 0; i < _indexBufferData.length; i+= 12)
				{
					_indexBufferData.position = i;
					trace(_indexBufferData.readUnsignedShort() + ", " +
						_indexBufferData.readUnsignedShort() + ", " +
						_indexBufferData.readUnsignedShort() + ", " +
						_indexBufferData.readUnsignedShort() + ", " +
						_indexBufferData.readUnsignedShort() + ", " +
						_indexBufferData.readUnsignedShort()
					);
				}
				*/
				_indexBuffer.uploadFromByteArray(_indexBufferData, 0, 0, _numVisibleSprites * 6);
				_needUploadIndexData = false;
			}
			
			return _indexBuffer;
		}
		
		public function get indexBufferOffset():int
		{
			return 0;
		}
		
		public function onContextRestored():void
		{
			if (_vertexBufferVertices != null)
			{
				_vertexBufferVertices.dispose();
				_vertexBufferVertices = null;
			}
			
			if (_vertexBufferColor != null)
			{
				_vertexBufferColor.dispose();
				_vertexBufferColor = null;
			}
			
			if (_vertexBufferTexture != null)
			{
				_vertexBufferTexture.dispose();
				_vertexBufferTexture = null;
			}
			
			_needUploadVertexData = true;
			_needUploadColorData = true;
			_needUploadTextureData = true;
			
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			
			_needUploadIndexData = true;
		}
	}
}