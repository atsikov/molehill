package molehill.core.render.shader.species.base
{
	import molehill.core.render.shader.Shader3D;

	public class BaseShaderPremultAlpha extends Shader3D
	{
		public function BaseShaderPremultAlpha()
		{
			super();
		}
		
		override public function get fragmentShaderCode():String
		{
			var code:String =
				"tex ft1, v1, fs0 <2d,clamp,linear>\n" +
				
				"mov ft2, ft1\n" +
				"seq ft2.x, ft1.w, fc0.x\n" +
				"sub ft2.z, ft1.w, ft2.x\n" +
				"kil ft2.z\n" +
				"add ft2.y, ft2.x, ft1.w\n" +
				"div ft1.xyz, ft1.xyz, ft2.y\n" +
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