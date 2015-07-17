package molehill.core.render.shader.species
{
	import flash.display.Shader;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.ShaderRegister;

	public class ParticleEmitterShader extends Shader3D
	{
		public function ParticleEmitterShader()
		{
			super();
			
			_vc4 = new <Number>[0, 1000, 2, 0.5];
			_vc4.fixed = true;
		}
		
		override protected function prepareVertexShader():void
		{
			// va2 = x0, y0, appear time (ms), life time (ms)
			// va3 = speedX, speedY, accelX, accelY
			// va4 = targetSizeX, targetSizeY, targetAlpha
			
			var position:ShaderRegister = VT0;
			
			var currentTimer:String = VC4.x;
			
			var initialParams:ShaderRegister = VA2;
			var appearTime:String = initialParams.z;
			var lifeTime:String = initialParams.w;
			
			// time.xyz = life time, life progress, life time ^ 2
			var time:ShaderRegister = VT1;
			
			subtract(time.x, currentTimer, appearTime);
			divide(time.y, time.x, lifeTime);
			divide(time.x, time.x, VC4.y);
			multiply(time.z, time.x, time.x);
			
			var offset:ShaderRegister = VT2;
			var speedsAccels:ShaderRegister = VA3;
			
			multiply(offset.xy, speedsAccels.xy, time.x);
			
			multiply(offset.z, speedsAccels.z, time.z);
			divide(offset.z, offset.z, VC4.z);
			
			multiply(offset.w, speedsAccels.w, time.z);
			divide(offset.w, offset.w, VC4.z);
			
			add(offset.xy, offset.xy, offset.zw);
			
			move(position, VA0);
			add(position.xy, position.xy, initialParams.xy);
			add(position.xy, position.xy, offset.xy);
			
			multiply(VT3.xy, VA4.xy, time.yy);
			add(position.xy, position.xy, VT3.xy);
			
			multiplyVectorMatrix(position, position, VC0);
			move(V0, VA1);
			
			multiply(time.w, time.y, time.y);
			move(V2, time);
			
			move(OP, position);
		}
		
		override protected function prepareFragmentShader():void
		{
			var outputColor:ShaderRegister = FT1;
			var textureCoords:ShaderRegister = V0;
			var fragmentColor:ShaderRegister = FT3;
			
			// x - lived for (secs), y - life progress, z - time^2 (secs), w - life progress^2
			var time:ShaderRegister = V2;
			
			// FC3 is start fragment color, FC4 is fragment color change (end color - start color)
			// fragment color = FC3 + FC4 * life progress
			multiply(fragmentColor, FC4, time.yyyy);
			add(fragmentColor, fragmentColor, FC3);
			
			if ((_textureReadParams & TEXTURE_DONT_USE_TEXTURE) > 0)
			{
				writeFragmentOutput(fragmentColor);
			}
			else
			{
				writeTextureToOutput(outputColor, textureCoords, FS0, fragmentColor);
				writeFragmentOutput(outputColor);
			}
		}
		
		private var _vc4:Vector.<Number>;
		override public function prepareContext(context3D:Context3D):void
		{
			super.prepareContext(context3D);
			
			_vc4[0] = getTimer();
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _vc4);
		}
	}
}