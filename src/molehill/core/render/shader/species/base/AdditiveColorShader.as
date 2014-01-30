package molehill.core.render.shader.species.base
{
	import molehill.core.render.shader.Shader3D;
	
	public class AdditiveColorShader extends Shader3D
	{
		public function AdditiveColorShader()
		{
			super();
		}
		
		override public function get fragmentShaderCode():String
		{
			var code:String =
				"tex ft1, v1, fs0 <2d,clamp,linear,mipnone>\n" +
				"add ft1.xyzw, ft1.xyzw, v0.xyzw\n" +
				"mov oc, ft1\n";
			
			return code;
		}
		
	}
}