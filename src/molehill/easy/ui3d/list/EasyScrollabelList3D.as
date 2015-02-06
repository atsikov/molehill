package molehill.easy.ui3d.list
{
	import easy.collections.ISimpleCollection;
	import easy.collections.events.CollectionEvent;
	import easy.core.Direction;
	import easy.core.IFactory;
	import easy.ui.IEasyItemRenderer;
	import easy.ui.ILockableEasyItemRenderer;
	
	import fl.motion.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.getTimer;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.UIComponent3D;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	import molehill.easy.ui3d.GridBox;
	import molehill.easy.ui3d.scroll.KineticScrollContainer;
	
	import org.opentween.OpenTween;

	public class EasyScrollabelList3D extends KineticScrollContainer
	{
		public function EasyScrollabelList3D()
		{
			super();
		}
		
		override protected function onScrollStarted():void
		{
			for (var i:int = 0; i < _itemsContainer.numChildren; i++) 
			{
				var item:ILockableEasyItemRenderer = _itemsContainer.getChildAt(i) as ILockableEasyItemRenderer;
				
				if (item != null)
				{
					item.locked = true;
				}
			}
		}
		
		override protected function onScrollCompleted():void
		{
			for (var i:int = 0; i < _itemsContainer.numChildren; i++) 
			{
				var item:ILockableEasyItemRenderer = _itemsContainer.getChildAt(i) as ILockableEasyItemRenderer;
				
				if (item != null)
				{
					item.locked = false;
				}
			}
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
		
		//==================
		// list settings
		//==================
		
		private var LINE_ANIMATION_TIME:Number = 0.1;
		
		
		private var _updateCallback:Function;
		public function set updateCallback(value:Function):void
		{
			_updateCallback = value;
		}
		
		private var _mouseScrollingEnabled:Boolean = true;
		
		/** enable/disable mouse scrolling */
		public function set mouseScrollingEnabled(value:Boolean):void
		{
			_mouseScrollingEnabled = value;
		}
		
		
		private var _mouseScrollShortListLock:Boolean = false;
		
		/** set to true to disable mouse scrolling, when numItems < numItemsPerPage */
		public function set lockMouseScrollShortList(value:Boolean):void
		{
			_mouseScrollShortListLock = value;
		}
		
		private var _snapToClosestItem:Boolean = false;
		
		/** Enables snapping to closest item in the end of kinetic scroll.
		 * Disabled by default.
		 */
		public function set snapToClosestItem(value:Boolean):void
		{
			_snapToClosestItem = value;
		}
		
		override protected function onItemsContainerMouseDown(event:Input3DMouseEvent):void
		{
			if (!_mouseScrollingEnabled)
			{
				return;
			}
			
			if (_mouseScrollShortListLock)
			{
				var viewPortSize:Number = _direction == Direction.HORIZONTAL ? _viewPort.height : _viewPort.width;
				if (_itemsContainerSize <= viewPortSize)
				{
					return;
				}
			}
			
			super.onItemsContainerMouseDown(event);
		}
		
		//==================
		// paging
		//==================
		
		public function get canScrollToStart():Boolean
		{
			if (_firstVisibleIndex > 0)
			{
				return true;
			}
			
			return _direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY > topBorder : _itemsContainerCamera.scrollX > leftBorder;
		}
		
		public function get canScrollToEnd():Boolean
		{
			if (_lastVisibleIndex < _dataSource.length - 1)
			{
				return true;
			}
			
			return _direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY < bottomBorder : _itemsContainerCamera.scrollX < rightBorder;
		}
		
		public function get currentItem():uint
		{
			return _firstVisibleIndex;
		}
		
		public function set currentItem(itemIndex:uint):void
		{
			if (_dataSource == null)
			{
				return;
			}
			
			_itemsContainerCamera.scrollX = 0;
			_itemsContainerCamera.scrollY = 0;
			
			itemIndex = Math.min(itemIndex, _dataSource.length - 1);
			_firstVisibleIndex = Math.floor(itemIndex / _numElementsPerRow) * _numElementsPerRow;
			updateItems();
			
			var scrolledBack:Boolean = false;
			
			while (_lastVisibleIndex == _dataSource.length - 1)
			{
				_firstVisibleIndex -= _numElementsPerRow;
				updateItems();
				
				scrolledBack = true;
			}
			
			if (scrolledBack)
			{
				nextLine();
			}
			else
			{
				checkBorders();
			}
		}
		
		public function nextLine():void
		{
			if (_animation != null)
			{
				_animation.stop();
			}
			
			stopScrolling();
			
			_animation = OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : _direction == Direction.VERTICAL ? _secondRowPosition + 1 : 0,
					scrollY : _direction == Direction.VERTICAL ? 0 : _secondRowPosition + 1
				},
				LINE_ANIMATION_TIME,
				0,
				Linear.easeOut,
				onLineScrollingComplete,
				onLineScrollingUpdate
			);
		}
		
		public function previousLine():void
		{
			if (_animation != null)
			{
				_animation.stop();
			}
			
			stopScrolling();
			
			_animation = OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : _direction == Direction.VERTICAL ? _previousRowPosition - 1 : 0,
					scrollY : _direction == Direction.VERTICAL ? 0 : _previousRowPosition - 1
				},
				LINE_ANIMATION_TIME,
				0,
				Linear.easeOut,
				onLineScrollingComplete,
				onLineScrollingUpdate
			);
		}
		
		private function onLineScrollingComplete():void
		{
			checkBorders();
			completeScrolling();
		}
		
		private function onLineScrollingUpdate():void
		{
			if (checkBorders())
			{
				completeScrolling();
			}
		}
		
		//==================
		// elements settings
		//==================
		
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
		
		private var _numElementsPerRow:int = 1;
		public function get numElementsPerRow():int
		{
			return _numElementsPerRow;
		}
		
		public function set numElementsPerRow(value:int):void
		{
			if (value < 1)
			{
				return;
			}
			
			_numElementsPerRow = value;
		}
		
		protected var _direction:String = Direction.HORIZONTAL;
		public function get direction():String
		{
			return _direction;
		}
		public function set direction(value:String):void
		{
			if (_direction == value)
				return;
			
			_direction = value;
			
			scrollDirection = _direction == Direction.HORIZONTAL ? VERTICAL : HORIZONTAL;
			
			updateItems();
		}
		
		
		private var _dataSource:*;
		public function get dataSource():*
		{
			return _dataSource;
		}
		public function set dataSource(value:*):void
		{
			if (_dataSource != null)
			{
				if (_dataSource is ISimpleCollection)
				{
					(_dataSource as ISimpleCollection).removeEventListener(CollectionEvent.COLLECTION_CHANGED, onDataSourceChanged);
				}
			}	
			
			_dataSource = value;
			
			if (_dataSource != null)
			{
				if (_dataSource is ISimpleCollection)
				{
					(_dataSource as ISimpleCollection).addEventListener(CollectionEvent.COLLECTION_CHANGED, onDataSourceChanged);
				}
			}
			
			updateOnDataSourceChange();
		}
		
		private function onDataSourceChanged(event:Event):void
		{
			update();
		}
		
		protected function updateOnDataSourceChange():void
		{
			stopScrolling();
			
			_itemsContainer.camera.scrollX = 0;
			_itemsContainer.camera.scrollY = 0;
			
			_firstVisibleIndex = 0;
			
			update();
		}
		
		private var _itemRendererFactory:IFactory;
		public function get itemRendererFactory():IFactory
		{
			return _itemRendererFactory;
		}
		public function set itemRendererFactory(value:IFactory):void
		{
			_itemRendererFactory = value;
		}
		
		private var _emptyItemRendererFactory:IFactory;
		public function get emptyItemRendererFactory():IFactory
		{
			return _emptyItemRendererFactory;
		}
		public function set emptyItemRendererFactory(value:IFactory):void
		{
			_emptyItemRendererFactory = value;
		}
		
		private function createItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:Sprite3D = _itemRendererFactory.newInstance() as Sprite3D;
			
			return itemRenderer as IEasyItemRenderer;
		}
		
		private var _listFreeItemRenderers:Array = new Array();
		protected final function getItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:IEasyItemRenderer = null;
			
			while ( _listFreeItemRenderers.length > 0 && itemRenderer == null )
			{
				itemRenderer = _listFreeItemRenderers.pop() as IEasyItemRenderer;
			}
			
			if (itemRenderer == null)
			{
				itemRenderer = createItemRenderer();
			}
			
			addChild(itemRenderer as Sprite3D);
			
			return itemRenderer;
		}
		
		protected final function freeItemRenderer(itemRenderer:IEasyItemRenderer):void
		{
			if (itemRenderer == null)
			{
				return;
			}
			
			itemRenderer.itemData = null;
			itemRenderer.selected = false;
			itemRenderer.highlighted = false;
			
			var displayObject:Sprite3D = itemRenderer as Sprite3D;
			if ( displayObject != null && displayObject.parent != null )
			{
				displayObject.parent.removeChild(displayObject);
			}
			
			_listFreeItemRenderers.push(
				itemRenderer
			);
		}
		
		//==================
		// scroll limits
		//==================
		private var _firstVisibleIndex:uint = 0;
		private var _lastVisibleIndex:uint = 0;
		
		private var _previousRowPosition:Number = 0;
		private var _secondRowPosition:Number = 0;
		private var _itemsContainerSize:Number = 0;

		
		override protected function checkBottomBorder():Boolean
		{
			if (_lastVisibleIndex < (_dataSource.length - 1))
			{
				while (_itemsContainerCamera.scrollY > _secondRowPosition && _lastVisibleIndex < (_dataSource.length - 1))
				{
					_itemsContainerCamera.scrollY -= _secondRowPosition;
					_firstVisibleIndex += _numElementsPerRow;
					updateItems();
				}
			}
			
			if (_lastVisibleIndex == _dataSource.length - 1)
			{
				if (_itemsContainerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
				{
					_itemsContainerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		override protected function get bottomBorder():Number
		{
			if (_itemsContainer.numChildren > 0 && _itemsContainerSize > _viewPort.height)
			{
				return _itemsContainerSize - _viewPort.height - _viewPort.y + bottomGap;
			}
			else
			{
				return 0;
			}
		}
		
		override protected function checkTopBorder():Boolean
		{
			if (_firstVisibleIndex != 0)
			{
				while (_itemsContainerCamera.scrollY < _previousRowPosition && _firstVisibleIndex != 0)
				{
					_itemsContainerCamera.scrollY -= _previousRowPosition;
					_firstVisibleIndex -= _numElementsPerRow;
					updateItems();
				}
			}
			
			if (_firstVisibleIndex == 0)
			{
				if (_itemsContainerCamera.scrollY < topBorder - ELASCTIC_SIZE)
				{
					_itemsContainerCamera.scrollY = topBorder - ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		
		override protected function checkRightBorder():Boolean
		{
			if (_lastVisibleIndex < (_dataSource.length - 1))
			{
				while (_itemsContainerCamera.scrollX > _secondRowPosition && _lastVisibleIndex < (_dataSource.length - 1))
				{
					_itemsContainerCamera.scrollX -= _secondRowPosition;
					_firstVisibleIndex += _numElementsPerRow;
					updateItems();
				}
			}
			
			if (_lastVisibleIndex == _dataSource.length - 1)
			{
				if (_itemsContainerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
				{
					_itemsContainerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		override protected function get rightBorder():Number
		{
			if (_itemsContainer.numChildren > 0 && _itemsContainerSize > _viewPort.width)
			{
				return _itemsContainerSize - _viewPort.width - _viewPort.x + rightGap;
			}
			else
			{
				return 0;
			}
		}
		
		override protected function checkLeftBorder():Boolean
		{
			if (_firstVisibleIndex != 0)
			{
				while (_itemsContainerCamera.scrollX < _previousRowPosition && _firstVisibleIndex != 0)
				{
					_itemsContainerCamera.scrollX -= _previousRowPosition;
					_firstVisibleIndex -= _numElementsPerRow;
					updateItems();
				}
			}
			
			if (_firstVisibleIndex == 0)
			{
				if (_itemsContainerCamera.scrollX < leftBorder - ELASCTIC_SIZE)
				{
					_itemsContainerCamera.scrollX = leftBorder - ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		
		//==================
		// update everything
		//==================
		
		public function update():void
		{
			if (_firstVisibleIndex > _dataSource.length - 1)
			{
				_firstVisibleIndex = Math.max(_dataSource.length - _numElementsPerRow, 0);
			}
			
			updateItems();
		}
		
		private var _helperCache:Object = new Object();
		private function updateItems():void
		{
			if (dataSource == null)
			{
				while (_itemsContainer.numChildren > 0)
				{
					_itemsContainer.removeChildAt(0);
				}
				return;
			}
			
			_previousRowPosition = 0;
			_secondRowPosition = 0;
			
			var currentX:int = 0;
			var currentY:int = 0;
			var rowHeight:int = 0;
			var rowWidth:int = 0;
			
			_itemsContainerSize = 0;
			
			var j:int;
			
			var child:Sprite3D;
			var itemRenderer:IEasyItemRenderer;
			var breakOnNextLine:Boolean = false;
			
			var numVisibleItems:uint = 0;
			
			var dataBeginIndex:int = Math.max(_firstVisibleIndex - _numElementsPerRow, 0);
			
			for (var i:int = dataBeginIndex; i < dataSource.length; i++) 
			{
				if (!breakOnNextLine)
				{
					_lastVisibleIndex = i;
				}
				
				if (_itemsContainer.numChildren > i - dataBeginIndex)
				{
					itemRenderer = _itemsContainer.getChildAt(i - dataBeginIndex) as IEasyItemRenderer;
				}
				else
				{
					itemRenderer = getItemRenderer();
					_itemsContainer.addChild(itemRenderer as Sprite3D);
				}
				
				itemRenderer.itemData = dataSource[i];
				itemRenderer.update();
				
				if (i < _firstVisibleIndex)
				{
					_helperCache[(i - dataBeginIndex) + "x"] = currentX;
					_helperCache[(i - dataBeginIndex) + "y"] = currentY;
				}
				else
				{
					if (itemRenderer.x != currentX || itemRenderer.y != currentY)
					{
						(itemRenderer as Sprite3D).moveTo(
							currentX,
							currentY
						);
					}
				}
				
				numVisibleItems++;
				
				if (_direction == Direction.HORIZONTAL)
				{
					rowHeight = Math.max((itemRenderer as Sprite3D).height, rowHeight);
					
					if ((i + 1) % _numElementsPerRow == 0)
					{
						currentY += rowHeight + _rowsGap;
						
						if ((i + 1) == _firstVisibleIndex)
						{
							for (j = 0; j < numVisibleItems; j++) 
							{
								//_itemsContainer.getChildAt(j).y -= currentY;
								_helperCache[j + "y"] -= currentY;
								
								child = _itemsContainer.getChildAt(j);
								
								if (child.x != _helperCache[j + "x"] || child.y != _helperCache[j + "y"])
								{
									child.moveTo(
										_helperCache[j + "x"],
										_helperCache[j + "y"]
									);
								}
							}
							
							if (_previousRowPosition == 0)
							{
								_previousRowPosition = (itemRenderer as Sprite3D).y;
							}
							
							currentY = 0;
							_itemsContainerSize = 0;
						}
						
						if (breakOnNextLine)
						{
							break;
						}
						
						
						if ((i + 1) > _firstVisibleIndex)
						{
							_itemsContainerSize += rowHeight + _rowsGap;
						}
						
						rowHeight = 0;
						
						currentX = 0;
						
						if (_secondRowPosition == 0 && currentY > 0)
						{
							_secondRowPosition = currentY;
						}
						
						if (currentY > _viewPort.height + _viewPort.y)
						{
							breakOnNextLine = true;
						}
					}
					else
					{
						if (i == _dataSource.length - 1)
						{
							_itemsContainerSize += rowHeight;
						}
						currentX += (itemRenderer as Sprite3D).width + _columnsGap;
					}
				}
				else
				{
					rowWidth = Math.max((itemRenderer as Sprite3D).width, rowWidth);
					
					if ((i + 1) % _numElementsPerRow == 0)
					{
						currentX += rowWidth + _columnsGap;
						
						if ((i + 1) == _firstVisibleIndex)
						{
							for (j = 0; j < numVisibleItems; j++) 
							{
								//_itemsContainer.getChildAt(j).x -= currentX;
								_helperCache[j + "x"] -= currentX;
								
								child = _itemsContainer.getChildAt(j);
								
								if (child.x != _helperCache[j + "x"] || child.y != _helperCache[j + "y"])
								{
									child.moveTo(
										_helperCache[j + "x"],
										_helperCache[j + "y"]
									);
								}
							}
							
							if (_previousRowPosition == 0)
							{
								_previousRowPosition = (itemRenderer as Sprite3D).x;
							}
							
							currentX = 0;
							_itemsContainerSize = 0;
						}
						
						if (breakOnNextLine)
						{
							break;
						}
						
						if ((i + 1) > _firstVisibleIndex)
						{
							_itemsContainerSize += rowWidth + _columnsGap;
						}
						
						rowWidth = 0;
						
						currentY = 0;
						
						if (_secondRowPosition == 0 && currentX > 0)
						{
							_secondRowPosition = currentX;
						}
						
						if (currentX > _viewPort.width + _viewPort.x)
						{
							breakOnNextLine = true;
						}
					}
					else
					{
						if (i == _dataSource.length - 1)
						{
							_itemsContainerSize += rowWidth;
						}
						
						currentY += (itemRenderer as Sprite3D).height + _rowsGap;
					}
				}
			}
			
			while (_itemsContainer.numChildren > numVisibleItems)
			{
				freeItemRenderer(_itemsContainer.removeChildAt(_itemsContainer.numChildren - 1) as IEasyItemRenderer);
			}
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
	}
}