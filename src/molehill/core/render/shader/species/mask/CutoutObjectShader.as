package molehill.core.render.shader.species.mask
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DClearMask;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	
	import molehill.core.render.shader.Shader3D;
	
	public class CutoutObjectShader extends Shader3D
	{
		public function CutoutObjectShader()
		{
			super();
		}
		
		override public function prepareContext(context3D:Context3D):void
		{
			context3D.setStencilReferenceValue(0);
			context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.EQUAL, Context3DStencilAction.DECREMENT_SATURATE);
		}
		
		override public function cleanUpContext(context3D:Context3D):void
		{
			context3D.setStencilReferenceValue(0);
			context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
			context3D.clear(0, 0, 0, 0, 0, 0, Context3DClearMask.STENCIL);
		}
	}
}