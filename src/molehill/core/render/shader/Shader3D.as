package molehill.core.render.shader
{
	import flash.display3D.Context3D;
	import flash.display3D.Program3D;

	public class Shader3D
	{
		public function Shader3D()
		{
			if (!Shader3DFactory._allowShaderInstantion)
			{
				throw new Error("Use Shader3DFactory::getShaderInstance(shaderClass)")
			}
		}
		
		public function get fragmentShaderCode():String
		{
			var code:String =
				"tex ft1, v1, fs0 <2d,clamp,linear,mipnone>\n" +
				"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
				"mov oc, ft1\n";
			
			return code;
		}
		
		public function get vertexShaderCode():String
		{
			var code:String =
				"m44 vt0, va0, vc0\n" +
				"mov v0, va1\n" +
				"mov v1, va2\n" +
				"mov op, vt0\n";
			
			return code;
		}
		
		public function prepareContext(context3D:Context3D):void
		{
			
		}
		
		public function cleanUpContext(context3D:Context3D):void
		{
			
		}
		
		private var _assembledProgram:Program3D;
		public function getAssembledProgram():Program3D
		{
			return _assembledProgram;
		}
		
		internal function setAssembledProgram(value:Program3D):void
		{
			_assembledProgram = value;
		}
	}
}