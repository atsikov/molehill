package molehill.core.render.shader
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display.Shader;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;

	public class Shader3DCache
	{
		private static var _instance:Shader3DCache;
		public static function getInstance():Shader3DCache
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new Shader3DCache();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		private var _assembler:AGALMiniAssembler;
		public function Shader3DCache()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use ShaderCache::getInstance()");
			}
			
			_cacheAssembledShaders = new Dictionary();
			_assembler = new AGALMiniAssembler();
		}
		
		private var _context3D:Context3D;
		public function init(context3D:Context3D):void
		{
			_context3D = context3D;
			
			for each (var listShaderAlphas:Object in _cacheAssembledShaders)
			{
				for each (var listShaderTextures:Object in listShaderAlphas)
				{
					for each (var shader:Shader3D in listShaderTextures)
					{
						shader.setAssembledProgram(
							_assembler.assemble2(_context3D, 1, shader.vertexShaderCode, shader.fragmentShaderCode)
						);
					}
				}
			}
		}
		
		private var _cacheAssembledShaders:Dictionary;
		public function registerShader(shaderClass:Class, premultAlpha:Boolean, textureParams:uint):Shader3D
		{
			var premultAlphaIndex:int = premultAlpha ? 1 : 0;
			if (_cacheAssembledShaders[shaderClass] != null &&
				_cacheAssembledShaders[shaderClass][premultAlphaIndex] != null &&
				_cacheAssembledShaders[shaderClass][premultAlphaIndex][textureParams] != null)
			{
				return _cacheAssembledShaders[shaderClass][premultAlphaIndex][textureParams];
			}
			
			var shader:Shader3D = new shaderClass();
			shader.premultAlpha = premultAlpha;
			shader.textureReadParams = textureParams;
			
			if (_cacheAssembledShaders[shaderClass] == null)
			{
				_cacheAssembledShaders[shaderClass] = new Array();
			}
			if (_cacheAssembledShaders[shaderClass][premultAlphaIndex] == null)
			{
				_cacheAssembledShaders[shaderClass][premultAlphaIndex] = new Array();
			}
			_cacheAssembledShaders[shaderClass][premultAlphaIndex][textureParams] = shader;
			
			if (_context3D != null)
			{
				shader.setAssembledProgram(
					_assembler.assemble2(_context3D, 1, shader.vertexShaderCode, shader.fragmentShaderCode)
				);
			}
			
			return shader;
		}
		
		public function hasRegistredClass(shaderClass:Shader):Boolean
		{
			return _cacheAssembledShaders[shaderClass] != null;
		}
	}
}