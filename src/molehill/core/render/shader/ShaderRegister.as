package molehill.core.render.shader
{
	
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	public dynamic class ShaderRegister extends Proxy
	{
		private var _registerName:String;
		public function ShaderRegister(name:String)
		{
			_registerName = name;
		}
		
		public function toString():String
		{
			return _registerName;
		}
		
		public function get all():String
		{
			return _registerName;
		}
		
		override flash_proxy function getProperty(name:*):*
		{
			return _registerName + '.' + name;
		}
	}
}