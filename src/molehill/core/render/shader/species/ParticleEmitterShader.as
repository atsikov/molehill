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
			//move(time, VC4);
			
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
			///move(V1, VA2);
			
			multiply(time.w, time.y, time.y);
			move(V2, time);
			//move(V3, VA4);
			
			move(OP, position);
//			
//			var code:String =
//				// traveled distance = speed + accel
//				"add vt2.xy, vt2.xy, vt2.zw\n" +
//				
//				"mov vt0, va0\n" +
//				// position + initial offset
//				"add vt0.xy, vt0.xy, va3.xy\n" +
//				
//				// position + traveled distance
//				"add vt0.xy, vt0.xy, vt2.xy\n" +
//				
//				"m44 vt0, vt0, vc0\n" +
//				"mov v0, va1\n" +
//				"mov v1, va2\n" +
//				
//				"mul vt1.w, vt1.y, vt1.y\n" +
//				// x - lived for (secs), y - life progress, z - time^2 (secs), w - life progress^2
//				"mov v2, vt1\n" +
//				
//				"mov op, vt0\n";
//			
//			return code;
		}
		
		override protected function prepareFragmentShader():void
		{
			var outputColor:ShaderRegister = FT1;
			var textureCoords:ShaderRegister = V0;
			var fragmentColor:ShaderRegister = FT2;
			
			// x - lived for (secs), y - life progress, z - time^2 (secs), w - life progress^2
			var time:ShaderRegister = V2;
			
			//move(fragmentColor, FC3);
			//add(fragmentColor, fragmentColor, FC4);
			//move(fragmentColor.w, V3.z);
			multiply(fragmentColor, FC4, time.yyyy);
			add(fragmentColor, fragmentColor, FC3);
			
			//writeFragmentOutput(FC3);
			
			//multiply(fragmentColor, fragmentColor, V0);
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
		/*
		override protected function writeFragmentOutput(fragmentDataRegister:ShaderRegister):void
		{
			move(FT2, V3);
			multiply(FT2.z, FT2.z, V2.y);
			multiply(FT2.z, FT2.z, fragmentDataRegister.w);
			add(fragmentDataRegister.w, fragmentDataRegister.w, FT2.z);
			
			super.writeFragmentOutput(fragmentDataRegister);
		}
		*/
		private var _vc4:Vector.<Number>;
		override public function prepareContext(context3D:Context3D):void
		{
			_vc4[0] = getTimer();
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _vc4);
		}
	}
}