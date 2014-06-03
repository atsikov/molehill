package molehill.easy.ui3d
{
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	
	public class HBox extends VBox
	{	
		override public function resize():void
		{
			var numChildren:int = this.numChildren;
			if (numChildren > 0)
			{
				var i:int;
				
				var boundsWidth:Number = 0;
				var boundsHeight:Number = 0;
				var child:Sprite3D;
				for (i = 0; i < numChildren; i++)
				{
					child = getChildAt(i);
					if(i == 0 && child == _background)
					{
						continue;
					}
					if (child.height > boundsHeight)
					{
						boundsHeight = child.height;
					}
					boundsWidth += child.width;
				}
				
				boundsWidth += space * (numChildren - 1);
				var center:Number;
				var currentX:Number;
				if (autosize)
				{
					center = boundsHeight / 2;
					currentX = 0;
					
					_boxWidth = boundsWidth;
					_boxHeight = boundsHeight;
				}
				else
				{
					center = height / 2;
					currentX = (width - boundsWidth) / 2;
				}
				
				for (i = 0; i < numChildren; i++)
				{
					child = getChildAt(i);
					if(i == 0 && child == _background)
					{
						continue;
					}
					child.moveTo(int(currentX), isCenter ? int(center - child.height / 2) : 0);
					currentX += child.width + space;
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
	}
}