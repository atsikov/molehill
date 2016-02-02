package molehill.core.render.camera
{
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;

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
		
		private var _owner:Sprite3D;
		public function get owner():Sprite3D
		{
			return _owner;
		}
		
		public function set owner(value:Sprite3D):void
		{
			_owner = value;
		}
		
		public function copyValues(camera:CustomCamera):void
		{
			if (camera == null)
			{
				reset();
				return;
			}
			
			_scrollX = camera._scrollX;
			_scrollY = camera._scrollY;
			_scale = camera._scale;
			
			var referenceRect:Rectangle = camera._scissorRect;
			if (referenceRect != null)
			{
				if (_scissorRect == null)
				{
					_scissorRect = referenceRect.clone();
				}
				else
				{
					_scissorRect.copyFrom(referenceRect);
				}
			}
		}
		
		public function isEqual(reference:CustomCamera):Boolean
		{
			var referenceScissorRect:Rectangle = reference._scissorRect;
			return _scrollX == reference._scrollX &&
				_scrollY == reference._scrollY &&
				scale == reference._scale &&
				(_scissorRect == null && referenceScissorRect == null ||
				 _scissorRect != null && referenceScissorRect != null && _scissorRect.equals(referenceScissorRect));
		}
	}
}