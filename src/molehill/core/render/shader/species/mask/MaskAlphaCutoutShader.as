package molehill.core.render.shader.species.mask
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.ShaderRegister;
	
	public class MaskAlphaCutoutShader extends Shader3D
	{
		public function MaskAlphaCutoutShader()
		{
			super();
		}
		
		override protected function writeFragmentOutput(fragmentDataRegister:ShaderRegister):void
		{
			move(FT2, fragmentDataRegister);
			setIfEqual(FT2.x, fragmentDataRegister.w, FC0.x);
			subtract(FT2.z, fragmentDataRegister.w, FT2.x);
			kill(FT2.z);
			move(fragmentDataRegister.w, FC0.x);
			
			super.writeFragmentOutput(fragmentDataRegister);
		}
		
		override public function prepareContext(context3D:Context3D):void
		{
			context3D.setStencilReferenceValue(1);
			context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
		}
	}
}