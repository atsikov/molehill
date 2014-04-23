package molehill.easy.ui3d.effects
{
	import flash.events.Event;
	
	import molehill.core.sprite.Sprite3D;

	public class ZoomInEffect extends Effect
	{
		public function ZoomInEffect()
		{
			super();
		}
		
		public var speedX:Number = 0.01;		
		public var speedY:Number = 0.001;
		
		public var accelerationX:Number = 0.05;
		public var accelerationY:Number = 0.05;
				
		private var _srcCenterX:Number;
		private var _srcCenterY:Number;
		private var _srcWidth:Number;
		private var _srcHeight:Number;
				
		public var destinationX:Number = 1.0;
		public var destinationY:Number = 1.0;
		
		override public function showEffect(target:Sprite3D, completeCallback:Function = null) : void
		{			
			_srcWidth = target.width;
			_srcHeight = target.height;
			_srcCenterX = target.x + _srcWidth / 2;
			_srcCenterY = target.y + _srcHeight / 2;
			
			target.scaleX = 0.01;
			target.scaleY = 0.01;
			
			super.showEffect(target, completeCallback);
		}
		
		override protected function onTimer(event:Event):void
		{
			speedX += accelerationX;
			speedY += accelerationY;
			
			_target.scaleX += speedX;
			_target.scaleY += speedY;
			_target.x = _srcCenterX - _srcWidth * _target.scaleX / 2;
			_target.y = _srcCenterY - _srcHeight * _target.scaleY / 2;
			
			var directionXSign:int = accelerationX > 0 ? +1 : -1;
			var restX:Number = destinationX - _target.scaleX;
			
			var directionYSign:int = accelerationY > 0 ? +1 : -1;
			var restY:Number = destinationY - _target.scaleY;			
			
			if (directionXSign > 0)
			{
				if ( restX < 0 || restX <= (speedX / 2)  )
				{
					speedX = 0;
					accelerationX = 0;
					
					_target.scaleX = 1.0;
					_target.x = _srcCenterX - _target.width / 2;
				}
			}
			else
			{
				if ( restX > 0 || (-restX <= (-speedX / 2))  )
				{
					speedX = 0;
					accelerationX = 0;
					
					_target.scaleX = 1.0;
					_target.x = _srcCenterX - _target.width / 2;
				}
			}
			
			
			if (directionYSign > 0)
			{
				if ( restY < 0 || restY <= (speedY / 2)  )
				{
					speedY = 0;
					accelerationY = 0;
					
					_target.scaleY = 1.0;
					_target.y = _srcCenterY - _target.height / 2;
				}
			}
			else
			{
				if ( restY > 0 || (-restY <= (-speedY / 2))  )
				{
					speedY = 0;
					accelerationY = 0;
					
					_target.scaleY = 1.0;
					_target.y = _srcCenterY - _target.height / 2;
				}
			}
				
			if ((accelerationX == 0) && (accelerationY == 0))
			{
				completeEffect();
			}
		}
		
		public override function restoreNormal() : void
		{
			_target.scaleX = _target.scaleY = 1;
		}
		
		public override function clone():Effect
		{
			return new ZoomInEffect();
		}
	}
}