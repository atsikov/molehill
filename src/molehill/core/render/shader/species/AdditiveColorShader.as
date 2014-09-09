package molehill.core.render.shader.species
{
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.ShaderRegister;
	
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
				"add ft1.xyz, ft1.xyz, v0.xyz\n" +
				"mov oc, ft1\n";
			
			return code;
		}
		
		override protected function writeFragmentOutput(fragmentDataRegister:ShaderRegister):void
		{
			add(fragmentDataRegister.xyz, fragmentDataRegister.xyz, V0.xyz);
			super.writeFragmentOutput(fragmentDataRegister);
		}
		
	}
}