package molehill.core.render.engine
{
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
	
	import molehill.core.molehill_internal;
	import molehill.core.render.BlendMode;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.base.BaseShader;
	import molehill.core.render.shader.species.base.BaseShaderPremultAlpha;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;
	
	public class RenderEngine
	{
		private var _context3D:Context3D;
		public function RenderEngine(context:Context3D)
		{
			_poolRenderChunkData = new Vector.<RenderChunkData>();
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
			
			_listRenderChunks = new Vector.<RenderChunkData>();
			
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
		
		public function get isReady():Boolean
		{
			return _context3D != null && _context3D.driverInfo != "Disposed";
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
		
		private var _toBitmapData:Boolean = false;
		public function getScreenshot():BitmapData
		{
			if (!isReady)
			{
				return null;
			}
			
			_toBitmapData = true;
			
			doRender();
			
			var bd:BitmapData = new BitmapData(_viewportWidth, _viewportHeight);
			_context3D.drawToBitmapData(bd);
			
			_toBitmapData = false;
			
			return bd;
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
			
			_viewportWidth = width;
			_viewportHeight = height;
			
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
		public function bindTexture(textureAtlasID:String):void
		{
			if (textureAtlasID == null)
			{
				_currentTexture = null;
			}
			else
			{
				var texture:Texture = _textureManager.getTextureByAtlasID(textureAtlasID);
				_currentTexture = texture;
			}
		}
		
		private var _clearR:Number = 0.5;
		private var _clearG:Number = 0.5;
		private var _clearB:Number = 0.5;
		public function setClearColor(value:uint):void
		{
			_clearR = (value >>> 16) / 0xFF;
			_clearG = ((value & 0xFFFF) >>> 8) / 0xFF;
			_clearB = (value & 0xFF) / 0xFF;
		}
		
		public function clear():void
		{
			_context3D.clear(_clearR, _clearG, _clearB, 1, 1, 0);
			
			drawCalls = 0;
			totalTris = 0;
			
			_numVertexFloats = 0;
			_numIndexShorts = 0;
			
			_lastChunkData = null;
			
			_baIndexData.position = 0;
			_baVertexData.position = 0;
			
			//trace(' --------------------- clear --------------------- ');
		}
		
		public function present():void
		{
			doRender();
			_context3D.present();
		}
		
		public var drawCalls:uint = 0;
		public var totalTris:uint = 0;
		public function get renderMode():String
		{
			return _context3D.driverInfo;
		}
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		
		private var _listRenderChunks:Vector.<RenderChunkData>;
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
			
			if (_lastChunkData != null &&
				_lastChunkData.texture == _currentTexture &&
				_lastChunkData.shader == batcher.shader &&
				_lastChunkData.blendMode == batcher.blendMode &&
				camerasEqual &&
				_lastChunkData.additionalVertexBuffers === batcher.getAdditionalVertexBuffers(_context3D) &&
				_lastChunkData.customIndexBuffer === batcher.getCustomIndexBuffer(_context3D))
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
				chunkData.additionalVertexBuffers = batcher.getAdditionalVertexBuffers(_context3D);
				chunkData.customIndexBuffer = batcher.getCustomIndexBuffer(_context3D);
				
				_listRenderChunks.push(chunkData);
				
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
		
		private var _poolRenderChunkData:Vector.<RenderChunkData>;
		private function getRenderChunkData():RenderChunkData
		{
			if (_poolRenderChunkData.length > 0)
			{
				return _poolRenderChunkData.pop();
			}
			
			return new RenderChunkData();
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
			
			var blendMode:String = "";
			var lastShader:Shader3D;
			
			var m:Matrix3D = new Matrix3D();
			_currentScrollX = int.MIN_VALUE;
			_currentScrollY = int.MIN_VALUE;
			_currentScale = 1;
			
			m.identity();
			m.append(_orthoMatrix);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			
			var currentCamera:CustomCamera;
			
			while (_listRenderChunks.length > 0)
			{
				var chunkData:RenderChunkData = _listRenderChunks.shift();
				
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
				
				var currentShader:Shader3D = chunkData.shader;
				if (currentShader == null)
				{
					if (tm.textureIsCompressed(chunkData.texture) || _toBitmapData)
					{
						currentShader = shaderFactory.getShaderInstance(BaseShader);
					}
					else
					{
						currentShader = shaderFactory.getShaderInstance(BaseShaderPremultAlpha);
					}
				}
				
				var additionalVertexBuffers:Vector.<OrderedVertexBuffer> = chunkData.additionalVertexBuffers;
				var numAdditionalBuffers:int = additionalVertexBuffers.length;
				if (additionalVertexBuffers != null)
				{
					for (var i:int = 0; i < numAdditionalBuffers; i++)
					{
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
					if (lastShader != null)
					{
						lastShader.cleanUpContext(_context3D);
					}
					currentShader.prepareContext(_context3D);
					
					//trace("setting shader: " + currentShader);
					_context3D.setProgram(currentShader.getAssembledProgram());
					
					lastShader = currentShader;
				}
				
				_context3D.setTextureAt(0, chunkData.texture);
				try
				{
					//trace('drawing ' + chunkData.numTriangles + ' triangles from ' + chunkData.firstIndex + ' offset');
					
					var currentIndexBuffer:IndexBuffer3D = chunkData.customIndexBuffer == null ? _indexBuffer : chunkData.customIndexBuffer;
					_context3D.drawTriangles(currentIndexBuffer, chunkData.firstIndex, chunkData.numTriangles);
					
					totalTris += chunkData.numTriangles;
				}
				catch (e:Error)
				{
					trace(e.message);
				}
				
				if (chunkData.additionalVertexBuffers != null)
				{
					//trace('restoring vertex buffers');
					for (i = 0; i < chunkData.additionalVertexBuffers.length; i++)
					{
						if (chunkData.additionalVertexBuffers[i].index <= 2)
						{
							continue;
						}
						
						_context3D.setVertexBufferAt(
							chunkData.additionalVertexBuffers[i].index,
							null
						);
					}
					
					// in case additional buffers were placed in streams 0-2
					//_context3D.setVertexBufferAt(0, _vertexBuffer, _verticesOffset, Context3DVertexBufferFormat.FLOAT_3);
					//_context3D.setVertexBufferAt(1, _vertexBuffer, _colorOffset, Context3DVertexBufferFormat.FLOAT_4);
					//_context3D.setVertexBufferAt(2, _vertexBuffer, _textureOffset, Context3DVertexBufferFormat.FLOAT_2);
				}
				
				chunkData.blendMode = null;
				chunkData.firstIndex = 0;
				chunkData.numTriangles = 0;
				chunkData.camera = null;
				chunkData.shader = null;
				chunkData.texture = null;
				chunkData.additionalVertexBuffers = null;
				chunkData.customIndexBuffer = null;
				
				_poolRenderChunkData.push(chunkData);
				
				
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
	}
}