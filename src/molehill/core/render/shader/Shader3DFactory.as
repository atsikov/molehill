package molehill.core.render.shader
{
	import flash.display.Shader;

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
		public function Shader3DFactory()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use Shader3DFactory::getInstance()");
			}
		}
		
		public function getShaderInstance(shaderClass:Class):Shader3D
		{
			var shaderCache:Shader3DCache = Shader3DCache.getInstance();
			_allowShaderInstantion = true;
			var shader:Shader3D = shaderCache.registerShader(shaderClass);
			_allowShaderInstantion = false;
			return shader;
		}
	}
}