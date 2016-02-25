package molehill.core.render.shader
{
	import com.adobe.utils.AGALMiniAssembler;
	
	import flash.display.Shader;
	import flash.display3D.Context3D;
	import flash.utils.Dictionary;
	import flash.utils.getDefinitionByName;

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
			
			_cacheAssembledShaders = new Object();
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
		
		private var _cacheAssembledShaders:Object;
		public function registerShader(shaderClassName:String, premultAlpha:Boolean, textureParams:uint):Shader3D
		{
			var shader:Shader3D;
			var premultAlphaIndex:int = premultAlpha ? 1 : 0;
			var shaderAlphaByClass:Object = _cacheAssembledShaders[shaderClassName];
			if (shaderAlphaByClass != null)
			{
				var shaderParamsByAlpha:Object = shaderAlphaByClass[premultAlphaIndex];
				if (shaderParamsByAlpha != null)
				{
					shader = shaderParamsByAlpha[textureParams];
					
					if (shader != null)
					{
						return shader;
					}
				}
			}
			
			if (shader == null)
			{
				var shaderClass:Class = getDefinitionByName(shaderClassName) as Class;
				shader = new shaderClass();
				shader.premultAlpha = premultAlpha;
				shader.textureReadParams = textureParams;
				
				if (_cacheAssembledShaders[shaderClassName] == null)
				{
					_cacheAssembledShaders[shaderClassName] = new Array();
				}
				if (_cacheAssembledShaders[shaderClassName][premultAlphaIndex] == null)
				{
					_cacheAssembledShaders[shaderClassName][premultAlphaIndex] = new Array();
				}
				_cacheAssembledShaders[shaderClassName][premultAlphaIndex][textureParams] = shader;
				
				if (_context3D != null)
				{
					shader.setAssembledProgram(
						_assembler.assemble2(_context3D, 1, shader.vertexShaderCode, shader.fragmentShaderCode)
					);
				}
			}
			
			return shader;
		}
		
		public function hasRegistredClass(shaderClass:Shader):Boolean
		{
			return _cacheAssembledShaders[shaderClass] != null;
		}
	}
}