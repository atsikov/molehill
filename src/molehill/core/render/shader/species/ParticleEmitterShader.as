package molehill.core.render.shader.species
{
	import flash.display3D.Context3D;
	import flash.display3D.Context3DProgramType;
	import flash.utils.getTimer;
	
	import molehill.core.render.shader.Shader3D;

	public class ParticleEmitterShader extends Shader3D
	{
		public function ParticleEmitterShader()
		{
			super();
			
			_vc4 = new <Number>[0, 1000, 2, 0.5];
			_vc4.fixed = true;
		}
		
		override public function get vertexShaderCode():String
		{
			// va3 = x0, y0, appear time (ms), life time (ms)
			// va4 = speedX, speedY, accelX, accelY
			
			var code:String =
				"mov vt1, vc4\n" +
				
				// vt1.x = timer - appear time
				"sub vt1.x, vc4.x, va3.z\n" +
				
				// vt1.y = life progress (vt1.x / lifeTime)
				"div vt1.y, vt1.x, va3.w\n" +
				
				// vt1.x /= 1000 (msecs => secs)
				"div vt1.x, vt1.x, vc4.y\n" +
				
				// time^2
				"mul vt1.z, vt1.x, vt1.x\n" +
				
				// speed * time
				"mul vt2.xy, vt1.xx, va4.xy\n" +
				// accel * time^2 / 2
				"mul vt2.zw, vt1.zz, va4.zw\n" +
				"div vt2.zw, vt2.zw, vc4.zz\n" +
				
				"mov vt0, va0\n" +
				// position + initial offset
				"add vt0.xy, vt0.xy, va3.xy\n" +
				
				// position + traveled distance (accel + speed)
				"add vt0.xy, vt0.xy, vt2.xy\n" +
				"add vt0.xy, vt0.xy, vt2.zw\n" +
				
				"m44 vt0, vt0, vc0\n" +
				"mov v0, va1\n" +
				"mov v1, va2\n" +
				
				"mul vt1.w, vt1.y, vt1.y\n" +
				// x - lived for (secs), y - life progress, z - time^2 (secs), w - life progress^2
				"mov v2, vt1\n" +
				
				"mov op, vt0\n";
			
			return code;
		}
		
		private var _vc4:Vector.<Number>;
		override public function prepareContext(context3D:Context3D):void
		{
			_vc4[0] = getTimer();
			context3D.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 4, _vc4);
		}
	}
}