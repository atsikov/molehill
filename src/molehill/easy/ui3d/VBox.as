package molehill.easy.ui3d
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3DContainer;
	
	public class VBox extends Sprite3DContainer
	{
		public function VBox()
		{
			addEventListener(Event.RESIZE, onResize);
		}
		
		private function onResize(event:Event):void
		{
			var target:DisplayObject = event.target as DisplayObject;
			if(target != this && this.contains(target))
			{
				resize();
			}
		}
		
		public var isCenter:Boolean = true;
		public var space:int = 10;

		protected var _boxWidth:Number;
		protected var _boxHeight:Number;
		
		public function clear():void
		{
			while (numChildren > 0)
			{
				removeChildAt(0);
			}
			_boxWidth = 0;
			_boxHeight = 0;
		}
		
		protected var _background:DisplayObject;
		public function setBackground(bg:DisplayObject, x:Number = 0, y:Number = 0):void
		{
			if(bg != null)
			{
				_background = bg;
				_background.x = x;
				_background.y = y;
				addChildAt(_background, 0);
			}
			else
			{
				if(_background != null && this.contains(_background))
				{
					removeChild(_background);
				}
			}
		}
		
		override public function resize():void
		{
			var numChildren:int = this.numChildren;
			if (numChildren > 0)
			{
				var i:int;
				
				var boundsWidth:Number = 0;
				var boundsHeight:Number = 0;
				var child:DisplayObject;
				for (i = 0; i < numChildren; i++)
				{
					child = getChildAt(i);
					if(i == 0 && child == _background)
					{
						continue;
					}
					if (child.width > boundsWidth)
					{
						boundsWidth = child.width;
					}
					boundsHeight += child.height;
				}
				
				boundsHeight += space * (numChildren - 1);
				var center:Number;
				var currentY:Number;
				if (autosize)
				{
					center = boundsWidth / 2;
					currentY = 0;
					
					_boxWidth = boundsWidth;
					_boxHeight = boundsHeight;
				}
				else
				{
					center = width / 2;
					currentY = (height - boundsHeight) / 2;
				}
				
				for (i = 0; i < numChildren; i++)
				{
					child = getChildAt(i);
					if(i == 0 && child == _background)
					{
						continue;
					}
					child.x = isCenter ? int(center - child.width / 2) : 0;
					child.y = int(currentY);
					currentY += child.height + space;
				}
			}
			else
			{
				if(autosize)
				{
					_boxWidth = 0;
					_boxHeight = 0;
				}
			}
		}
		
		private var _autosize:Boolean = true;
		public function get autosize():Boolean
		{
			return _autosize;
		}
		public function set autosize(value:Boolean):void
		{
			_autosize = value;
		}
	}
}