package molehill.core.render
{
	internal class ParticleData
	{
		public function ParticleData()
		{
			super();
		}
		
		private var _shiftX:Number = 0;
		public function get shiftX():Number
		{
			return _shiftX;
		}

		public function set shiftX(value:Number):void
		{
			_shiftX = value;
		}

		private var _shiftY:Number = 0;
		public function get shiftY():Number
		{
			return _shiftY;
		}

		public function set shiftY(value:Number):void
		{
			_shiftY = value;
		}

		private var _speedX:Number = 0;
		public function get speedX():Number
		{
			return _speedX;
		}

		public function set speedX(value:Number):void
		{
			_speedX = value;
		}

		private var _speedY:Number = 0;
		public function get speedY():Number
		{
			return _speedY;
		}

		public function set speedY(value:Number):void
		{
			_speedY = value;
		}

		private var _accelerationX:Number = 0;
		public function get accelerationX():Number
		{
			return _accelerationX;
		}

		public function set accelerationX(value:Number):void
		{
			_accelerationX = value;
		}

		private var _accelerationY:Number = 0;
		public function get accelerationY():Number
		{
			return _accelerationY;
		}

		public function set accelerationY(value:Number):void
		{
			_accelerationY = value;
		}

		private var _appearTime:uint = 0;
		public function get appearTime():uint
		{
			return _appearTime;
		}

		public function set appearTime(value:uint):void
		{
			_appearTime = value;
		}

		private var _lifeTime:uint = 0;
		public function get lifeTime():uint
		{
			return _lifeTime;
		}

		public function set lifeTime(value:uint):void
		{
			_lifeTime = value;
		}

	}
}