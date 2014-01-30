package molehill.core.render.shader.species.base
{
	import molehill.core.render.shader.Shader3D;
	
	public class ColorFillShader extends Shader3D
	{
		public function ColorFillShader()
		{
			super();
		}
		override public function get fragmentShaderCode():String
		{
			var code:String =
				"mov oc, v0\n";
			
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