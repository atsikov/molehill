package molehill.core.render.particles
{
	import easy.collections.LinkedList;
	import easy.collections.LinkedListElement;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.Scene3D;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.ParticleEmitterShader;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	
	import utils.CachingFactory;
	import utils.DebugLogger;
	
	use namespace molehill_internal;

	public class ParticleEmitter extends Sprite3D implements IVertexBatcher
	{
		private var _indicesData:ByteArray;
		
		private var _enterFrameListener:Sprite
		public function ParticleEmitter()
		{
			shader = Shader3DFactory.getInstance().getShaderInstance(ParticleEmitterShader);
			
			_indicesData = new ByteArray();
			_indicesData.endian = Endian.LITTLE_ENDIAN;
			
			_listParticles = new LinkedList();
			
			if (_cacheParticleData == null)
			{
				_cacheParticleData = new CachingFactory(ParticleData, 1000);
			}
			
			_enterFrameListener = new Sprite();
			//_enterFrameListener.addEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
		}
		
		private var _lastGenerationTime:uint = 0;
		private var _listGenerationTimes:Vector.<uint>;
		private function onNeedUpdateParticles(event:Event):void
		{
			var timer:uint = getTimer();
			
			while (_scene != null && (_lastGenerationTime == 0 || timer - _lastGenerationTime > _appearInterval))
			{
				//trace('Generating new particles. timer = ' + timer + '; lastGenerationTime = ' + _lastGenerationTime + '; num generations: ' + _listGenerationTimes.length);
				generateParticles();
				if (_lastGenerationTime == 0)
				{
					_lastGenerationTime = timer;
				}
				else
				{
					_lastGenerationTime += _appearInterval;
				}
				_listGenerationTimes.push(_lastGenerationTime);
			}
			
			while (_listGenerationTimes.length > 0 && timer - _listGenerationTimes[0] > _lifeTime)
			{
				//trace('Removing dead particles. timer = ' + timer + '; lastGenerationTime = ' + _listGenerationTimes[0] + '; num generations: ' + _listGenerationTimes.length);
				removeParticles();
				_listGenerationTimes.shift();
			}
			
			if (_scene == null && _listGenerationTimes.length == 0)
			{
				_enterFrameListener.removeEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
			}
		}
		
		override molehill_internal function setScene(value:Scene3D):void
		{
			super.setScene(value);
			
			if (value != null)
			{
				_lastGenerationTime = 0;
				if (_listGenerationTimes == null)
				{
					_listGenerationTimes = new Vector.<uint>();
				}
				_enterFrameListener.addEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
			}
			else
			{
				//_enterFrameListener.removeEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
			}
		}
		
		private var _listParticles:LinkedList;
		private var _hashParticlesByEndTime:Vector.<ParticleData>
		private var _numAddedParticles:int = 0;
		private var _numRemovedParticles:int = 0;
		private var _numTotalParticles:int = 0;
		
		private static var _cacheParticleData:CachingFactory;
		public function getParticleData():ParticleData
		{
			return _cacheParticleData.newInstance();
		}
		
		private function generateParticles():void
		{
			var timer:uint = getTimer();
			for (var i:int = 0; i < _appearCount; i++)
			{
				var particle:ParticleData = getParticleData();
				
				var radiusX:Number = _xRadius * Math.random();
				var radiusY:Number = _yRadius * Math.random();
				
				if (_emitterShape == ParticleEmitterShape.ELLIPTIC)
				{
					var angle:Number = Math.random() * 2 * Math.PI;
					particle.shiftX = radiusX * Math.cos(angle);
					particle.shiftY = radiusY * Math.sin(angle);
				}
				else
				{
					particle.shiftX = radiusX * (Math.random() >= 0.5 ? 1 : -1);
					particle.shiftY = radiusY * (Math.random() >= 0.5 ? 1 : -1);
				}
				
				particle.appearTime = timer;
				particle.lifeTime = _lifeTime;
				particle.speedX = speedX;
				particle.speedY = speedY;
				particle.accelerationX = _accelerationX;
				particle.accelerationY = _accelerationY;
				
				_listParticles.enqueue(particle);
				_numTotalParticles++;
			}
			
			_numAddedParticles += _appearCount;
		}
		
		private function removeParticles():void
		{
			var numParticles:uint = _numTotalParticles;
			var cursor:LinkedListElement = _listParticles.head;
			var next:LinkedListElement;
			
			var i:int = 0;
			
			var time:uint = getTimer();
			var maxGeneratedTime:int = time - _lifeTime;
			
			while (i < _appearCount && cursor != null)
			{
				var particleData:ParticleData = cursor.data as ParticleData;
				next = cursor.next;
				
				if (particleData.appearTime + particleData.lifeTime < time)
				{
					_listParticles.removeElement(cursor);
					_cacheParticleData.storeInstance(particleData);
					_numTotalParticles--;
				}
				
				cursor = next;
			}
			_numRemovedParticles += numParticles - _numTotalParticles;
			//trace("Removed " + _numRemovedParticles + " particles");
		}
		
		private var _emitterShape:String = ParticleEmitterShape.ELLIPTIC;
		public function get emitterShape():String
		{
			return _emitterShape;
		}
		
		public function set emitterShape(value:String):void
		{
			_emitterShape = value;
		}
		
		private var _xRadius:Number = 0;
		public function get xRadius():Number
		{
			return _xRadius;
		}

		public function set xRadius(value:Number):void
		{
			_xRadius = value;
		}

		private var _yRadius:Number = 0;
		public function get yRadius():Number
		{
			return _yRadius;
		}

		public function set yRadius(value:Number):void
		{
			_yRadius = value;
		}

		private var _speedX:Number = 0;
		public function get speedX():Number
		{
			return _speedX;
		}

		public function set speedX(value:Number):void
		{
			_speedX = value;
		}

		private var _speedY:Number = 0;
		public function get speedY():Number
		{
			return _speedY;
		}

		public function set speedY(value:Number):void
		{
			_speedY = value;
		}

		private var _accelerationX:Number = 0;
		public function get accelerationX():Number
		{
			return _accelerationX;
		}

		public function set accelerationX(value:Number):void
		{
			_accelerationX = value;
		}

		private var _accelerationY:Number = 0;
		public function get accelerationY():Number
		{
			return _accelerationY;
		}

		public function set accelerationY(value:Number):void
		{
			_accelerationY = value;
		}

		private var _lifeTime:int;
		public function get lifeTime():int
		{
			return _lifeTime;
		}
		
		public function set lifeTime(value:int):void
		{
			_lifeTime = value;
		}
		
		private var _appearInterval:int;
		public function get appearInterval():int
		{
			return _appearInterval;
		}

		public function set appearInterval(value:int):void
		{
			_appearInterval = value;
		}

		private var _appearCount:int;
		public function get appearCount():int
		{
			return _appearCount;
		}

		public function set appearCount(value:int):void
		{
			_appearCount = value;
		}
		
		override public function setTexture(value:String):void
		{
			super.setTexture(value);
			
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(value);
			_textureAtlasID = atlas != null ? atlas.atlasID : null;
		}
		
		// IVertexBatcher implementation
		private var _vertexData:ByteArray;
		private var _spriteVertexData:ByteArray;
		private var _emptyByteArray:ByteArray;
		private var _mainVerticesDataChanged:Boolean = false;
		public function getVerticesData():ByteArray
		{
			updateScrollableContainerValues();
			if (_vertexData == null)
			{
				_vertexData = new ByteArray();
				_vertexData.endian = Endian.LITTLE_ENDIAN;
			}
			
			updateValues();
			
			if (hasChanged)
			{
				if (_spriteVertexData == null)
				{
					_spriteVertexData = new ByteArray();
					_spriteVertexData.endian = Endian.LITTLE_ENDIAN;
				}
				
				_spriteVertexData.position = 0;
				_spriteVertexData.writeFloat(_x0);
				_spriteVertexData.writeFloat(_y0);
				//_spriteVertexData.writeFloat(_z0);
				_spriteVertexData.writeFloat(_redMultiplier * _parentRed);
				_spriteVertexData.writeFloat(_greenMultiplier * _parentGreen);
				_spriteVertexData.writeFloat(_blueMultiplier * _parentBlue);
				_spriteVertexData.writeFloat(_alpha * _parentAlpha);
				_spriteVertexData.writeFloat(_textureU0);
				_spriteVertexData.writeFloat(_textureW0);
				
				_spriteVertexData.writeFloat(_x1);
				_spriteVertexData.writeFloat(_y1);
				//_spriteVertexData.writeFloat(_z1);
				_spriteVertexData.writeFloat(_redMultiplier * _parentRed);
				_spriteVertexData.writeFloat(_greenMultiplier * _parentGreen);
				_spriteVertexData.writeFloat(_blueMultiplier * _parentBlue);
				_spriteVertexData.writeFloat(_alpha * _parentAlpha);
				_spriteVertexData.writeFloat(_textureU1);
				_spriteVertexData.writeFloat(_textureW1);
				
				_spriteVertexData.writeFloat(_x2);
				_spriteVertexData.writeFloat(_y2);
				//_spriteVertexData.writeFloat(_z2);
				_spriteVertexData.writeFloat(_redMultiplier * _parentRed);
				_spriteVertexData.writeFloat(_greenMultiplier * _parentGreen);
				_spriteVertexData.writeFloat(_blueMultiplier * _parentBlue);
				_spriteVertexData.writeFloat(_alpha * _parentAlpha);
				_spriteVertexData.writeFloat(_textureU2);
				_spriteVertexData.writeFloat(_textureW2);
				
				_spriteVertexData.writeFloat(_x3);
				_spriteVertexData.writeFloat(_y3);
				//_spriteVertexData.writeFloat(_z3);
				_spriteVertexData.writeFloat(_redMultiplier * _parentRed);
				_spriteVertexData.writeFloat(_greenMultiplier * _parentGreen);
				_spriteVertexData.writeFloat(_blueMultiplier * _parentBlue);
				_spriteVertexData.writeFloat(_alpha * _parentAlpha);
				_spriteVertexData.writeFloat(_textureU3);
				_spriteVertexData.writeFloat(_textureW3);
			}
			
			
			if (_emptyByteArray == null)
			{
				_emptyByteArray = new ByteArray();
			}
			
			return getIndicesData(0);
		}
		
		private var _lastPassedVertices:uint = int.MAX_VALUE;
		private var _indicesChanged:Boolean = false;
		public function getIndicesData(passedVertices:uint):ByteArray
		{
			var numParticles:uint = _numTotalParticles;
			var numPassedParticles:uint = _indicesData.length / 12; // 2 bytes per index * 6 indices per particle (quad)
			
			if (numParticles != numPassedParticles)
			{
				_indicesChanged = true;
				if (numParticles > numPassedParticles)
				{
					_indicesData.position = _indicesData.length;
					for (var i:int = numPassedParticles; i < numParticles; i++)
					{
						_indicesData.writeShort(i * 4);
						_indicesData.writeShort(i * 4 + 1);
						_indicesData.writeShort(i * 4 + 2);
						
						_indicesData.writeShort(i * 4);
						_indicesData.writeShort(i * 4 + 2);
						_indicesData.writeShort(i * 4 + 3);
					}
				}
				else
				{
					//_indicesData.length = numParticles * 12;
				}
			}
			
			return _emptyByteArray;
		}
		
		public function get numTriangles():uint
		{
			//trace(_listParticles.length * 2);
			return _numTotalParticles * 2;
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
					_batcherCamera.scrollY += referenceCamera.scrollY;
					_batcherCamera.scale *= referenceCamera.scale;
				}
				
				parent = parent.parent;
			}
		}
		
		private var _left:Number = int.MIN_VALUE;
		
		public function get left():Number
		{
			return _x0;
		}
		
		private var _right:Number = int.MAX_VALUE;
		
		public function get right():Number
		{
			return _x2;
		}
		
		private var _top:Number = int.MIN_VALUE;
		
		public function get top():Number
		{
			return _y1;
		}
		
		private var _bottom:Number = int.MAX_VALUE;
		
		public function get bottom():Number
		{
			return _y0;
		}
		
		private var _additionalVertexBufferData:ByteArray;
		private var _lastMainBufferSize:int = 0;
		private var _listAdditionalVertexBuffers:Vector.<OrderedVertexBuffer>;
		private var _lastAdditionalBufferSize:int = 0;
		
		private var _mainVertexBuffer:VertexBuffer3D;
		private var _additionalVertexBuffer:VertexBuffer3D;
		private var _tempBuffer:ByteArray;
		public function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>
		{
			if (_additionalVertexBufferData == null)
			{
				_additionalVertexBufferData = new ByteArray();
				_additionalVertexBufferData.endian = Endian.LITTLE_ENDIAN;
			}
			
			if (_listAdditionalVertexBuffers == null)
			{
				_listAdditionalVertexBuffers = new Vector.<OrderedVertexBuffer>();
				_listAdditionalVertexBuffers.length = 5;
				_listAdditionalVertexBuffers.fixed = true;
			}
			
			var numParticles:uint = _numTotalParticles;
			
			// 8 floats per vertex * 4 vertices per sprite (quad) * 4 bytes per float = 128
			var bytesPerParticle:int = 128;
			
			// 8 floats per vertex * 4 vertices per sprite (quad) * 4 bytes per float = 128
			var bytesPerAdditionalParticleData:uint = 128;
			
			var numStoredParticles:uint = _vertexData.length / bytesPerParticle;
			if (_numRemovedParticles != 0 || _numAddedParticles != 0)
			{
				if (_numRemovedParticles > 0)
				{
					if (_numRemovedParticles >= numStoredParticles)
					{
						_vertexData.position = 0;
						_vertexData.length = 0;
					}
					else
					{
						var bytesOffset:uint = _numRemovedParticles * bytesPerParticle;
						_vertexData.position = 0;
						_vertexData.writeBytes(_vertexData, bytesOffset);
						_vertexData.length = _vertexData.length - bytesOffset;
					}
					numStoredParticles = _vertexData.length / bytesPerParticle;
				}
				
				_vertexData.position = _vertexData.length;
				for (var i:int = numStoredParticles; i < numParticles; i++)
				{
					_vertexData.writeBytes(_spriteVertexData);
				}
				_vertexData.length = numParticles * bytesPerParticle;
				_mainVerticesDataChanged = true;
				
				_additionalVertexBufferData.position = 0;
				numStoredParticles = _additionalVertexBufferData.length / bytesPerAdditionalParticleData;
				if (_numRemovedParticles > 0)
				{
					if (_numRemovedParticles >= numStoredParticles)
					{
						_additionalVertexBufferData.position = 0;
						_additionalVertexBufferData.length = 0;
					}
					else
					{
						bytesOffset = _numRemovedParticles * bytesPerAdditionalParticleData;
						_additionalVertexBufferData.writeBytes(_additionalVertexBufferData, bytesOffset);
						_additionalVertexBufferData.length = _additionalVertexBufferData.length - bytesOffset;
					}
					numStoredParticles = _additionalVertexBufferData.length / bytesPerAdditionalParticleData;
				}
				
				_numRemovedParticles = 0;
				_numAddedParticles = 0;
				
				if (_tempBuffer == null)
				{
					_tempBuffer = new ByteArray();
					_tempBuffer.endian = Endian.LITTLE_ENDIAN;
				}
				
				_tempBuffer.position = 0;
				
				_additionalVertexBufferData.position = _additionalVertexBufferData.length;
				
				i = 0;
				var cursor:LinkedListElement = _listParticles.head;
				while (i < numStoredParticles && cursor != null)
				{
					cursor = cursor.next;
					i++;
				}
				
				while (i < numParticles && cursor != null)
				{
					var particle:ParticleData = cursor.data as ParticleData;
					
					//trace("====================>>>>>>>>>> " + particle.appearTime, particle.shiftX, particle.shiftY);
					
					// va3
					_tempBuffer.writeFloat(particle.shiftX);
					_tempBuffer.writeFloat(particle.shiftY);
					_tempBuffer.writeFloat(particle.appearTime);
					_tempBuffer.writeFloat(particle.lifeTime);
					// va4
					_tempBuffer.writeFloat(particle.speedX);
					_tempBuffer.writeFloat(particle.speedY);
					_tempBuffer.writeFloat(particle.accelerationX);
					_tempBuffer.writeFloat(particle.accelerationY);
					
					for (var j:int = 0; j < 4; j++)
					{
						_additionalVertexBufferData.writeBytes(_tempBuffer);
					}
					
					_tempBuffer.position = 0;
					
					cursor = cursor.next;
				}
				
				if (_additionalVertexBuffer == null || _lastAdditionalBufferSize != numParticles)
				{
					if (_additionalVertexBuffer != null && _lastAdditionalBufferSize != numParticles)
					{
						_additionalVertexBuffer.dispose();
						_additionalVertexBuffer = null;
					}
					
					if (_additionalVertexBuffer == null)
					{
						_additionalVertexBuffer = context.createVertexBuffer(numParticles * 4, 8);
					}
					//trace('creating additional buffer for ' + numParticles + ' particles');
					_lastAdditionalBufferSize = numParticles;
					
					var orderedVertexBuffer:OrderedVertexBuffer = new OrderedVertexBuffer(3, _additionalVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
					_listAdditionalVertexBuffers[3] = orderedVertexBuffer;
					
					orderedVertexBuffer = new OrderedVertexBuffer(4, _additionalVertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_4);
					_listAdditionalVertexBuffers[4] = orderedVertexBuffer;

				}
				_additionalVertexBuffer.uploadFromByteArray(_additionalVertexBufferData, 0, 0, numParticles * 4);
			}
				
			if (_mainVertexBuffer == null || _lastMainBufferSize != numParticles)
			{
				if (_mainVertexBuffer != null && _lastMainBufferSize != numParticles)
				{
					_mainVertexBuffer.dispose();
					_mainVertexBuffer = null;
				}
				
				if (numParticles > 0)
				{
					if (_mainVertexBuffer == null)
					{
						_mainVertexBuffer = context.createVertexBuffer(numParticles * 4, Sprite3D.NUM_ELEMENTS_PER_VERTEX);
						_mainVerticesDataChanged = true;
					}
					
					orderedVertexBuffer = new OrderedVertexBuffer(0, _mainVertexBuffer, Sprite3D.VERTICES_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
					_listAdditionalVertexBuffers[0] = orderedVertexBuffer;
					
					orderedVertexBuffer = new OrderedVertexBuffer(1, _mainVertexBuffer, Sprite3D.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
					_listAdditionalVertexBuffers[1] = orderedVertexBuffer;
					
					orderedVertexBuffer = new OrderedVertexBuffer(2, _mainVertexBuffer, Sprite3D.TEXTURE_OFFSET, Context3DVertexBufferFormat.FLOAT_2);
					_listAdditionalVertexBuffers[2] = orderedVertexBuffer;
					
					_lastMainBufferSize = numParticles;
				}
			}
			
			if (_mainVertexBuffer != null && _mainVerticesDataChanged)
			{
				_mainVertexBuffer.uploadFromByteArray(_vertexData, 0, 0, numParticles * 4);
				_mainVerticesDataChanged = false;
			}
				
			return _listAdditionalVertexBuffers;
		}
		
		private var _indexBuffer:IndexBuffer3D;
		private var _indexBufferSize:uint = 0;
		public function getCustomIndexBuffer(context:Context3D):IndexBuffer3D
		{
			var numParticles:uint = _numTotalParticles;
			if (_indexBuffer != null && _indexBufferSize != numParticles * 6)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			
			if (_indexBuffer == null)
			{
				_indexBufferSize = numParticles * 6;
				_indexBuffer = context.createIndexBuffer(_indexBufferSize);
				_indicesChanged = true;
			}
			if (_indicesChanged)
			{
				_indexBuffer.uploadFromByteArray(_indicesData, 0, 0, _indexBufferSize);
				_indicesChanged = false;
			}
			
			return _indexBuffer;
		}
		
		public function get indexBufferOffset():int
		{
			return 0;
		}
		
		public function onContextRestored():void
		{
			if (_mainVertexBuffer != null)
			{
				_mainVertexBuffer.dispose();
				_mainVertexBuffer = null;
			}
			
			if (_additionalVertexBuffer != null)
			{
				_additionalVertexBuffer.dispose();
				_additionalVertexBuffer = null;
			}
			
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
		}
	}
}
