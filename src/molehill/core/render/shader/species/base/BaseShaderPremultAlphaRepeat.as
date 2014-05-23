package molehill.core.render.shader.species.base
{
	import molehill.core.render.shader.Shader3D;

	public class BaseShaderPremultAlphaRepeat extends Shader3D
	{
		public function BaseShaderPremultAlphaRepeat()
		{
			super();
		}
		
		override public function get fragmentShaderCode():String
		{
			var code:String =
				"tex ft1, v1, fs0 <2d,repeat,linear>\n" +
				
				"mov ft2, ft1\n" +
				"seq ft2.x, ft1.w, fc0.x\n" +
				"add ft2.x, ft1.w, ft2.x\n" +
				"div ft1.xyz, ft1.xyz, ft2.x\n" +
				
				"mul ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
				
				"mov oc, ft1\n";
			
			return code;
		}
		
		override public function get vertexShaderCode():String
		{
			var code:String =
				"m44 vt0, va0, vc0\n" +
				"mov v0, va1\n" +
				"mov v1, va2\n" +
				"mov op, vt0\n";
			
			return code;
		}
	}
}