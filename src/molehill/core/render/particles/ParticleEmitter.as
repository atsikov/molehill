package molehill.core.render.particles
{
	import easy.collections.LinkedList;
	import easy.collections.LinkedListElement;
	
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getTimer;
	
	import molehill.core.Scene3DManager;
	import molehill.core.molehill_internal;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.ProgramConstantsData;
	import molehill.core.render.Scene3D;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.ParticleEmitterShader;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	import utils.CachingFactory;
	
	use namespace molehill_internal;

	public class ParticleEmitter extends Sprite3D implements IVertexBatcher
	{
		private var _indicesData:ByteArray;
		
		private var _enterFrameListener:Sprite
		public function ParticleEmitter()
		{
			shader = Shader3DFactory.getInstance().getShaderInstance(
				getQualifiedClassName(ParticleEmitterShader)
			);
			
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
		
		private var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}
		
		public function set enabled(value:Boolean):void
		{
			_enabled = value;
			
			if (!value)
			{
				_enterFrameListener.removeEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
			}
			else
			{
				_enterFrameListener.addEventListener(Event.ENTER_FRAME, onNeedUpdateParticles);
			}
		}
		
		private var _lastGenerationTime:uint = 0;
		private var _listGenerationTimes:Vector.<uint>;
		private function onNeedUpdateParticles(event:Event):void
		{
			var timer:uint = getTimer();
			
			if (_appearInterval == 0 ||
				textureID == null ||
				_scene == null ||
				!_enabled)
			{
				return;
			}
			
			var textureAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByID(_textureAtlasID);
			var textureData:TextureData = textureAtlasData != null ? textureAtlasData.getTextureData(textureID) : null;
			if (textureData == null)
			{
				return;
			}
			
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
				onContextRestored();
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
				
				//trace("new particle: " + particle.shiftX, particle.shiftY);
				
				particle.appearTime = timer;
				particle.lifeTime = _lifeTime;
				particle.speedX = _speedX + (Math.random() - 0.5) * 2 * _speedXDeviation;
				particle.speedY = _speedY + (Math.random() - 0.5) * 2 * _speedYDeviation;
				particle.accelerationX = _accelerationX + (Math.random() - 0.5) * 2 * _accelerationXDeviation;
				particle.accelerationY = _accelerationY + (Math.random() - 0.5) * 2 * _accelerationYDeviation;
				
				particle.startScale = _startScale + (Math.random() - 0.5) * 2 * _startScaleDeviation;
				particle.endScale = _endScale + (Math.random() - 0.5) * 2 * _endScaleDeviation;
				
				particle.startAlpha = _startAlpha;
				particle.endAlpha = _endAlpha;
				
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
				
				if (particleData.disappearTime < time)
				{
					_listParticles.removeElement(cursor);
					_cacheParticleData.storeInstance(particleData);
					_numTotalParticles--;
				}
				
				cursor = next;
			}
			_numRemovedParticles += numParticles - _numTotalParticles;
			//trace("Removed " + _numRemovedParticles + " particles, " + _numTotalParticles + " particles left");
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

		private var _speedXDeviation:Number = 0;
		public function get speedXDeviation():Number
		{
			return _speedXDeviation;
		}

		public function set speedXDeviation(value:Number):void
		{
			_speedXDeviation = value;
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

		private var _speedYDeviation:Number = 0;
		public function get speedYDeviation():Number
		{
			return _speedYDeviation;
		}

		public function set speedYDeviation(value:Number):void
		{
			_speedYDeviation = value;
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

		private var _accelerationXDeviation:Number = 0;
		public function get accelerationXDeviation():Number
		{
			return _accelerationXDeviation;
		}

		public function set accelerationXDeviation(value:Number):void
		{
			_accelerationXDeviation = value;
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
		
		private var _accelerationYDeviation:Number = 0;
		public function get accelerationYDeviation():Number
		{
			return _accelerationYDeviation;
		}

		public function set accelerationYDeviation(value:Number):void
		{
			_accelerationYDeviation = value;
		}

		
		private var _startScale:Number = 1;
		public function get startScale():Number
		{
			return _startScale;
		}

		public function set startScale(value:Number):void
		{
			_startScale = value;
		}

		private var _endScale:Number = 1;
		public function get endScale():Number
		{
			return _endScale;
		}

		public function set endScale(value:Number):void
		{
			_endScale = value;
		}

		private var _startScaleDeviation:Number = 0;
		public function get startScaleDeviation():Number
		{
			return _startScaleDeviation;
		}

		public function set startScaleDeviation(value:Number):void
		{
			_startScaleDeviation = value;
		}

		private var _endScaleDeviation:Number = 0;
		public function get endScaleDeviation():Number
		{
			return _endScaleDeviation;
		}

		public function set endScaleDeviation(value:Number):void
		{
			_endScaleDeviation = value;
		}


		private var _lifeTime:int = 0;
		public function get lifeTime():int
		{
			return _lifeTime;
		}
		
		public function set lifeTime(value:int):void
		{
			_lifeTime = value;
		}
		
		private var _appearInterval:int = 0;
		public function get appearInterval():int
		{
			return _appearInterval;
		}

		public function set appearInterval(value:int):void
		{
			_appearInterval = value;
		}

		private var _appearCount:int = 0;
		public function get appearCount():int
		{
			return _appearCount;
		}

		public function set appearCount(value:int):void
		{
			_appearCount = value;
		}
		
		private var _startAlpha:Number = 1;
		public function get startAlpha():Number
		{
			return _startAlpha;
		}

		public function set startAlpha(value:Number):void
		{
			_startAlpha = value;
		}

		private var _endAlpha:Number = 1;
		public function get endAlpha():Number
		{
			return _endAlpha;
		}

		public function set endAlpha(value:Number):void
		{
			_endAlpha = value;
		}

		override public function setTexture(value:String):void
		{
			super.setTexture(value);
			
			var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(value);
			_textureAtlasID = atlas != null ? atlas.atlasID : null;
		}
		
		// IVertexBatcher implementation
		private var _vertexData:ByteArray;
		private var _emptyByteArray:ByteArray;
		private var _verticesDataChanged:Boolean = false;
		public function getVerticesData():ByteArray
		{
			updateScrollableContainerValues();
			if (_vertexData == null)
			{
				_vertexData = new ByteArray();
				_vertexData.endian = Endian.LITTLE_ENDIAN;
			}
			
			updateValues();
			
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
				//_indicesChanged = true;
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
						
						//trace(i * 4, i * 4 + 1, i * 4 + 2, i * 4, i * 4 + 2, i * 4 + 3);
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
			if (!visibleWithParent)
			{
				return 0;
			}
			
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
			return _x0 - _xRadius;
		}
		
		private var _right:Number = int.MAX_VALUE;
		
		public function get right():Number
		{
			return _x0 + _xRadius;
		}
		
		private var _top:Number = int.MIN_VALUE;
		
		public function get top():Number
		{
			return _y1 - _yRadius;
		}
		
		private var _bottom:Number = int.MAX_VALUE;
		
		public function get bottom():Number
		{
			return _y1 + _yRadius;
		}
		
		override public function get isOnScreen():Boolean
		{
			var renderEngine:RenderEngine = Scene3DManager.getInstance().renderEngine;
			
			var onScreenCamera:CustomCamera = Sprite3D._onScreenTotalCamera;
			if (_cameraOwner != null)
			{
				onScreenCamera.copyValues(_cameraOwner.camera);
			}
			else
			{
				onScreenCamera.reset();
			}
			
			var parent:Sprite3DContainer = _cameraOwner != null ? _cameraOwner.parent : this.parent;
			while (parent != null)
			{
				var parentCamera:CustomCamera = parent.camera;
				if (parentCamera != null)
				{
					onScreenCamera.scrollX += parentCamera.scrollX;
					onScreenCamera.scrollY += parentCamera.scrollY;
					onScreenCamera.scale *= parentCamera.scale;
				}
				
				parent = parent.parent;
			}
			
			var viewportWidth:uint = renderEngine.getViewportWidth() / onScreenCamera.scale;
			var viewportHeight:uint = renderEngine.getViewportHeight() / onScreenCamera.scale;
			var viewportX0:uint = onScreenCamera.scrollX / onScreenCamera.scale;
			var viewportY0:uint = onScreenCamera.scrollY / onScreenCamera.scale;
			var viewportX1:uint = viewportX0 + viewportWidth;
			var viewportY1:uint = viewportY0 + viewportHeight;
			
			return !(left > viewportX1 ||
				right < viewportX0 ||
				top > viewportY1 ||
				bottom < viewportY0);
		}
		
		private static const NUM_VERTEX_DATA_COMPONENTS:uint = 4;
		private static const NUM_ADDITIONAL_DATA_COMPONENTS:uint = 10;
		
		private var _additionalVertexBufferData:ByteArray;
		private var _lastMainBufferSize:int = 0;
		private var _listAdditionalVertexBuffers:Vector.<OrderedVertexBuffer>;
		private var _lastAdditionalBufferSize:int = 0;
		
		private var _mainVertexBuffer:VertexBuffer3D;
		private var _additionalVertexBuffer:VertexBuffer3D;
		private var _tempBuffer:ByteArray;
		
		private var _startDarkenColorData:Vector.<Number>;
		private var _endDarkenColorData:Vector.<Number>;
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
			
			var orderedVertexBuffer:OrderedVertexBuffer;
			var numParticles:uint = _numTotalParticles;
			
			// 8 floats per vertex * 4 vertices per sprite (quad) * 4 bytes per float = 128
			var bytesPerParticle:int = NUM_VERTEX_DATA_COMPONENTS * 4 * 4;
			
			// 12 floats per vertex * 4 vertices per sprite (quad) * 4 bytes per float = 192
			var bytesPerAdditionalParticleData:uint = NUM_ADDITIONAL_DATA_COMPONENTS * 4 * 4;
			
			var textureAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByID(_textureAtlasID);
			var textureData:TextureData = textureAtlasData.getTextureData(textureID);
			
			var numStoredParticles:uint = _vertexData.length / bytesPerParticle;
			_vertexData.position = 0;
			if (_numRemovedParticles != 0 || _numAddedParticles != 0)
			{
				if (_numRemovedParticles > 0)
				{
					if (_numRemovedParticles >= numStoredParticles)
					{
						_vertexData.length = 0;
					}
					else
					{
						var bytesOffset:uint = _numRemovedParticles * bytesPerParticle;
						_vertexData.writeBytes(_vertexData, bytesOffset);
						_vertexData.length = _vertexData.length - bytesOffset;
					}
					numStoredParticles = _vertexData.length / bytesPerParticle;
				}
				
				var i:int = 0;
				var cursor:LinkedListElement = _listParticles.head;
				while (i < numStoredParticles && cursor != null)
				{
					cursor = cursor.next;
					i++;
				}
				
				var firstAddedParticle:LinkedListElement = cursor;
				
				var centerX:Number = _parentShiftX + _shiftX;
				var centerY:Number = _parentShiftY + _shiftY;
				var width2:Number = Math.abs((_x2 - _x0) / 2);
				var height2:Number = Math.abs((_y2 - _y0) / 2);
				
				var offsetLeft:int = width2 - textureData.blankOffsetX;
				var offsetRight:int = width2 - (textureData.width - textureData.blankOffsetX - textureData.croppedWidth);
				var offsetTop:int = height2 - textureData.blankOffsetY;
				var offsetBottom:int = height2 - (textureData.height - textureData.blankOffsetY - textureData.croppedHeight);
				
				_vertexData.length = numParticles * bytesPerParticle;
				
				while (i < numParticles && cursor != null)
				{
					var particle:ParticleData = cursor.data as ParticleData;
					_vertexData.position = i * bytesPerParticle;
					
					var particleScale:Number = particle.startScale;
					var particleAlpha:Number = particle.startAlpha;
					
					_vertexData.writeFloat(centerX - offsetLeft * particleScale);
					_vertexData.writeFloat(centerY - offsetTop * particleScale);
					_vertexData.writeFloat(_textureU0);
					_vertexData.writeFloat(_textureW0);
					
					_vertexData.writeFloat(centerX - offsetLeft * particleScale);
					_vertexData.writeFloat(centerY + offsetBottom * particleScale);
					_vertexData.writeFloat(_textureU1);
					_vertexData.writeFloat(_textureW1);
					
					_vertexData.writeFloat(centerX + offsetRight * particleScale);
					_vertexData.writeFloat(centerY + offsetBottom * particleScale);
					_vertexData.writeFloat(_textureU2);
					_vertexData.writeFloat(_textureW2);
					
					_vertexData.writeFloat(centerX + offsetRight * particleScale);
					_vertexData.writeFloat(centerY - offsetTop * particleScale);
					_vertexData.writeFloat(_textureU3);
					_vertexData.writeFloat(_textureW3);
					
					cursor = cursor.next;
					i++;
				}
				_verticesDataChanged = true;
				
				_additionalVertexBufferData.position = 0;
				numStoredParticles = _additionalVertexBufferData.length / bytesPerAdditionalParticleData;
				if (_numRemovedParticles > 0)
				{
					if (_numRemovedParticles >= numStoredParticles)
					{
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
				
				_additionalVertexBufferData.length = numParticles * bytesPerAdditionalParticleData;
				
				i = numStoredParticles;
				cursor = firstAddedParticle;
				while (i < numParticles && cursor != null)
				{
					particle = cursor.data as ParticleData;
					//trace(JSON.stringify(particle));
					_additionalVertexBufferData.position = i * bytesPerAdditionalParticleData;
					
					var deltaScale:Number = particle.endScale - particle.startScale;
					particleAlpha = _parentAlpha * _alpha * (particle.endAlpha - particle.startAlpha);
					//trace(particleAlpha);
					var deltaSizeLeft:Number = offsetLeft * deltaScale;
					var deltaSizeTop:Number = offsetTop * deltaScale;
					var deltaSizeRight:Number = offsetRight * deltaScale;
					var deltaSizeBottom:Number = offsetBottom * deltaScale;
					
					var shiftX:Number = particle.shiftX;
					var shiftY:Number = particle.shiftY;
					var appearTime:Number = particle.appearTime;
					var lifeTime:Number = particle.lifeTime;
					var speedX:Number = particle.speedX;
					var speedY:Number = particle.speedY;
					var accX:Number = particle.accelerationX;
					var accY:Number = particle.accelerationY;
					
					var commonData:ByteArray;
					if (commonData == null)
					{
						commonData = new ByteArray();
						commonData.endian = Endian.LITTLE_ENDIAN;
					}
					else
					{
						commonData.position = 0;
					}
					
					if (commonData == null)
					{
						commonData = new ByteArray();
						commonData.endian = Endian.LITTLE_ENDIAN;
					}
					else
					{
						commonData.position = 0;
					}
					
					var bytesPerCommonData:Number = NUM_ADDITIONAL_DATA_COMPONENTS * 4;
					
					// va3
					commonData.writeFloat(shiftX);
					commonData.writeFloat(shiftY);
					commonData.writeFloat(appearTime);
					commonData.writeFloat(lifeTime);
					// va4
					commonData.writeFloat(speedX);
					commonData.writeFloat(speedY);
					commonData.writeFloat(accX);
					commonData.writeFloat(accY);
					// va5
					commonData.writeFloat(-deltaSizeLeft);
					commonData.writeFloat(-deltaSizeTop);
					//commonData.writeFloat(particleAlpha);
					
					_additionalVertexBufferData.writeBytes(commonData, 0, bytesPerCommonData);
					
					commonData.position = 32;
					commonData.writeFloat(-deltaSizeLeft);
					commonData.writeFloat(deltaSizeBottom);
					
					_additionalVertexBufferData.writeBytes(commonData, 0, bytesPerCommonData);
					
					commonData.position = 32;
					commonData.writeFloat(deltaSizeRight);
					commonData.writeFloat(deltaSizeBottom);
					
					_additionalVertexBufferData.writeBytes(commonData, 0, bytesPerCommonData);
					
					commonData.position = 32;
					commonData.writeFloat(deltaSizeRight);
					commonData.writeFloat(-deltaSizeTop);
					
					_additionalVertexBufferData.writeBytes(commonData, 0, bytesPerCommonData);
					
					i++;
					cursor = cursor.next;
				}
				
			}
				
			if (_mainVertexBuffer == null || _lastMainBufferSize < numParticles)
			{
				if (_mainVertexBuffer != null && _lastMainBufferSize < numParticles)
				{
					_mainVertexBuffer.dispose();
					_mainVertexBuffer = null;
				}
				
				if (numParticles > 0)
				{
					if (_mainVertexBuffer == null)
					{
						_mainVertexBuffer = context.createVertexBuffer(numParticles * 4, NUM_VERTEX_DATA_COMPONENTS);
						_lastMainBufferSize = numParticles;
						_verticesDataChanged = true;
						
						//trace('creating main buffer for ' + numParticles + ' particles');
						
						orderedVertexBuffer = new OrderedVertexBuffer(0, _mainVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_2);
						_listAdditionalVertexBuffers[0] = orderedVertexBuffer;
						
//						orderedVertexBuffer = new OrderedVertexBuffer(1, _mainVertexBuffer, Sprite3D.COLOR_OFFSET, Context3DVertexBufferFormat.FLOAT_4);
//						_listAdditionalVertexBuffers[1] = orderedVertexBuffer;
						
						orderedVertexBuffer = new OrderedVertexBuffer(1, _mainVertexBuffer, 2, Context3DVertexBufferFormat.FLOAT_2);
						_listAdditionalVertexBuffers[1] = orderedVertexBuffer;
					}
				}
			}
			
			if (_mainVertexBuffer != null && _verticesDataChanged)
			{
				_mainVertexBuffer.uploadFromByteArray(_vertexData, 0, 0, numParticles * 4);
				//_verticesDataChanged = false;
				
				//trace(numParticles * 2 + " triangles uploaded");
			}
			
			if (_additionalVertexBuffer == null || _lastAdditionalBufferSize < numParticles)
			{
				/*
				_additionalVertexBufferData.position = 0;
				trace('=========');
				while (_additionalVertexBufferData.bytesAvailable)
				{
					trace(
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat(),
						_additionalVertexBufferData.readFloat()
					);
				}
				*/
				if (_additionalVertexBuffer != null && _lastAdditionalBufferSize < numParticles)
				{
					_additionalVertexBuffer.dispose();
					_additionalVertexBuffer = null;
				}
				
				if (_additionalVertexBuffer == null)
				{
					_additionalVertexBuffer = context.createVertexBuffer(numParticles * 4, NUM_ADDITIONAL_DATA_COMPONENTS);
					_lastAdditionalBufferSize = numParticles;
					_verticesDataChanged = true;
					
					//trace('creating additional buffer for ' + numParticles + ' particles');
					
					orderedVertexBuffer = new OrderedVertexBuffer(2, _additionalVertexBuffer, 0, Context3DVertexBufferFormat.FLOAT_4);
					_listAdditionalVertexBuffers[2] = orderedVertexBuffer;
					
					orderedVertexBuffer = new OrderedVertexBuffer(3, _additionalVertexBuffer, 4, Context3DVertexBufferFormat.FLOAT_4);
					_listAdditionalVertexBuffers[3] = orderedVertexBuffer;
					
					orderedVertexBuffer = new OrderedVertexBuffer(4, _additionalVertexBuffer, 8, Context3DVertexBufferFormat.FLOAT_2);
					_listAdditionalVertexBuffers[4] = orderedVertexBuffer;
				}
			}
			
			if (_verticesDataChanged)
			{
				_additionalVertexBuffer.uploadFromByteArray(_additionalVertexBufferData, 0, 0, numParticles * 4);
			}
			
			_verticesDataChanged = false;
			
			if (_endDarkenColorData == null)
			{
				_endDarkenColorData = new Vector.<Number>();
				_endDarkenColorData.length = 4;
				_endDarkenColorData.fixed = true;
			}
			
			if (_startDarkenColorData == null)
			{
				_startDarkenColorData = new Vector.<Number>();
				_startDarkenColorData.length = 4;
				_startDarkenColorData.fixed = true;
			}
			
			_startDarkenColorData[0] = _parentRed * redMultiplier;
			_startDarkenColorData[1] = _parentGreen * greenMultiplier;
			_startDarkenColorData[2] = _parentBlue * blueMultiplier;
			_startDarkenColorData[3] = _parentAlpha * _alpha * startAlpha;
			
			_endDarkenColorData[0] = _parentRed * (_endRedMultiplier - redMultiplier);
			_endDarkenColorData[1] = _parentGreen * (_endGreenMultiplier - greenMultiplier);
			_endDarkenColorData[2] = _parentBlue * (_endBlueMultiplier - blueMultiplier);
			_endDarkenColorData[3] = _parentAlpha * _alpha * (_endAlpha - startAlpha);
			
			return _listAdditionalVertexBuffers;
		}
		
		private var _endRedMultiplier:Number = 1;
		public function get endRedMultiplier():Number
		{
			return _endRedMultiplier;
		}
		
		public function set endRedMultiplier(value:Number):void
		{
			_endRedMultiplier = value;
		}
		
		private var _endGreenMultiplier:Number = 1;
		public function get endGreenMultiplier():Number
		{
			return _endGreenMultiplier;
		}
		
		public function set endGreenMultiplier(value:Number):void
		{
			_endGreenMultiplier = value;
		}
		
		private var _endBlueMultiplier:Number = 1;
		public function get endBlueMultiplier():Number
		{
			return _endBlueMultiplier;
		}
		
		public function set endBlueMultiplier(value:Number):void
		{
			_endBlueMultiplier = value;
		}
		
		private var _indexBuffer:IndexBuffer3D;
		private var _indexBufferSize:uint = 0;
		public function getCustomIndexBuffer(context:Context3D):IndexBuffer3D
		{
			var numParticles:uint = _numTotalParticles;
			if (_indexBuffer != null && _indexBufferSize < numParticles * 6)
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
		
		public function clearBatcher():void
		{
			onContextRestored();
		}
		
		public function onContextRestored():void
		{
			if (_mainVertexBuffer != null)
			{
				_mainVertexBuffer.dispose();
				_mainVertexBuffer = null;
				_lastMainBufferSize = 0;
			}
			
			if (_additionalVertexBuffer != null)
			{
				_additionalVertexBuffer.dispose();
				_additionalVertexBuffer = null;
				_lastAdditionalBufferSize = 0;
			}
			
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
				_indexBufferSize = 0;
			}
		}
		
		private var _listFragmentProgramConstants:Vector.<ProgramConstantsData>; 
		public function getProgramConstantsData():Vector.<ProgramConstantsData>
		{
			if (_listFragmentProgramConstants == null)
			{
				_listFragmentProgramConstants = new Vector.<ProgramConstantsData>();
				_listFragmentProgramConstants.length = 2;
				_listFragmentProgramConstants .fixed = true;
				
				if (_startDarkenColorData == null)
				{
					_startDarkenColorData = new Vector.<Number>();
					_startDarkenColorData.length = 4;
					_startDarkenColorData.fixed = true;
				}
				_listFragmentProgramConstants[0] = new ProgramConstantsData(3, Context3DProgramType.FRAGMENT, _startDarkenColorData);
				
				if (_endDarkenColorData == null)
				{
					_endDarkenColorData = new Vector.<Number>();
					_endDarkenColorData.length = 4;
					_endDarkenColorData.fixed = true;
				}
				_listFragmentProgramConstants[1] = new ProgramConstantsData(4, Context3DProgramType.FRAGMENT, _endDarkenColorData);
			}
			
			return _listFragmentProgramConstants;
		}
	}
}
