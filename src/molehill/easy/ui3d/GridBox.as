package molehill.easy.ui3d
{
	import molehill.core.sprite.Sprite3D;
	
	public class GridBox extends VBox
	{
		private var _align:String = GridBoxAlign.ALIGN_LEFT;
		public function get align():String
		{
			return _align;
		}

		public function set align(value:String):void
		{
			_align = value;
		}

		
		private var _numElementsPerRow:int = 4;
		public function get numElementsPerRow():int
		{
			return _numElementsPerRow;
		}
		
		public function set numElementsPerRow(value:int):void
		{
			if (_numElementsPerRow < 1)
			{
				return;
			}
			
			_numElementsPerRow = value;
		}
		
		private var _vSpace:int = 10;
		public function get vSpace():int
		{
			return _vSpace;
		}
		
		public function set vSpace(value:int):void
		{
			_vSpace = value;
		}
		
		private var _hSpace:int = 10;
		public function get hSpace():int
		{
			return _hSpace;
		}
		
		public function set hSpace(value:int):void
		{
			_hSpace = value;
			space = value;
		}
		
		override public function resize():void
		{
			var numChildren:int = this.numChildren;
			if (numChildren > 0)
			{
				var numChildrenPlaced:int = 0;
				var currentX:Number = 0;
				var currentY:int = 0;
				var maxBoundsWidth:int = 0;
				var listBoundWidths:Array = new Array();
				while (numChildrenPlaced < numChildren)
				{
					var i:int;
					
					var boundsWidth:Number = 0;
					var boundsHeight:Number = 0;
					var child:Sprite3D;
					for (i = numChildrenPlaced; i < numChildrenPlaced + _numElementsPerRow; i++)
					{
						if (i >= numChildren)
						{
							break;
						}
						
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
					
					boundsWidth += _hSpace * (_numElementsPerRow - 1);
					listBoundWidths.push(boundsWidth);
					
					if (_align != GridBoxAlign.ALIGN_LEFT && maxBoundsWidth < boundsWidth)
					{
						for (i = 0; i < numChildrenPlaced; i++)
						{
							child = getChildAt(i);
							if(i == 0 && child == _background)
							{
								continue;
							}
							
							var shift:int = maxBoundsWidth - listBoundWidths[int(i / _numElementsPerRow)];
							if (_align == GridBoxAlign.ALIGN_CENTER)
							{
								shift = int(shift / 2);
							}
							child.x += shift;
							
							if ((i % _numElementsPerRow) == _numElementsPerRow - 1)
							{
								listBoundWidths[int(i / _numElementsPerRow)] = maxBoundsWidth;
							}
						}
						
						maxBoundsWidth = boundsWidth;
					}
					
					switch (_align)
					{
						case GridBoxAlign.ALIGN_CENTER:
							currentX = int((maxBoundsWidth - boundsWidth) / 2);
							break;
						
						case GridBoxAlign.ALIGN_RIGHT:
							currentX = maxBoundsWidth - boundsWidth;
							break;
						
						default:
							currentX 0;
					}
					
					_boxWidth = maxBoundsWidth;
					_boxHeight = currentY + _vSpace + boundsHeight;
					
					for (i = numChildrenPlaced; i < numChildrenPlaced + _numElementsPerRow; i++)
					{
						if (i >= numChildren)
						{
							break;
						}
						
						child = getChildAt(i);
						if(i == 0 && child == _background)
						{
							continue;
						}
						child.moveTo(int(currentX), currentY);
						currentX += child.width + _hSpace;
					}
					currentY += _vSpace + boundsHeight;
					
					numChildrenPlaced += _numElementsPerRow;
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