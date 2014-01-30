package molehill.core.render.engine
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import fl.motion.easing.Linear;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BlendMode;
	import flash.display.Sprite;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DProgramType;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DVertexBufferFormat;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.Program3D;
	import flash.display3D.VertexBuffer3D;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.geom.Matrix;
	import flash.geom.Matrix3D;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	
	import molehill.core.render.BlendMode;
	import molehill.core.texture.ARFTextureData;
	import molehill.core.texture.TextureManager;
	
	import org.opentween.OpenTween;
	
	public class MolehillRenderEngine implements IRenderEngine
	{
		private var _context3D:Context3D;
		public function MolehillRenderEngine(context:Context3D)
		{
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
			
			_totalIndexBufferData = new Vector.<uint>();
			_totalVertexBufferData = new Vector.<Number>();
			
			//_context3D.enableErrorChecking = true;
			//_context3D.setCulling(Context3DTriangleFace.BACK);
			_context3D.setBlendFactors(Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA);
			_context3D.setDepthTest(false, Context3DCompareMode.ALWAYS);
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, Vector.<Number>([0.0, 0.5, 1.0, 2.0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 1, Vector.<Number>([0.6, 3.0, -1.0, 0.8]));
			if (_context3D.driverInfo.toLocaleLowerCase().indexOf("constrained") != -1)
			{
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([Math.sin(Math.PI / 3), -Math.cos(Math.PI / 3), 0.024, 0.035]));
			}
			else
			{
				_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 2, Vector.<Number>([Math.sin(Math.PI / 3), -Math.cos(Math.PI / 3), 0.035, 0.035]));
			}
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 8, Vector.<Number>([0.6, 0.6, 0.6, 0.0]));
			_context3D.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 9, Vector.<Number>([0.6, 0.6, 0.6, 16.0]));
			
			_context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 5, Vector.<Number>([0.0, 0.5, 1.0, 0.7]));
			
			createNormalTexture();
			
			_motionObject = {
				"y" : 1
			};
			
			OpenTween.go(
				_motionObject,
				{
					"y" : 0
				},
				60,
				0,
				Linear.easeNone,
				null,
				null,
				null,
				null,
				null,
				{cycles:0, reverse:false, easing:Linear.easeNone}
			);
			
			_cacheShaders = new Object();
			loadBaseShader();
		}
		
		private var _normalTexture:Texture;
		private var _normalTextureData:ARFTextureData;

		public function set normalTextureData(value:ARFTextureData):void
		{
			_normalTextureData = value;
			createNormalTexture();
		}
		
		private var _normalTextureBitmapData:BitmapData;
		
		public function set normalTextureBitmapData(value:BitmapData):void
		{
			_normalTextureBitmapData = value;
			_processedBitmapData = new BitmapData(_normalTextureBitmapData.width, _normalTextureBitmapData.height);
			
			_sourceImage = new Sprite();
			_sourceImage.graphics.beginBitmapFill(_normalTextureBitmapData);
			_sourceImage.graphics.drawRect(0, 0, _normalTextureBitmapData.width, _normalTextureBitmapData.height);
			_sourceImage.graphics.endFill();
			
			_movingImage = new Sprite();
			_movingImage.blendMode = flash.display.BlendMode.MULTIPLY;
			
			_sourceImage.addChild(_movingImage);
			
			_movingImage.graphics.beginBitmapFill(_normalTextureBitmapData, null, true, true);
			_movingImage.graphics.drawRect(-_normalTextureBitmapData.width, 0, 2 * _normalTextureBitmapData.width, 2 * _normalTextureBitmapData.height);
			_movingImage.graphics.endFill();
			
			createNormalTexture();
		}
		
		private function createNormalTexture():void
		{
			if (_normalTextureData == null)
			{
				if (_normalTextureBitmapData != null)
				{
					_normalTexture = _context3D.createTexture(_normalTextureBitmapData.width, _normalTextureBitmapData.height, Context3DTextureFormat.BGRA, false);//TextureManager.getInstance().createTextureFromBitmapData(_normalTextureBitmapData, "normalMap", 512, 256);
					_normalTexture.uploadFromBitmapData(_normalTextureBitmapData);
				}
				return;
			}
			
			_normalTexture = TextureManager.getInstance().createCompressedTextureFromARF(_normalTextureData);
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
			
			if (_needUpdateCamera)
			{
				var m:Matrix3D = new Matrix3D();
				m.appendTranslation(_currentCameraX - _viewportWidth / 2, _currentCameraY - _viewportHeight / 2, 0);
				m.appendScale(1, -1, 1);
				m.append(_orthoMatrix);
				
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
				
				_needUpdateCamera = false;
			}
			
			flushBuffersData();
			
			var bd:BitmapData = new BitmapData(_viewportWidth, _viewportHeight);
			_context3D.drawToBitmapData(bd);
			
			_toBitmapData = false;
			
			return bd;
		}
		
		private var _motionObject:Object;
		
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
			
			var orthoCameraMatrix:Matrix3D = new Matrix3D();
			orthoCameraMatrix.appendTranslation(_currentCameraX - _viewportWidth / 2, _currentCameraY - _viewportHeight / 2, 0);
			orthoCameraMatrix.appendScale(1, -1, 1);  
			orthoCameraMatrix.append(_orthoMatrix);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, orthoCameraMatrix, true);
			_context3D.configureBackBuffer(_viewportWidth, _viewportHeight, 0, true);
			
			//_currentCameraX = 0;
			//_currentCameraY = 0;
			_needUpdateCamera = true;
		}
		
		private var _preRenderFunction:Function;
		public function setPreRenderFunction(value:Function):void
		{
			_preRenderFunction = value;
		}
		
		private var _postRenderFunction:Function;
		public function setPostRenderFunction(value:Function):void
		{
			_postRenderFunction = value;
		}
		
		private var _vertexBufferData:ByteArray;
		public function setVertexBufferData(data:ByteArray):void
		{
			_vertexBufferData = data;
		}
		
		private var _indexBufferData:ByteArray;
		public function setIndexBufferData(data:ByteArray):void
		{
			_indexBufferData = data;
		}
		
		private var _currentTexture:Texture;
		private var _textureAtlasID:String;
		private var textureManager:TextureManager;
		public function bindTexture(textureAtlasID:String, sampler:uint = 0):void
		{
			if (textureManager == null)
			{
				textureManager = TextureManager.getInstance();
			}
			
			var texture:Texture = textureManager.getTextureByAtlasID(textureAtlasID);
			//_context3D.setTextureAt(sampler, texture);
			_currentTexture = texture;
		}
		
		private var _timer:uint = 0;
		
		public function clear():void
		{
			_context3D.clear(0.5, 0.5, 0.5, 1, 1, 0);
			
			drawCalls = 0;
			totalTris = 0;
			
			_numVertices = 0;
			_numIndices = 0;
			
			_baIndexData.position = 0;
			_baVertexData.position = 0;
			
			if (_timer == 0)
			{
				_timer = getTimer();
			}
			else
			{
				_timer = getTimer();//+= 17;
			}
			/*
			_context3D.setProgramConstantsFromVector(
				Context3DProgramType.VERTEX,
				4,
				Vector.<Number>(
					[
						(timer  / 300) % (2 * Math.PI),
						(timer  / 500)  % (2 * Math.PI),
						2,
						3
					]
				)
			);
			*/
			
			_context3D.setProgramConstantsFromVector(
				Context3DProgramType.VERTEX, 4, Vector.<Number>(
					[
						- _currentCameraX + 0.5 * _viewportWidth,
						-_currentCameraY - _viewportHeight * 3, //Application.getInstance().stage.mouseY - _currentCameraY,
						50,
						0.0
					]
				)
			);
			
			_context3D.setProgramConstantsFromVector(
				Context3DProgramType.VERTEX, 6, Vector.<Number>(
					[
						- _currentCameraX + 0.5 * _viewportWidth,//
						-_currentCameraY + _viewportHeight * 4, //Application.getInstance().stage.mouseY - _currentCameraY - 500,
						0.0,
						0.0
					]
				)
			);
			
			_context3D.setProgramConstantsFromVector(
				Context3DProgramType.FRAGMENT,
				3, 
				Vector.<Number>(
					[
						160,
						Math.cos((_timer  / 600) % (2 * Math.PI)) * Math.PI / 180 / 12,
						(_timer  / 600) % (2 * Math.PI),
						_motionObject["y"]
					]
				)
			);
			
			_context3D.setProgramConstantsFromVector(
				Context3DProgramType.FRAGMENT,
				4, 
				Vector.<Number>(
					[
						320,
						Math.cos((3287 / 500) % (2 * Math.PI)) * Math.PI / 180,
						(_timer  / 300) % (2 * Math.PI), 
						0
					]
				)
			);
			
			processNormallMap();
		}
		
		private var _processedBitmapData:BitmapData;
		private var _sourceImage:Sprite;
		private var _movingImage:Sprite;
		
		private function processNormallMap():void
		{
			if (_processedBitmapData == null)
			{
				return;
			}
			_movingImage.x = (1 - _motionObject["y"]) * _normalTextureBitmapData.width;
			_movingImage.y = (_motionObject["y"] - 1) * _normalTextureBitmapData.height;
			
			_processedBitmapData.draw(_sourceImage, null, null);
			
			
			_normalTexture.uploadFromBitmapData(_processedBitmapData);
		}
		
		public function present():void
		{
			if (_needUpdateCamera)
			{
				var m:Matrix3D = new Matrix3D();
				m.appendTranslation(_currentCameraX - _viewportWidth / 2, _currentCameraY - _viewportHeight / 2, 0);
				m.appendScale(1, -1, 1);
				m.append(_orthoMatrix);
				
				_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
				
				_needUpdateCamera = false;
			}
			
			flushBuffersData();
			
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
		private var _vertexBufferSize:int = 0;
		private var _indexBufferSize:int = 0;
		public function drawTriangles(numTriangles:int):uint
		{
			if (numTriangles == 0)
			{
				return _numVertices;
			}
			
			/*
			if (_baIndexData.length / 2 + numTriangles * 3 > 3072)
			{
				flushBuffersData();
			}
			*/
			fillVertexIndexData(numTriangles);
			
			
			/*
			if (_vertexBuffer != null && _vertexBufferSize < _vertexBufferData.length / _dataPerVertex / 4)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null;
			}
			if (_vertexBuffer == null)
			{
				_vertexBufferSize = _vertexBufferData.length / _dataPerVertex / 4;
				_vertexBuffer = _context3D.createVertexBuffer(_vertexBufferSize, _dataPerVertex);
			}
			_vertexBuffer.uploadFromByteArray(_vertexBufferData, 0, 0, _vertexBufferData.length / _dataPerVertex / 4);
			
			if (_indexBuffer != null && _indexBufferSize < _indexBufferData.length / 2)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			if (_indexBuffer == null)
			{
				_indexBufferSize = _indexBufferData.length / 2;
				_indexBuffer = _context3D.createIndexBuffer(_indexBufferSize);
			}
			_indexBuffer.uploadFromByteArray(_indexBufferData, 0, 0, _indexBufferData.length / 2);
			
			_context3D.setVertexBufferAt(0, _vertexBuffer, _verticesOffset, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _vertexBuffer, _colorOffset, Context3DVertexBufferFormat.FLOAT_4);
			_context3D.setVertexBufferAt(2, _vertexBuffer, _textureOffset, Context3DVertexBufferFormat.FLOAT_2);
			
			_context3D.drawTriangles(_indexBuffer, 0, numTriangles);
			*/
			
			/*
			_context3D.setStencilReferenceValue(1);
			_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.KEEP);
			*/
			totalTris += numTriangles;
			
			return _numVertices;
		}
		
		private var _listRenderChunks:Vector.<RenderChunkData>;
		private var _baVertexData:ByteArray;
		private var _baIndexData:ByteArray;
		
		private var _totalIndexBufferData:Vector.<uint>;
		private var _totalVertexBufferData:Vector.<Number>;
		
		private var _numVertices:uint;
		private var _numIndices:uint;
		
		private function fillVertexIndexData(numTriangles:int):void
		{
			var chunkData:RenderChunkData = new RenderChunkData();
			chunkData.texture = _currentTexture;
			chunkData.firstIndex = _numIndices;
			chunkData.numTrinagles = numTriangles;
			chunkData.preRenderFunction = _preRenderFunction;
			chunkData.postRenderFunction = _postRenderFunction;
			chunkData.blendMode = _blendMode;
			
			_listRenderChunks.push(chunkData);
			
			//_totalIndexBufferData = _totalIndexBufferData.concat(_indexBufferData);
			//_totalVertexBufferData = _totalVertexBufferData.concat(_vertexBufferData);
			_baVertexData.writeBytes(_vertexBufferData, 0, _vertexBufferData.length);
			_baIndexData.writeBytes(_indexBufferData, 0, _indexBufferData.length);
			
			var i:int;
			/*
			for (i = 0; i < _vertexBufferData.length; i++)
			{
				//_baVertexData.writeFloat(_vertexBufferData[i]);
				_totalVertexBufferData.push(_vertexBufferData[i]);
			}
			*/
			/*
			_indexBufferData.position = 0;
			var shift:int = _numVertices / 9;
			for (i = 0; i < _indexBufferData.length / 2; i++)
			{
				_baIndexData.writeShort(
					_indexBufferData.readShort() + shift
				);
				//_totalIndexBufferData.push(_indexBufferData[i] + _numVertices / 9);
			}
			*/
			_numVertices += _vertexBufferData.length / 4;
			_numIndices += _indexBufferData.length / 2;
		}
		
		private function flushBuffersData():void
		{
			if (_baIndexData.length == 0)
			{
				return;
			}
			
			_baVertexData.position = 0;
			_baIndexData.position = 0;
			
			if (_indexBuffer != null && _indexBufferSize < _numIndices)
			{
				_indexBuffer.dispose();
				_indexBuffer = null;
			}
			if (_indexBuffer == null)
			{
				_indexBufferSize = _numIndices;
				_indexBuffer = _context3D.createIndexBuffer(_indexBufferSize);
			}
			
			if (_vertexBuffer != null && _vertexBufferSize < _numVertices / _dataPerVertex)
			{
				_vertexBuffer.dispose();
				_vertexBuffer = null;
			}
			if (_vertexBuffer == null)
			{
				_vertexBufferSize = _numVertices / _dataPerVertex;
				_vertexBuffer = _context3D.createVertexBuffer(_vertexBufferSize, _dataPerVertex);
			}
			
			_vertexBuffer.uploadFromByteArray(_baVertexData, 0, 0, _numVertices / _dataPerVertex);
			_indexBuffer.uploadFromByteArray(_baIndexData, 0, 0, _numIndices);
			//_vertexBuffer.uploadFromVector(_totalVertexBufferData, 0, _numVertices / _dataPerVertex);
			//_indexBuffer.uploadFromVector(_totalIndexBufferData, 0, _numIndices);
			
			
			
			_context3D.setVertexBufferAt(0, _vertexBuffer, _verticesOffset, Context3DVertexBufferFormat.FLOAT_3);
			_context3D.setVertexBufferAt(1, _vertexBuffer, _colorOffset, Context3DVertexBufferFormat.FLOAT_4);
			_context3D.setVertexBufferAt(2, _vertexBuffer, _textureOffset, Context3DVertexBufferFormat.FLOAT_2);
			var tm:TextureManager = TextureManager.getInstance();
			
			var blendMode:String = "";
			
			while (_listRenderChunks.length > 0)
			{
				var chunkData:RenderChunkData = _listRenderChunks.shift();
				
				if (blendMode != chunkData.blendMode)
				{
					blendMode = chunkData.blendMode;
					_context3D.setBlendFactors.apply(null, molehill.core.render.BlendMode.getBlendFactors(blendMode));
				}
				/*
				if (chunkData.numTrinagles == 0)
				{
					_context3D.setStencilReferenceValue(0);
					_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
					continue;
				}
				*/
				if (chunkData.preRenderFunction != null)
				{
					chunkData.preRenderFunction();
				}
				else
				{
					if (tm.textureIsCompressed(chunkData.texture))
					{
						loadBaseToBitmapShader();
					}
					else
					{
						loadBaseShader();
					}
				}
				
				_context3D.setTextureAt(0, chunkData.texture);
				_context3D.drawTriangles(_indexBuffer, chunkData.firstIndex, chunkData.numTrinagles);
				//trace(chunkData.firstIndex, chunkData.numTrinagles, _numIndices);
				
				if (chunkData.postRenderFunction != null)
				{
					chunkData.postRenderFunction();
				}
				
				drawCalls++;
			}
			
			_numVertices = 0;
			_numIndices = 0;
			
			_totalIndexBufferData.splice(0, _totalIndexBufferData.length);
			_totalVertexBufferData.splice(0, _totalVertexBufferData.length);
			
			_baIndexData.length = 0;
			_baVertexData.length = 0;
		}
		
		private var _currentCameraX:int = 0;
		private var _currentCameraY:int = 0;
		private var _needUpdateCamera:Boolean = false;
		public function setCameraPosition(position:Point):void
		{
			_needUpdateCamera = true;
			
			_currentCameraX = position.x;
			_currentCameraY = position.y;
		}
		
		private var _cacheShaders:Object;
		private var _currentShaderID:String = "";
		public function loadShader(shaderName:String, vertexShaderSource:String = null, fragmentShaderSource:String = null):void
		{
			if (_currentShaderID == shaderName)
			{
				return;
			}
			
			if (_cacheShaders == null)
			{
				_cacheShaders = new Object();
			}
			
			var program:Program3D = _cacheShaders[shaderName];
			if (program == null)
			{
				var agalVertex:AGALMiniAssembler = new AGALMiniAssembler();
				var agalFragment:AGALMiniAssembler = new AGALMiniAssembler();
				
				agalVertex.assemble(Context3DProgramType.VERTEX, vertexShaderSource);
				agalFragment.assemble(Context3DProgramType.FRAGMENT, fragmentShaderSource);
				
				program = _context3D.createProgram();
				program.upload(agalVertex.agalcode, agalFragment.agalcode);
				
				_cacheShaders[shaderName] = program;
			}
			
			_context3D.setProgram(program);
		}
		
		public function loadBaseShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			
			if (_cacheShaders['base'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"tex ft1, v1, fs0 <2d,clamp,linear>\n" +
					//"mov ft1, v0\n" +
					
					"mov ft2, ft1\n" +
					"seq ft2.x, ft1.w, fc0.x\n" +
					"sub ft2.z, ft1.w, ft2.x\n" +
					"kil ft2.z\n" +
					"add ft2.y, ft2.x, ft1.w\n" +
					"div ft1.xyz, ft1.xyz, ft2.y\n" +
					"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
					
					"mov oc, ft1\n";
					//"mov oc, v0\n";
			}
			
			loadShader("base", agalVertexSource, agalFragmentSource);
		}
		
		public function clearSecondTexture():void
		{
			_context3D.setTextureAt(1, null);
			loadBaseShader();
		}
		
		public function loadCutOutWaterShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			
			if (_cacheShaders['cutOutWater'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"sge ft3.z, v1.y, fc2.z\n" + 
					
					"tex ft1, v1, fs0 <2d,clamp,linear>\n" +
					
					"slt ft2.x, ft1.z, fc1.x\n" +
					"add ft2.x, fc1.z, ft2.x\n" +
					"mul ft2.x, ft3.z, ft2.x\n" +
					"kil ft2.x\n" +
					
					"sub ft2.x, v1.y, fc2.w\n" + 
					"mul ft2.x, ft3.z, ft2.x\n" +
					"kil ft2.x \n" +
					
					"mov oc, ft1\n";
			}
			
			loadShader("cutOutWater", agalVertexSource, agalFragmentSource);
			
		}
		
		public function loadWaterOverlayShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			_context3D.setTextureAt(1, _normalTexture);
			
			if (_cacheShaders['waterOverlay'] == null)
			{
				// v0	texCoord
				// v1	normal
				var agalVertexSource:String =
					"m44 op, va0, vc0\n" +		// position = vertex * viewProjMatrix
					"mov v4, va1'\n" +			//normal map params : x - width multiplier, y - height multiplier
					"mov v0, va2'\n";			// v0 = texCoord
				
				var agalFragmentSource:String =
					//расчёт смещения:
					"mul ft3.x, v0.y, fc3.x\n" +
					"add ft3.x, ft3.x, fc3.z\n" + // добавляем сдвиг синусоиды
					"sin ft4.x, ft3.x\n" +
					"mul ft3.x, ft4.x, fc3.y\n" + //домножаем на размер смещения
					//--------------------
					
					"mov ft4, v0\n" + 
					
					//сдвигаем по по X:
					"mul ft3.z, ft3.x, fc2.x\n" + // домножаем на sin 60	
					"add ft4.x, v0.x, ft3.z\n" +
					
					//сдвигаем по по Y:
					"mul ft3.y, ft3.x, fc2.y\n" + // домножаем на cos 60	
					"add ft4.y, v0.y, ft3.z\n" +
					
					"tex ft0, ft4, fs0 <2d,clamp,linear,mipnone>\n" +
					/*
					// cut out green
					"sge ft2.x, ft0.z, fc1.x\n" +
					"add ft2.x, fc1.z, ft2.x\n" +
					"kil ft2.x\n" +
					*/
					//"tex ft0, ft4, fs0 <2d,clamp,linear,mipnone>\n" +
					
					"mul ft4.x, ft4.x, v4.x \n" + //"repeat" texture by width
					"mul ft4.y, ft4.y, v4.y \n" + //"repeat" texture by height
					
					"sub ft4.x, ft4.x, ft3.z \n" +
					"sub ft4.y, ft4.y, ft3.y \n" +
					
					"tex ft1, ft4, fs1 <2d,repeat,linear,mipnone>\n" +	// ft1 = normalMap(v0)
					
					"sub ft3, fc0.z, ft1\n" +
					"sub ft2, fc0.z, ft0\n" +
					"mul ft3, ft3, ft2\n" +
					//"add ft3, ft3, ft3\n" +
					"sub ft0, fc0.z, ft3\n" +
					
					"mov oc, ft0\n";
			}
			
			loadShader('waterOverlay', agalVertexSource, agalFragmentSource);
		}
		
		public function loadNormalMappingShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			
			if (_context3D.driverInfo.toLocaleLowerCase().indexOf("constrained") != -1)
			{
				loadWaterOverlayShader();
				return;
			}
			
			_context3D.setTextureAt(1, _normalTexture);
			
			if (_cacheShaders['normalMap'] == null)
			{
				// v0	texCoord
				// v1	normal
				// v2	lightVec
				// v3	viewVec
				// vertex
				// vc0	viewProj matrix
				// vc4	lightPos
				// vc5	viewPos
				
				var agalVertexSource:String =
					"m44 op, va0, vc0\n" +		// position = vertex * viewProjMatrix
					"mov v4, va1'\n" +			//normal map params : x - width multiplier, y - height multiplier
					"mov v0, va2'\n" + 			// v0 = texCoord
					// transform lightVec
					
					"sub vt1, vc4, va0\n" +	// vt1 = lightPos - vertex (lightVec)					
					"mov vt3.x, vt1.x\n" +
					"mov vt3.y, vt1.y\n" +
					"mov vt3.z, vt1.z\n" +
					"mov v2, vt3.xyzx\n" +		// v2 = lightVec
										
					"sub vt2, va0, vc6\n" +	// vt2 = viewPos - vertex (viewVec)
					"mov vt4.x, vt2.x\n" +
					"mov vt4.y, vt2.y\n" +
					"mov vt4.z, vt2.z\n" +				
					"mov v3, vt4.xyzx\n";		// v3 = viewVec
				
				
				// fragment
				// fc0	vec4(0.0, 0.5, 1.0, 2.0)
				// fc8	ambient
				// fc9	vec4(specularLevel.xyz, specularPower)
				// ft0	output color
				// ft1	normalize(lerp_normal)
				// ft2	normalize(lerp_lightVec)
				// ft3	normalize(lerp_viewVec)
				// ft4 	reflect(-ft3, ft1)
				// ft5..ft7	temp
				
				// diffuse
				var agalFragmentSource:String =
					//не изменяем горизонт:
					//"sge ft3.z, v1.y, fc2.z\n" +  // подает в фиксированную область ? 0 : 1
					"sub ft3.z, v0.y, fc2.z\n" + 
					"kil ft3.z \n" +
					
					//расчёт смещения:
					"mul ft3.x, v0.y, fc3.x\n" +
					"add ft3.x, ft3.x, fc3.z\n" + // добавляем сдвиг синусоиды
					"sin ft4.x, ft3.x\n" +
					"mul ft3.x, ft4.x, fc3.y\n" + //домножаем на размер смещения
					//--------------------
					
					"mov ft4, v0\n" + 
					
					//сдвигаем по по X:
					"mul ft3.z, ft3.x, fc2.x\n" + // домножаем на sin 60	
					"add ft4.x, v0.x, ft3.z\n" +
					
					//сдвигаем по по Y:
					"mul ft3.y, ft3.x, fc2.y\n" + // домножаем на cos 60	
					"add ft4.y, v0.y, ft3.z\n" +
					
					"tex ft0, ft4, fs0 <2d,clamp,linear,mipnone>\n" +
					/*
					// cut out green
					"sge ft2.x, ft0.z, fc1.x\n" +
					"add ft2.x, fc1.z, ft2.x\n" +
					"kil ft2.x\n" +
					
					//"tex ft0, ft4, fs0 <2d,clamp,linear,mipnone>\n" +
					*/
					"mul ft4.x, ft4.x, v4.x \n" + //"repeat" texture by width
					"mul ft4.y, ft4.y, v4.y \n" + //"repeat" texture by height
					
					"tex ft1, ft4, fs1 <2d,repeat,linear,mipnone>\n" +	// ft1 = normalMap(v0)
					
					"add ft4.x, ft4.x, fc3.w \n" +
					"sub ft4.y, ft4.y, fc3.w \n" +
					
					"sub ft4.x, ft4.x, ft3.z \n" +
					"sub ft4.y, ft4.y, ft3.y \n" +
					
					"tex ft3, ft4, fs1 <2d,repeat,linear,mipnone>\n" +	// ft1 = normalMap(v0)
					
					"mul ft1, ft3, ft1\n" +
					// 0..1 to -1..1
					
					"add ft1, ft1, ft1\n" +		// ft1 *= 2
					"sub ft1, ft1, fc0.z\n" +		// ft1 -= 1
					
					"nrm ft1.xyz, ft1\n" +			// normal ft1 = normalize(normal)
					"nrm ft2.xyz, v2\n" +	// lightVec	ft2 = normalize(lerp_lightVec)
					"nrm ft3.xyz, v3\n" +	// viewVec	ft3 = normalize(lerp_viewVec)
					
					"dp3 ft4.x, ft1.xyz ft3.xyz\n" +	// ft4 = dot(normal, viewVec)
					"mul ft4, ft1.xyz, ft4.x\n" +		// ft4 *= normal
					"add ft4, ft4, ft4\n" +			// ft4 *= 2					
					"sub ft4, ft3.xyz, ft4\n" +			// reflect	ft4 = viewVec - ft4
					
					"dp3 ft5.x, ft1.xyz, ft2.xyz\n" +	// ft5 = dot(normal, lightVec)
					"max ft5.x, ft5.x, fc0.x\n" +		// ft5 = max(ft5, 0.0)					
					"add ft5, fc8, ft5.x\n" +			// ft5 = ambient + ft5
					"mul ft0, ft0, ft5\n" +				// color *= ft5
					
					"dp3 ft6.x, ft2.xyz, ft4.xyz\n" +	// ft6 = dot(lightVec, reflect)
					"max ft6.x, ft6.x, fc0.x\n" +		// ft6 = max(ft6, 0.0)
					"pow ft6.x, ft6.x, fc9.w\n" +		// ft6 = pow(ft6, specularPower)
					"mul ft6, ft6.x, fc9.xyz\n" +		// ft6 *= specularLevel
					"add ft0, ft0, ft6\n" +				// color += ft6
					
					"mov oc, ft0\n";
			}
			
			loadShader('normalMap', agalVertexSource, agalFragmentSource);
		}
		
		public function loadSineWaterShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			
			if (_cacheShaders['sineWater'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					
					"mov ft0, v1\n" +
					
					//расчёт смещения:
					
					"mul ft3.x, v1.y, v0.y\n" + //v0.y - коэффициент высоты атласа (atlas.height * Math.PI / 180)
					"mul ft3.x, ft3.x, fc4.x\n" +
					"add ft3.x, ft3.x, fc4.z\n" + 
					"sin ft4.x, ft3.x\n" +	
					//домножаем на размер смещения (fc4.y)
					"mul ft3.x, fc4.y, v0.x\n" + //v0.x - коэффициент ширины атласа (128 / atlas.width)
					"mul ft3.x, ft3.x, ft4.x\n" + 
					//--------------------
										
					//сдвигаем по по X:
					"add ft0.x, ft0.x, ft3.x\n" +
					
					"tex ft1, ft0, fs0, <2d, repeat, linear, mipnone>\n" + 
					
					"mul ft1.w, ft1.w, v0.w\n" +
					
					"mov oc, ft1\n";
			}
			
			loadShader("sineWater", agalVertexSource, agalFragmentSource);
		}
		
		public function loadSineShadowShader():void
		{
			if (_toBitmapData)
			{
				loadBaseToBitmapShader();
				return;
			}
			
			if (_cacheShaders['sineShadow'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					
					"mov ft0, v1\n" +
					
					//расчёт смещения:
					"mul ft3.x, v1.y, v0.y\n" + //v0.y - коэффициент высоты атласа (atlas.height * Math.PI / 180)
					"mul ft3.x, ft3.x, fc3.x\n" +
					"add ft3.x, ft3.x, fc3.z\n" + 
					"sin ft4.x, ft3.x\n" +	
					//домножаем на размер смещения (fc3.y)
					"mul ft3.x, fc3.y, v0.x\n" + //v0.x - коэффициент ширины атласа (128 / atlas.width)
					"mul ft3.x, ft3.x, ft4.x\n" + 
					//--------------------
										
					//сдвигаем по по X:
					"mul ft3.z, ft3.x, fc2.x\n" + // домножаем на sin 60	
					"add ft0.x, ft0.x, ft3.z\n" +
					
					//сдвигаем по по Y:
					"mul ft3.z, ft3.x, fc2.y\n" + // домножаем на cos 60	
					"add ft0.y, ft0.y, ft3.z\n" +
					
					"tex ft1, ft0, fs0, <2d, clamp, linear, mipnone>\n" + 
					"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
					
					"mov oc, ft1\n";
			}
			
			loadShader("sineShadow", agalVertexSource, agalFragmentSource);
		}
		
		public function loadBaseToBitmapShader():void
		{
			if (_cacheShaders['baseToBitmap'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"tex ft1, v1, fs0 <2d,clamp,linear>\n" +
					"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
					
					"mov oc, ft1\n";
				//"mov oc, v0\n";
			}
			
			loadShader("baseToBitmap", agalVertexSource, agalFragmentSource);
		}
		
		public function loadMaskShader():void
		{
			if (_cacheShaders['mask'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"tex ft1, v1, fs0 <2d,clamp,nearest>\n" +
					//"mov ft1, v0\n" +
					
					"mov ft2, ft1\n" +
					"seq ft2.x, ft1.w, fc0.x\n" +
					"sub ft2.z, ft1.w, ft2.x\n" +
					"kil ft2.z\n" +
					"mov ft1.w, fc0.x\n" +
					
					"mov oc, ft1\n";
				//"mov oc, v0\n";
			}
			
			loadShader("mask", agalVertexSource, agalFragmentSource);
		}
		
		public function loadBloomShader():void
		{
			if (_cacheShaders['bloom'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov v2, vc4\n" +
					"mov op, vt0\n";
				
				// v0 is rgba multiplication
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"tex ft1, v1, fs0 <2d,clamp,nearest>\n" +
					//"mov ft1, v0\n" + 
					"mov ft2, ft1\n" +
					"seq ft2.x, ft1.w, fc0.x\n" +
					"add ft2.x, ft2.x, ft1.w\n" +
					"div ft1.xyz, ft1.xyz, ft2.x\n" +
					"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
					
					// init registers
					"mov ft2.xyzw, fc0.xxxx\n" +
					"mov ft3.xyzw, fc0.xxxx\n" +
					
					// get channels summ to ft3.x
					"dp3 ft3.x, ft1.xyz, fc0.zzz\n" +
					"div ft3.x, ft3.x, fc0.w\n" +
					
					// get brightness diff in ft3.x
					"sub ft3.x, ft3.x, fc1.x\n" +
					// get 0..1 to ft3.y where 0 means dot is under bright pass and 1 is over bright pass
					"slt ft3.y, fc0.x, ft3.x\n" +
					
					// transform negative values in ft3.x to 0
					// bright pass is fc1.w
					"sat ft3.x, ft3.x\n" +
					
					// get brightness amount
					"sin ft2.w, v2.x\n" +
					"sat ft2.w, ft2.w\n" +
					"mul ft2.xyz, ft1.xyz, ft3.xxx\n" +
					"mul ft2.xyz, ft2.xyz, ft2.www\n" +
					//"sqt ft2.xyz, ft2.xyz\n" +
					
					// apply brightness
					"add ft1.xyz, ft1.xyz, ft2.xyz\n" +
					
					/*
					"seq ft3.y, ft3.x, fc0.x\n" +
					"mul ft3.y, ft3.y, fc1.x\n" +
					"add ft1.xyz, ft1.xyz, ft3.yyy\n" +
					
					
					"mul ft3.y, ft3.y, fc0.z\n" +
					"mul ft3.y, ft3.y, ft1.w\n" +
					
					"mov ft1.w, ft3.x\n" +
					"add ft1.w, ft1.w, ft3.y\n" +
					*/
					
					"mov oc, ft1\n";
					//"mov oc, v0\n";
			}
			
			loadShader("bloom", agalVertexSource, agalFragmentSource);
		}
		
		public function loadTintShader():void
		{
			if (_cacheShaders['tint'] == null)
			{
				var agalVertexSource:String =
					"m44 vt0, va0, vc0\n" +
					"mov v0, va1\n" +
					"mov v1, va2\n" +
					"mov op, vt0\n";
				
				// v0 is rgba addition
				// v1 is UW texture coords
				var agalFragmentSource:String =
					"tex ft1, v1, fs0 <2d,clamp,nearest>\n" +
					//"mov ft1, v0\n" + 
					"mov ft2, ft1\n" +
					"seq ft2.x, ft1.w, fc0.x\n" +
					"add ft2.x, ft2.x, ft1.w\n" +
					"div ft1.xyz, ft1.xyz, ft2.x\n" +
					
					"mul ft1.w, ft1.w, v0.w\n" +
					"add ft1.xyz, ft1.xyz, v0.xyz\n" +
					"mov oc, ft1\n";
				//"mov oc, v0\n";
			}
			
			loadShader("tint", agalVertexSource, agalFragmentSource);
		}
		
		public function renderToMainCamera():void
		{
			_context3D.setScissorRectangle(
				null
			);
			
			var m:Matrix3D = new Matrix3D();
			m.appendTranslation(_currentCameraX - _viewportWidth / 2, _currentCameraY - _viewportHeight / 2, 0);
			m.appendScale(1, -1, 1);
			m.append(_orthoMatrix);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
			
		}
		
		public function renderToSecondCamera():void
		{
			_context3D.setScissorRectangle(
				new Rectangle(_viewportWidth - 306, 50, 256, 256)
			);
			
			var m:Matrix3D = new Matrix3D();
			m.appendTranslation(_currentCameraX - _viewportWidth / 2, _currentCameraY - _viewportHeight / 2, 0);
			m.appendScale(2, -2, 1);
			m.append(_orthoMatrix);
			
			_context3D.setProgramConstantsFromMatrix(Context3DProgramType.VERTEX, 0, m, true);
		}
		
		public function enterMaskMode():void
		{
			loadMaskShader();
			
			_context3D.setStencilReferenceValue(0);
			_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.INCREMENT_SATURATE);
		}
		
		public function enterMaskedMode():void
		{
			loadBaseShader();
			
			_context3D.setStencilReferenceValue(1);
			_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);
		}
		
		public function enterCutoutMode():void
		{
			loadBaseShader();
			
			_context3D.setStencilReferenceValue(0);
			_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);
		}
		
		public function enterNormalMode():void
		{
			loadBaseShader();
			
			_context3D.setStencilReferenceValue(0);
			_context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.KEEP);
		}
	}
}