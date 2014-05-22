package molehill.easy.ui3d.list
{
	import easy.core.Direction;
	import easy.ui.IEasyItemRenderer;
	import easy.ui.ILockableEasyItemRenderer;
	import easy.ui.ISizeable;
	
	import flash.events.Event;
	import flash.utils.Dictionary;
	
	
	public class EasyTileList3D extends EasyList3D
	{
		public function EasyTileList3D()
		{
			super();
		}
		
		protected var _direction:String = Direction.VERTICAL;
		public function get direction():String
		{
			return _direction;
		}
		public function set direction(value:String):void
		{
			if (_direction == value)
				return;
			
			_direction = value;
			
			this.currentItem = currentItem;//нужно пересчитать, чтобы за пределы не уйти
			update();
		}
		
		// скролл может быть лишь по одному заданному направлению построения списка
		// другая сторона(горизонталь или вертикаль) фиксированны
		protected var _scrollPosition:int = 0;
		public function get currentPage():int
		{
			return int(_scrollPosition / numItemsPerPage);
		}
		public function set currentPage(value:int):void
		{
			var pageMax:int = this.scrollPageMax;			
			if (value > pageMax)
				value = pageMax;
			if (value < 0)
				value = 0;
			
			if ((value * numItemsPerPage) == _scrollPosition)
				return;
			
			_scrollPosition = value * numItemsPerPage;
			update();
		}
		
		public function get currentItem():int
		{
			var scrollPosition:int = _scrollPosition;
			switch (_direction)
			{
				case Direction.HORIZONTAL:
					scrollPosition /= columnCount;
					break;
				
				case Direction.VERTICAL:
					scrollPosition /= rowCount;
					break;
			}
			return scrollPosition;
		}
		
		public function set currentItem(value:int):void
		{
			var maxItem:int = scrollItemMax;
			if (value > maxItem)
			{
				value = maxItem;
			}
			if (value < 0)
			{
				value = 0;
			}
			
			switch (_direction)
			{
				case Direction.HORIZONTAL:
					_scrollPosition = value * columnCount;
					break;
				
				case Direction.VERTICAL:
					_scrollPosition = value * rowCount;
					break;
			}
			update();
		}
		
		public function get scrollPageMax():int
		{
			if (dataSource == null)
				return 0;
			
			var numItemsRest:int = numItems - numItemsPerPage;
			if (numItemsRest <= 0)
				return 0;
			
			var valueMax:int = 0;
			switch (_direction)
			{
				case Direction.HORIZONTAL:
					valueMax = Math.ceil(numItemsRest / numItemsPerPage);
					break;
				
				case Direction.VERTICAL:
					valueMax = Math.ceil(numItemsRest / numItemsPerPage);
					break;
			}
			
			return valueMax;
		}
		
		public function get scrollItemMax():int
		{
			if (dataSource == null)
				return 0;
			
			var numItemsRest:int = numItems - numItemsPerPage;
			if (numItemsRest <= 0)
				return 0;
			
			var valueMax:int = 0;
			switch (_direction)
			{
				case Direction.HORIZONTAL:
					valueMax = Math.ceil(numItemsRest / columnCount);
					break;
				
				case Direction.VERTICAL:
					valueMax = Math.ceil(numItemsRest / rowCount);
					break;
			}
			
			return valueMax;
		}
		
		protected function get numItemsPerPage():int
		{
			return rowCount * columnCount;
		}
		
		protected var _autoSize:Boolean = false;
		public function get autoSize():Boolean
		{
			return _autoSize;
		}
		public function set autoSize(value:Boolean):void
		{
			_autoSize = value;
		}
		
		protected var _rowCount:int;
		public function get rowCount():int
		{
			if (_autoSize && direction == Direction.VERTICAL)
			{
				if (dataSource != null)
				{
					return Math.ceil( uint(dataSource['length']) / columnCount );
				}
			}
			
			return _rowCount;
		}
		public function set rowCount(value:int):void
		{
			_rowCount = value;
		}
		
		protected var _columnCount:int = 1;
		public function get columnCount():int
		{
			if (_autoSize && direction == Direction.HORIZONTAL)
			{
				if (dataSource != null)
				{
					return Math.ceil( uint(dataSource['length']) / rowCount );
				}
			}
			
			return _columnCount;
		}
		public function set columnCount(value:int):void
		{
			_columnCount = value;
		}
		
		protected var _rowHeight:int;
		public function get rowHeight():int
		{
			return _rowHeight;
		}
		public function set rowHeight(value:int):void
		{
			_rowHeight = value;
		}
		
		protected var _columnWidth:int;
		public function get columnWidth():int
		{
			return _columnWidth;
		}
		public function set columnWidth(value:int):void
		{
			_columnWidth = value;
		}
		
		protected var _rowsGap:int;
		public function get rowsGap():int
		{
			return _rowsGap;
		}
		public function set rowsGap(value:int):void
		{
			_rowsGap = value;
		}
		
		protected var _columnsGap:int;
		public function get columnsGap():int
		{
			return _columnsGap;
		}
		public function set columnsGap(value:int):void
		{
			_columnsGap = value;
		}
		
		protected var _showEmptyCells:Boolean = true;
		public function get showEmptyCells():Boolean
		{
			return _showEmptyCells;
		}
		public function set showEmptyCells(value:Boolean):void
		{
			_showEmptyCells = value;
		}
		
		// this method is used in tutorials where we need to highlight a certain renderer
		public function getItemRendererByIndex(index:int):IEasyItemRenderer
		{
			return _dictCurrentStateItemRenderersByData[dataSource[index + currentItem]];
		}
		
		//--------------------------------------------------------------------------
		override protected function initItemRenderer(itemRenderer:IEasyItemRenderer):void
		{
			if (itemRenderer is ISizeable)
			{
				(itemRenderer as ISizeable).setSize(
					_columnWidth, _rowHeight
				);
			}
		}
		
		override protected function updateOnDataSourceChange():void
		{
			if (numItems < _scrollPosition)
			{
				switch (_direction)
				{
					case Direction.HORIZONTAL:
						currentItem = _scrollPosition / columnCount;
						break;
					
					case Direction.VERTICAL:
						currentItem = _scrollPosition / rowCount;
						break;
				}
			}
			
			super.updateOnDataSourceChange();
		}
		
		override protected function doUpdate():void
		{
			var dataBeginIdx:int = _scrollPosition;
			
			var dataEndIdx:int = dataBeginIdx + numItemsPerPage;
			var numItems:int = this.numItems;
			if (dataEndIdx >= numItems)
				dataEndIdx = numItems;
			
			var dictCurrentStateItemRenderersByData:Dictionary = _dictCurrentStateItemRenderersByData;
			var dictNewStateItemRenderersByData:Dictionary = new Dictionary();
			//---
			var offsetRows:int = dataBeginIdx / columnCount;
			var offsetColumns:int = dataBeginIdx % columnCount;
			//---
			var viewRow:int = 0;
			var viewColumn:int = -1;
			var itemRenderer:IEasyItemRenderer;
			
			var cy:int = 0;
			var rowHeight:int = 0;
			for (var i:int = dataBeginIdx; i < dataEndIdx; i++)
			{
				
				switch (_direction)
				{
					case Direction.HORIZONTAL:
						viewRow		= (i - dataBeginIdx) / columnCount;
						viewColumn	= (i - dataBeginIdx) % columnCount;
						break;
					
					case Direction.VERTICAL:
						viewRow		= (i - dataBeginIdx) % rowCount;
						viewColumn	= (i - dataBeginIdx) / rowCount;
						break;
				}
				var itemData:* = getItemData(i);
				itemRenderer = dictCurrentStateItemRenderersByData[itemData] as IEasyItemRenderer;
				if (itemRenderer == null)
				{
					itemRenderer = getItemRenderer();
				}
				else
				{
					delete dictCurrentStateItemRenderersByData[itemData];
				}
				
				itemRenderer.x = viewColumn * (_columnWidth + _columnsGap);
				itemRenderer.y = viewRow * (_rowHeight + _rowsGap);
				itemRenderer.itemData = itemData;
				itemRenderer.selected = isItemSelected(itemData);
				itemRenderer.highlighted = false;
				if (!(itemRenderer is ILockableEasyItemRenderer) || !(itemRenderer as ILockableEasyItemRenderer).locked)
					itemRenderer.update();
				
				rowHeight = Math.max(rowHeight, itemRenderer.height);
				
				dictNewStateItemRenderersByData[itemData] = itemRenderer;
			}
			_croppedHeight = Math.max(
				cy + rowHeight,
				0
			);
			//---
			for each(itemRenderer in dictCurrentStateItemRenderersByData)
			{
				if (itemRenderer == null)
					continue;
				
				freeItemRenderer(itemRenderer);
			}
			_dictCurrentStateItemRenderersByData = dictNewStateItemRenderersByData;
			
			freeAllEmptyItemRenderers();
			if (_showEmptyCells)
			{
				viewColumn++;
				for (; viewRow < rowCount; viewRow++, viewColumn = 0)
				{
					for (; viewColumn < columnCount; viewColumn++)
					{
						itemRenderer = getEmptyItemRenderer();
						itemRenderer.x = viewColumn * (_columnWidth + _columnsGap);
						itemRenderer.y = viewRow * (_rowHeight + _rowsGap);
					}
				}
			}
			
			if (autoSize)
			{
				dispatchEvent(
					new Event(Event.RESIZE)
				);
			}
		}
	}
}