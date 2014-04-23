package molehill.core.render.camera
{
	import flash.geom.Rectangle;

	public class CustomCamera
	{
		public function CustomCamera()
		{
		}
		
		private var _scrollX:Number = 0;
		public function get scrollX():Number
		{
			return _scrollX;
		}
		
		public function set scrollX(value:Number):void
		{
			_scrollX = value;
		}
		
		private var _scrollY:Number = 0;
		public function get scrollY():Number
		{
			return _scrollY;
		}
		
		public function set scrollY(value:Number):void
		{
			_scrollY = value;
		}
		
		private var _scale:Number = 1;
		public function get scale():Number
		{
			return _scale;
		}
		
		public function set scale(value:Number):void
		{
			_scale = value;
		}
		
		private var _scissorRect:Rectangle;
		public function get scissorRect():Rectangle
		{
			return _scissorRect;
		}
		
		public function set scissorRect(value:Rectangle):void
		{
			_scissorRect = value;
		}
		
		public function reset():void
		{
			_scrollX = 0;
			_scrollY = 0;
			_scale = 1;
			_scissorRect = null;
		}
		
		public function copyValues(camera:CustomCamera):void
		{
			_scrollX = camera.scrollX;
			_scrollY = camera.scrollY;
			_scale = camera.scale;
			
			var referenceRect:Rectangle = camera.scissorRect;
			if (referenceRect != null)
			{
				if (_scissorRect == null)
				{
					_scissorRect = camera.scissorRect.clone();
				}
				else
				{
					_scissorRect.copyFrom(referenceRect);
				}
			}
		}
		
		public function isEqual(reference:CustomCamera):Boolean
		{
			return _scrollX == reference.scrollX &&
				_scrollY == reference.scrollY &&
				scale == reference.scale &&
				(_scissorRect == null && reference.scissorRect == null ||
				 _scissorRect != null && reference.scissorRect != null && _scissorRect.equals(reference._scissorRect));
		}
	}
}