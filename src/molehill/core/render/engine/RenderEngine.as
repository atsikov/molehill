package molehill.core.render.engine
{
	import easy.collections.LinkedList;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix3D;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.BlendMode;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.ProgramConstantsData;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.texture.TextureManager;
	
	import utils.CachingFactory;
	
	use namespace molehill_internal;
	
	public class RenderEngine
	{
		private var _context3D:Context3D;
		public function RenderEngine(context:Context3D)
		{
			_poolRenderChunkData = new CachingFactory(RenderChunkData, 1000);
			_textureManager = TextureManager.getInstance();
			
			setContext3D(context);
		}
		
		public function setContext3D(context:Context3D):void
		{
			_context3D = context;
			
			_viewportWidth = 0;
			_viewportHeight = 0;
			
			if (_vertexBuffer != null)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null;
			}
			
			if (_indexBuffer != null)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			
			_listRenderChunks = new LinkedList();
			
			_baVertexData = new ByteArray();
			_baVertexData.endian = Endian.LITTLE_ENDIAN;
			_baIndexData = new ByteArray();
			_baIndexData.endian = Endian.LITTLE_ENDIAN;
			
			//_context3D.enableErrorChecking = true;
			//_context3D.setCulling(Context3DTriangleFace.BACK);
			_context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0.0, 0.5, 1.0, 2.0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.6, 3.0, -1.0, 0.8]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([Math.sin(Math.PI / 3), -Math.cos(Math.PI / 3), 0.035, 0]));
		}
		
		private var _blendMode:String;
		
		public function setBlendMode(blendMode:String):void
		{
			_blendMode = blendMode;
		}
		
		private var _driverInfo:String;
		private var _driverInfoUpdated:Boolean = false;
		public function get isReady():Boolean
		{
			if (!_driverInfoUpdated && _context3D != null)
			{
				_driverInfo = _context3D.driverInfo;
				_driverInfoUpdated = _driverInfo != "Disposed";
			}
			return _context3D != null && _driverInfo != null && _driverInfoUpdated;
		}
		
		private var _verticesOffset:int = 0;
		private var _colorOffset:int = 0;
		private var _textureOffset:int = 0;
		private var _dataPerVertex:int = 0;
		public function configureVertexBuffer(verticesOffset:int, colorOffset:int, textureOffset:int, dataPerVertex:int):void
		{
			_verticesOffset = verticesOffset;
			_colorOffset = colorOffset;
			_textureOffset = textureOffset;
			_dataPerVertex = dataPerVertex;
		}
		
		private var _viewportWidth:int = 0;
		private var _viewportHeight:int = 0;
		public function getViewportWidth():int
		{
			return _viewportWidth;
		}
		
		public function getViewportHeight():int
		{
			return _viewportHeight;
		}
		
		molehill_internal var toBitmapData:Boolean = false;
		public function copyToBitmapData(bd:BitmapData):void 
		{
			_context3D.drawToBitmapData(bd);
		}
		
		private var _orthoMatrix:Matrix3D;
		public function setViewportSize(width:int, height:int):void
		{
			if (_viewportWidth == width && _viewportHeight == height)
			{
				return;
			}
			
			if (!isReady)
			{
				return;
			}
			
			_viewportWidth = Math.max(50, width);
			_viewportHeight = Math.max(50, height);
			
			_orthoMatrix = new Matrix3D(Vector.<Number> ([
				2/_viewportWidth, 0,  0,  0,
				0, 2/_viewportHeight, 0, 0,
				0, 0, 0.01, 0,
				0, 0, 0, 1])
			);
			_orthoMatrix.appendTranslation(-1, -1, 0);
			_orthoMatrix.appendScale(1, -1, 1);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, _orthoMatrix, true);
			
			_context3D.configureBackBuffer(_viewportWidth, _viewportHeight, 0, true);
		}
		
		private var _currentTexture:Texture;
		private var _textureManager:TextureManager;
		
		private var _clearA:Number = 1;
		private var _clearR:Number = 0.5;
		private var _clearG:Number = 0.5;
		private var _clearB:Number = 0.5;
		public function setClearColor(argb:uint):void
		{
			_clearA = (argb >>> 24) / 0xFF;
			_clearR = ((argb & 0xFFFFFF) >>> 16) / 0xFF;
			_clearG = ((argb & 0xFFFF) >>> 8) / 0xFF;
			_clearB = (argb & 0xFF) / 0xFF;
		}
		
		molehill_internal function clear():void
		{
			_context3D.clear(_clearR, _clearG, _clearB, _clearA);
			
			drawCalls = 0;
			totalTris = 0;
			
			_numVertexFloats = 0;
			_numIndexShorts = 0;
			
			_lastChunkData = null;
			
			_baIndexData.position = 0;
			_baVertexData.position = 0;
			
			//trace(' --------------------- clear --------------------- ');
		}
		
		molehill_internal function drawScenes():void
		{
			doRender();
		}
		
		molehill_internal function present():void
		{
			_context3D.present();
			
			_driverInfoUpdated = false;
		}
		
		public var drawCalls:uint = 0;
		public var totalTris:uint = 0;
		public function get renderMode():String
		{
			return _driverInfo;
		}
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		
		private var _listRenderChunks:LinkedList;
		private var _baVertexData:ByteArray;
		private var _baIndexData:ByteArray;
		
		private var _numVertexFloats:uint;
		private var _numIndexShorts:uint;
		
		private var _lastChunkData:RenderChunkData;
		public function drawBatcher(batcher:IVertexBatcher):uint
		{
			if (batcher.numTriangles == 0)
			{
				return _numVertexFloats;
			}
			
			/*
			var vertexBufferData:ByteArray = batcher.getVerticesData();
			var indexBufferData:ByteArray = batcher.getIndicesData(_numVertexFloats);
			var numNewVertices:uint = vertexBufferData.length / 4;
			var numNewIndices:uint = indexBufferData.length / 2;
			*/
			_currentTexture = batcher.textureAtlasID == null ? null : _textureManager.getTextureByAtlasID(batcher.textureAtlasID);
			
			var batcherScrollX:Number = 0;
			var batcherScrollY:Number = 0;
			var batcherScale:Number = 1;
			var batcherScissorRect:Rectangle = null;
			
			var camerasEqual:Boolean = false;
			if (_lastChunkData != null)
			{
				if (batcher.batcherCamera != null)
				{
					camerasEqual = _lastChunkData.camera != null && _lastChunkData.camera.isEqual(batcher.batcherCamera); 
				}
				else
				{
					camerasEqual = _lastChunkData.camera == null;
				}
			}
			
			var batcherAdditionalVertexBufers:Vector.<OrderedVertexBuffer> = batcher.getAdditionalVertexBuffers(_context3D);
			var programConstantsData:Vector.<ProgramConstantsData> = batcher.getProgramConstantsData();
			var batcherIndexBuffer:IndexBuffer3D = batcher.getCustomIndexBuffer(_context3D);
			if (_lastChunkData != null &&
				_lastChunkData.texture == _currentTexture &&
				_lastChunkData.shader == batcher.shader &&
				_lastChunkData.blendMode == batcher.blendMode &&
				camerasEqual &&
				_lastChunkData.additionalVertexBuffers === batcherAdditionalVertexBufers &&
				_lastChunkData.programConstantsData === programConstantsData &&
				_lastChunkData.customIndexBuffer === batcherIndexBuffer)
			{
				_lastChunkData.numTriangles += batcher.numTriangles;
			}
			else
			{
				var chunkData:RenderChunkData = getRenderChunkData();
				chunkData.texture = _currentTexture;
				chunkData.firstIndex = batcher.indexBufferOffset == -1 ? _numIndexShorts : batcher.indexBufferOffset;
				chunkData.numTriangles = batcher.numTriangles;
				chunkData.shader = batcher.shader;
				chunkData.blendMode = batcher.blendMode;
				chunkData.camera = batcher.batcherCamera;
				chunkData.additionalVertexBuffers = batcherAdditionalVertexBufers;
				chunkData.programConstantsData = programConstantsData
				chunkData.customIndexBuffer = batcherIndexBuffer;
				// [DEBUG ONLY]
				chunkData.textureAtlasID = batcher.textureAtlasID;
				// [/DEBUG ONLY]
				
				_listRenderChunks.enqueue(chunkData);
				
				_lastChunkData = chunkData;
			}
			
			//_baVertexData.position = _baVertexData.length;
			//_baIndexData.position = _baIndexData.length;
			
			//_baVertexData.writeBytes(vertexBufferData);
			//_baIndexData.writeBytes(indexBufferData);
			
			var i:int;
			//_numVertexFloats += numNewVertices;
			//_numIndexShorts += numNewIndices;
			
			return _numVertexFloats;
		}
		
		private var _poolRenderChunkData:CachingFactory;
		private function getRenderChunkData():RenderChunkData
		{
			return _poolRenderChunkData.newInstance();
		}
		
		private var _currentScrollX:Number;
		private var _currentScrollY:Number;
		private var _currentScale:Number;
		
		private var _vertexBufferSize:int = 0;
		private var _indexBufferSize:int = 0;
		private function doRender():void
		{
			/*
			if (_baIndexData.length == 0)
			{
				return;
			}
			
			_baVertexData.position = 0;
			_baIndexData.position = 0;
			*/
			if (_indexBuffer != null && _indexBufferSize < _numIndexShorts)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			if (_indexBuffer == null)
			{
				//_indexBufferSize = _numIndexShorts;
				//_indexBuffer = _context3D.createIndexBuffer(_indexBufferSize);
				//trace('creating index buffer for ' + _indexBufferSize + ' indices');
			}
			
			if (_vertexBuffer != null && _vertexBufferSize < _numVertexFloats / _dataPerVertex)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null;
			}
			if (_vertexBuffer == null)
			{
				//_vertexBufferSize = _numVertexFloats / _dataPerVertex;
				//_vertexBuffer = _context3D.createVertexBuffer(_vertexBufferSize, _dataPerVertex);
				//trace('creating vertex buffer for ' + _vertexBufferSize + ' vertices');
			}
			
			//_vertexBuffer.uploadFromByteArray(_baVertexData, 0, 0, _numVertexFloats / _dataPerVertex);
			//trace("uploading " + _numVertexFloats / _dataPerVertex + " vertices of " + _baVertexData.length / 36 + " in ByteArray");
			
			//_indexBuffer.uploadFromByteArray(_baIndexData, 0, 0, _numIndexShorts);
			//trace("uploading " + _numIndexShorts + " indices of " + _baIndexData.length / 2 + " in ByteArray");
			
			var shaderFactory:Shader3DFactory = Shader3DFactory.getInstance();
			
			//_context3D.setVertexBufferAt(0, _vertexBuffer, _verticesOffset, Context3DVertexBufferFormat.FLOAT_3);
			//_context3D.setVertexBufferAt(1, _vertexBuffer, _colorOffset, Context3DVertexBufferFormat.FLOAT_4);
			//_context3D.setVertexBufferAt(2, _vertexBuffer, _textureOffset, Context3DVertexBufferFormat.FLOAT_2);
			var tm:TextureManager = TextureManager.getInstance();
			
			var blendMode:String = null;
			var lastShader:Shader3D;
			
			var m:Matrix3D = new Matrix3D();
			_currentScrollX = int.MIN_VALUE;
			_currentScrollY = int.MIN_VALUE;
			_currentScale = 1;
			
			m.identity();
			m.append(_orthoMatrix);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			
			var errorCheckEnabled:Boolean = _context3D.enableErrorChecking;
			
			var currentCamera:CustomCamera;
			
			var lastShaderClassName:String = null;
			
			while (!_listRenderChunks.empty)
			{
				var chunkData:RenderChunkData = _listRenderChunks.dequeue() as RenderChunkData;
				
				if (blendMode != chunkData.blendMode)
				{
					blendMode = chunkData.blendMode;
					_context3D.setBlendFactors.apply(null, BlendMode.getBlendFactors(blendMode));
				}
				
				if (chunkData.camera != null && 
					(currentCamera == null || !currentCamera.isEqual(chunkData.camera)))
				{
					currentCamera = chunkData.camera;
					
					_currentScrollX = -currentCamera.scrollX;
					_currentScrollY = -currentCamera.scrollY;
					_currentScale = currentCamera.scale;
					
					//trace(_currentScrollX, _currentScrollY);
					
					m.identity();
					m.appendScale(_currentScale, _currentScale, 1);
					m.appendTranslation(_currentScrollX, _currentScrollY, 0);
					m.append(_orthoMatrix);
					
					_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
					
					//_context3D.setScissorRectangle(currentCamera.scissorRect);
				}
				else if (chunkData.camera == null && currentCamera != null)
				{
					_currentScrollX = 0;
					_currentScrollY = 0;
					_currentScale = 1;
					
					//trace(_currentScrollX, _currentScrollY);
					
					m.identity();
					m.appendScale(_currentScale, _currentScale, 1);
					m.appendTranslation(_currentScrollX, _currentScrollY, 0);
					m.append(_orthoMatrix);
					
					_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
					
					//_context3D.setScissorRectangle(null);
				}
				
				var programConstantsData:Vector.<ProgramConstantsData> = chunkData.programConstantsData;
				if (programConstantsData != null)
				{
					for (i = 0; i < programConstantsData.length; i++)
					{
						if (programConstantsData[i] == null)
						{
							continue;
						}
						
						_context3D.setProgramConstantsFromVector(programConstantsData[i].type, programConstantsData[i].index, programConstantsData[i].data);
					}
				}
				
				var isCompressed:Boolean = tm.textureIsCompressed(chunkData.texture);
				var premultAlpha:Boolean = !isCompressed && !toBitmapData;
				
				var currentShader:Shader3D = chunkData.shader;
				var currentShaderClassName:String = null;
				
				if (currentShader == null)
				{
					currentShader = shaderFactory.getShaderInstance(null, premultAlpha);
				}
				else
				{
					currentShaderClassName = getQualifiedClassName(currentShader);
					currentShader = shaderFactory.getShaderInstance(currentShaderClassName, premultAlpha, currentShader.textureReadParams);
				}
				
				var additionalVertexBuffers:Vector.<OrderedVertexBuffer> = chunkData.additionalVertexBuffers;
				var numAdditionalBuffers:int = additionalVertexBuffers.length;
				if (additionalVertexBuffers != null)
				{
					for (var i:int = 0; i < numAdditionalBuffers; i++)
					{
						if (additionalVertexBuffers[i] == null)
						{
							continue;
						}
						
						//trace("setting additional vertex buffer " + StringUtils.getObjectAddress(chunkData.additionalVertexBuffers[i].buffer) + " at " + chunkData.additionalVertexBuffers[i].index);
						_context3D.setVertexBufferAt(
							additionalVertexBuffers[i].index,
							additionalVertexBuffers[i].buffer,
							additionalVertexBuffers[i].bufferOffset,
							additionalVertexBuffers[i].bufferFormat
						);
					}
				}
				
				if (lastShader != currentShader)
				{
					if (lastShaderClassName != currentShaderClassName)
					{
						if (lastShader != null)
						{
							lastShader.cleanUpContext(_context3D);
						}
						
						//trace("setting shader: " + currentShader);						
					}
					
					currentShader.prepareContext(_context3D);
					_context3D.setProgram(currentShader.getAssembledProgram());
					
					lastShader = currentShader;
					lastShaderClassName = currentShaderClassName;
				}
				
				_context3D.setTextureAt(0, chunkData.texture);
				
				// avoiding try..catch in release versions 
				if (errorCheckEnabled)
				{
					totalTris += renderChunkTryCatch(chunkData);
				}
				else
				{
					totalTris += renderChunk(chunkData);
				}
				
				if (chunkData.additionalVertexBuffers != null)
				{
					//trace('restoring vertex buffers');
					for (i = 0; i < numAdditionalBuffers; i++)
					{
						var orderedBuffer:OrderedVertexBuffer = additionalVertexBuffers[i];
						if (orderedBuffer == null)
						{
							continue;
						}
						
						_context3D.setVertexBufferAt(
							additionalVertexBuffers[i].index,
							null
						);
					}
				}
				
				chunkData.blendMode = null;
				chunkData.firstIndex = 0;
				chunkData.numTriangles = 0;
				chunkData.camera = null;
				chunkData.shader = null;
				chunkData.texture = null;
				chunkData.additionalVertexBuffers = null;
				chunkData.customIndexBuffer = null;
				
				_poolRenderChunkData.storeInstance(chunkData);
				
				
				drawCalls++;
			}
			
			if (lastShader != null)
			{
				lastShader.cleanUpContext(_context3D);
			}
			
			_numVertexFloats = 0;
			_numIndexShorts = 0;
			
			_baIndexData.length = 0;
			_baVertexData.length = 0;
			
			_context3D.setVertexBufferAt(0, null, _verticesOffset, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, null, _colorOffset, Context3DVertexBufferFormat.FLOAT_4);
			_context3D.setVertexBufferAt(2, null, _textureOffset, Context3DVertexBufferFormat.FLOAT_2);
		}
		
		private function renderChunk(chunkData:RenderChunkData):int
		{
			var currentIndexBuffer:IndexBuffer3D = chunkData.customIndexBuffer == null ? _indexBuffer : chunkData.customIndexBuffer;
			_context3D.drawTriangles(currentIndexBuffer, chunkData.firstIndex, chunkData.numTriangles);
			
			return chunkData.numTriangles;
		}
		
		private function renderChunkTryCatch(chunkData:RenderChunkData):int
		{
			try
			{
				var currentIndexBuffer:IndexBuffer3D = chunkData.customIndexBuffer == null ? _indexBuffer : chunkData.customIndexBuffer;
				_context3D.drawTriangles(currentIndexBuffer, chunkData.firstIndex, chunkData.numTriangles);
				
				return chunkData.numTriangles;
			}
			catch (e:Error)
			{
				//trace("error drawing " + chunkData.numTriangles + " triangles from offest " + chunkData.firstIndex);
				trace(e);
			}
			
			return 0;
		}
	}
}