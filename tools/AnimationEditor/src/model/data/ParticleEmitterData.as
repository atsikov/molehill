package model.data
{
	import molehill.core.render.particles.ParticleEmitterShape;

	public class ParticleEmitterData
	{
		public function ParticleEmitterData()
		{
		}
		
		public var name:String = null;
		public var textureID:String = null;
		public var redMultiplier:Number = 1;
		public var greenMultiplier:Number = 1;
		public var blueMultiplier:Number = 1;
		public var endRedMultiplier:Number = 1;
		public var endGreenMultiplier:Number = 1;
		public var endBlueMultiplier:Number = 1;
		public var appearInterval:int = 15;
		public var appearCount:int = 10;
		public var lifeTime:int = 1000;
		public var emitterShape:String = ParticleEmitterShape.ELLIPTIC;
		public var xRadius:int = 0;
		public var yRadius:int = 0;
		public var accelerationX:int = 0;
		public var accelerationXDeviation:int = 0;
		public var accelerationY:int = 0;
		public var accelerationYDeviation:int = 0;
		public var speedX:int = 0;
		public var speedXDeviation:int = 0;
		public var speedY:int = 0;
		public var speedYDeviation:int = 0;
		public var startAlpha:Number = 1;
		public var endAlpha:Number = 1;
		public var startScale:Number = 1;
		public var startScaleDeviation:Number = 0;
		public var endScale:Number = 1;
		public var endScaleDeviation:Number = 0;
	}
}