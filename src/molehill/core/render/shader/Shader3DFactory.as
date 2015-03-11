package molehill.core.render.shader
{
	import flash.utils.getQualifiedClassName;

	public class Shader3DFactory
	{
		private static var _instance:Shader3DFactory;
		public static function getInstance():Shader3DFactory
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new Shader3DFactory();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		internal static var _allowShaderInstantion:Boolean = false;
		
		private static var _baseShaderClassName:String;
		public function Shader3DFactory()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use Shader3DFactory::getInstance()");
			}
			
			_baseShaderClassName = getQualifiedClassName(Shader3D);
		}
		
		private static const INITIAL_TEXTURE_PARAMS:uint = Shader3D.TEXTURE_REPEAT_CLAMP | Shader3D.TEXTURE_FILTER_LINEAR | Shader3D.TEXTURE_MIP_MIPNONE;
		/**
		 * Creates and caches shader instance
		 * 
		 * @param shaderClassName Shader class name to be instantiated (can be obtained with getQualifiedClassName)
		 * @param premultAlpha Defines if shader should divide color value to alpha
		 * @param textureParams Parameters to read texture in shader. Defaut is Shader3D.TEXTURE_REPEAT_CLAMP | Shader3D.TEXTURE_FILTER_LINEAR | Shader3D.TEXTURE_MIP_MIPNONE
		 **/
		public function getShaderInstance(
			shaderClassName:String = null,
			premultAlpha:Boolean = false,
			textureParams:uint = 268
		):Shader3D
		{
			if (shaderClassName == null)
			{
				shaderClassName = _baseShaderClassName;
			}
			
			var shaderCache:Shader3DCache = Shader3DCache.getInstance();
			_allowShaderInstantion = true;
			var shader:Shader3D = shaderCache.registerShader(shaderClassName, premultAlpha, textureParams);
			_allowShaderInstantion = false;
			return shader;
		}
	}
}