package molehill.core.render.shader.species.mask
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DCompareMode;
	import flash.display3D.Context3DStencilAction;
	import flash.display3D.Context3DTriangleFace;
	
	import molehill.core.render.shader.Shader3D;
	
	public class MaskAlphaCutoutShader extends Shader3D
	{
		public function MaskAlphaCutoutShader()
		{
			super();
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
		
		override public function get fragmentShaderCode():String
		{
			var code:String = 
				"tex ft1, v1, fs0 <2d,clamp,nearest>\n" +
				
				"mov ft2, ft1\n" +
				"seq ft2.x, ft1.w, fc0.x\n" +
				"sub ft2.z, ft1.w, ft2.x\n" +
				"kil ft2.z\n" +
				"mov ft1.w, fc0.x\n" +
				
				"mov oc, ft1\n";
			
			return code;
		}
		
		override public function prepareContext(context3D:Context3D):void
		{
			context3D.setStencilReferenceValue(1);
			context3D.setStencilActions(Context3DTriangleFace.FRONT_AND_BACK, Context3DCompareMode.ALWAYS, Context3DStencilAction.SET);
		}
	}
}