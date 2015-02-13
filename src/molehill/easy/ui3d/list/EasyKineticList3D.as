package molehill.easy.ui3d.list
{
	import easy.collections.ISimpleCollection;
	import easy.collections.events.CollectionEvent;
	import easy.core.Direction;
	import easy.core.IFactory;
	import easy.core.events.ListEvent;
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
	import molehill.easy.ui3d.scroll.KineticScrollContainer3D;
	
	import org.goasap.PlayStates;
	import org.goasap.managers.LinearGoRepeater;
	import org.opentween.OpenTween;

	public class EasyKineticList3D extends KineticScrollContainer3D
	{
		public function EasyKineticList3D()
		{
			super();
		}
		
		private var _delayedUpdate:Boolean = false;
		override protected function onAddedToScene():void
		{
			super.onAddedToScene();
			
			if (_stage != null)
			{
				if (_mouseWheelEnabled)
				{
					_stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
				else
				{
					_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
			}
			
			if (_delayedUpdate)
			{
				_delayedUpdate = false;
				update();
			}
		}
		
		override protected function onRemovedFromScene():void
		{
			if (_stage != null)
			{
				_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			}
			
			super.onRemovedFromScene();
		}
		
		private function onMouseWheel(event:MouseEvent):void
		{
			if (_animation != null && _animation.state != PlayStates.STOPPED)
			{
				return;
			}
			
			if (event.delta > 0 && canScrollToStart)
			{
				if (scrollOn(
						_direction == Direction.HORIZONTAL ? 0 : MOUSE_WHEEL_STEP,
						_direction == Direction.HORIZONTAL ? MOUSE_WHEEL_STEP : 0
					))
				{
					completeScrolling();
				}
			}
			
			if (event.delta < 0 && canScrollToEnd)
			{
				if (scrollOn(
						_direction == Direction.HORIZONTAL ? 0 : -MOUSE_WHEEL_STEP,
						_direction == Direction.HORIZONTAL ? -MOUSE_WHEEL_STEP : 0
					))
				{
					completeScrolling();
				}
			}
		}
		
		override protected function onScrollStarted():void
		{
			for (var i:int = 0; i < _container.numChildren; i++) 
			{
				var item:ILockableEasyItemRenderer = _container.getChildAt(i) as ILockableEasyItemRenderer;
				
				if (item != null)
				{
					item.locked = true;
				}
			}
		}
		
		override protected function onScrollCompleted():void
		{
			for (var i:int = 0; i < _container.numChildren; i++) 
			{
				var item:ILockableEasyItemRenderer = _container.getChildAt(i) as ILockableEasyItemRenderer;
				
				if (item != null)
				{
					item.locked = false;
				}
			}
		}
		
		private var _useCustomViewPort:Boolean = false;
		override public function set viewPort(value:Rectangle):void
		{
			super.viewPort = value;
			_useCustomViewPort = true;
		}
		
		private function updateAutoViewPort():void
		{
			if (_useCustomViewPort ||
				_rowHeight == 0 || 
				_columnWidth == 0)
			{
				return;
			}
			
			_viewPort.x = 0;
			_viewPort.y = 0;
			_viewPort.width = _direction == Direction.HORIZONTAL ?
				_numItemsPerLine * (_columnWidth + _columnsGap) - _columnsGap :
				_numLinesPerPage * (_columnWidth + _columnsGap) - _columnsGap;
			
			_viewPort.height = _direction == Direction.HORIZONTAL ?
				_numLinesPerPage * (_rowHeight + _rowsGap) - _rowsGap :
				_numItemsPerLine * (_rowHeight + _rowsGap) - _rowsGap;
			
			super.viewPort = _viewPort;
		}
		
		//==================
		// list settings
		//==================
		
		public var LINE_ANIMATION_DURATION:Number = 0.1;
		public var PAGE_ANIMATION_DURATION:Number = 0.1;
		
		private var MOUSE_WHEEL_STEP:Number = 30;
		
		
		private var _updateCallback:Function;
		public function set updateCallback(value:Function):void
		{
			_updateCallback = value;
		}
		
		
		private var _mouseWheelEnabled:Boolean = false;
		
		/** enable/disable mouse wheel scrolling */
		public function set mouseWheelEnabled(value:Boolean):void
		{
			_mouseWheelEnabled = value;
			
			if (_stage != null)
			{
				if (_mouseWheelEnabled)
				{
					_stage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
				else
				{
					_stage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
				}
			}
		}
		
		
		private var _mouseScrollingEnabled:Boolean = true;
		
		/** enable/disable mouse scrolling */
		public function set mouseScrollingEnabled(value:Boolean):void
		{
			_mouseScrollingEnabled = value;
		}
		
		
		public function set backgroundMouseEnabled(value:Boolean):void
		{
			_scrollingMask.mouseEnabled = value;
			_scrollingMask.mouseTransparent = !value;
			if (value)
			{
				_scrollingMask.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			}
			else
			{
				_scrollingMask.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			}
		}
		
		
		private var _snapToEnd:Boolean = false;
		
		/** 
		 * Set to true to snap end of list to the bottom of view port
		 * Disabled by default. 
		 */
		public function set snapToEnd(value:Boolean):void
		{
			_snapToEnd = value;
		}
		
		
		private var _mouseScrollShortListLock:Boolean = false;
		
		/** set to true to disable mouse scrolling, when numItems < numItemsPerPage */
		public function set lockMouseScrollShortList(value:Boolean):void
		{
			_mouseScrollShortListLock = value;
		}
		
		
		private var _snapToClosestItem:Boolean = false;
		
		/** 
		 * Enables snapping to closest item in the end of kinetic or mouse scroll.
		 * Disabled by default.
		 */
		public function set snapToClosestItem(value:Boolean):void
		{
			_snapToClosestItem = value;
		}
		
		
		private var _lockAnimation:Boolean = false;
		/** 
		 * lock paging and item scrolling animation 
		 */ 
		public function set lockAnimation(value:Boolean):void
		{
			_lockAnimation = value;
		}
		
		
		private var _numAdditionalLinesBefore:uint = 0;
		/** 
		 * Set num additional drawn lines before current item 
		 */
		public function set numAdditionalLinesBefore(value:uint):void
		{
			_numAdditionalLinesBefore = value;
		}
		
		private var _showEmptyCells:Boolean = false;
		public function get showEmptyCells():Boolean
		{
			return _showEmptyCells;
		}
		/**
		 * Enable or disable adding emty item renderers to fill the last line
		 * Required emptyItemRendererFactory to be set
		 */
		public function set showEmptyCells(value:Boolean):void
		{
			if (_emptyItemRendererFactory == null)
			{
				return;
			}
			
			_showEmptyCells = value;
			
			if (!_showEmptyCells)
			{
				freeAllEmptyItemRenderers();
			}
		}
		
		
		override protected function onItemsContainerMouseDown(event:Input3DMouseEvent):void
		{
			if (!_mouseScrollingEnabled || _dataSource == null)
			{
				return;
			}
			
			if (_mouseScrollShortListLock)
			{
				if (_dataSource.length <= _numItemsPerLine * _numLinesPerPage)
				{
					return;
				}
			}
			
			super.onItemsContainerMouseDown(event);
		}
		
		//==================
		// paging
		//==================
		
		override protected function stopAnimation():void
		{
			super.stopAnimation();
			if (_stage != null)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onScrollingEnterFrame);
			}
		}
		
		private var _numLinesPerPage:uint = 1;
		public function get numLinesPerPage():uint
		{
			return _numLinesPerPage;
		}

		public function set numLinesPerPage(value:uint):void
		{
			_numLinesPerPage = value;
			
			updateAutoViewPort();
		}
		
		public function get canScrollToStart():Boolean
		{
			if (_firstVisibleIndex > 0)
			{
				return true;
			}
			
			return _direction == Direction.HORIZONTAL ? _containerCamera.scrollY > topBorder : _containerCamera.scrollX > leftBorder;
		}
		
		public function get canScrollToEnd():Boolean
		{
			if (_snapToEnd)
			{
				if (_lastVisibleIndex < _dataSource.length - 1)
				{
					return true;
				}
			}
			else
			{
				if (_firstVisibleIndex < currentItemMax)
				{
					return true
				}
			}
			
			return _direction == Direction.HORIZONTAL ? _containerCamera.scrollY < bottomBorder : _containerCamera.scrollX < rightBorder;
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
			
			itemIndex = Math.min(itemIndex, _dataSource.length - 1);
			var targetIndex:uint = Math.floor(itemIndex / _numItemsPerLine) * _numItemsPerLine;
			
			scrollToIndex(targetIndex, !_lockAnimation);
		}
		
		public function get currentItemMax():uint
		{
			if (_dataSource == null || _dataSource.length == 0)
			{
				return 0;
			}
			
			var index:int;
			
			var numItemsPerPage:uint = _numItemsPerLine * _numLinesPerPage;
			
			if (_snapToEnd)
			{
				index = (_dataSource.length + _dataSource.length % _numItemsPerLine) - numItemsPerPage;
			}
			else
			{
				index = Math.floor((_dataSource.length - 1) / numItemsPerPage) * numItemsPerPage;
			}
			
			return index;
		}
		
		public function get currentPage():int
		{
			return Math.floor(_firstVisibleIndex / _numItemsPerLine / _numLinesPerPage);
		}
		
		public function set currentPage(value:int):void
		{
			value = Math.max(0, value);
			
			var targetIndex:uint = Math.min(value * _numItemsPerLine * _numLinesPerPage, currentItemMax);
			
			scrollToIndex(targetIndex, !_lockAnimation);
		}
		
		private function scrollToIndex(index:int, animate:Boolean = true):void
		{
			if (index == _firstVisibleIndex)
			{
				if (_containerCamera.scrollX != leftBorder || _containerCamera.scrollY != topBorder)
				{
					_animation = OpenTween.go(
						_containerCamera,
						{
							scrollX : leftBorder,
							scrollY : topBorder
						},
						LINE_ANIMATION_DURATION,
						0,
						Linear.easeNone,
						_updateCallback
					);
				}
				
				return;
			}
			
			stopAnimation();
			
			index = Math.max(0, index);
			index = Math.min(index, _dataSource.length - 1)
			
			stopScrolling();
			
			if (animate && _stage != null)
			{
				var numLinesToScroll:int = Math.floor((index - _firstVisibleIndex) / _numItemsPerLine);
				
				var numPagesToScroll:Number = Math.floor(Math.abs(numLinesToScroll) / _numLinesPerPage);
				
				var duration:Number = numPagesToScroll == 0 ? LINE_ANIMATION_DURATION : PAGE_ANIMATION_DURATION / numPagesToScroll;
				
				if (Math.abs(numLinesToScroll) > 3)
				{
					_numLinesToScroll = Math.abs(numLinesToScroll);
					_scrollForward = numLinesToScroll > 0;
					_stage.addEventListener(Event.ENTER_FRAME, onScrollingEnterFrame);
					onScrollingEnterFrame(null);
				}
				else
				{
					scrollNextLine(Math.abs(numLinesToScroll), duration, numLinesToScroll > 0);
				}
			}
			else
			{
				_firstVisibleIndex = index;
				updateItems();
				
				var scrolledBack:Boolean = false;
				
				while (_lastVisibleIndex == _dataSource.length - 1 && _firstVisibleIndex > 0)
				{
					_firstVisibleIndex -= _numItemsPerLine;
					updateItems();
					
					scrolledBack = true;
				}
				
				_containerCamera.scrollX = leftBorder;
				_containerCamera.scrollY = topBorder;
				
				if (scrolledBack)
				{
					_firstVisibleIndex += _numItemsPerLine;
					updateItems();
					
					completeScrolling(false);
				}
				else
				{
					completeScrolling(false);
				}
			}
		}
		
		private var _numLinesToScroll:int;
		private var _scrollForward:Boolean;
		protected function onScrollingEnterFrame(event:Event):void
		{
			if (_numLinesToScroll < 1 || _stage == null)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onScrollingEnterFrame);
				completeScrolling();
				return;
			}
			
			_numLinesToScroll--;
			
			var nextPosition:Number = _scrollForward ? 
				_secondLinePosition : 
				(_previousLinePosition == 0 ? -ELASCTIC_SIZE : _previousLinePosition);
			
			_containerCamera.scrollX = _direction == Direction.VERTICAL ? nextPosition : 0;
			_containerCamera.scrollY =  _direction == Direction.VERTICAL ? 0 : nextPosition;
			
			validateBorders();
		}		
		
		private function scrollNextLine(numLinesToScroll:int, duration:Number, forward:Boolean):void
		{
			if (numLinesToScroll < 0)
			{
				return;
			}
			
			numLinesToScroll--;
			
			var nextPosition:Number = forward ? 
				_secondLinePosition : 
				(_previousLinePosition == 0 ? -ELASCTIC_SIZE : _previousLinePosition);
			
			_animation = OpenTween.go(
				_containerCamera,
				{
					scrollX : _direction == Direction.VERTICAL ? nextPosition : 0,
					scrollY : _direction == Direction.VERTICAL ? 0 : nextPosition
				},
				duration,
				0,
				Linear.easeNone,
				numLinesToScroll <= 0 ? completeScrolling : scrollNextLine,
				validateBorders,
				numLinesToScroll <= 0 ? null : [numLinesToScroll, duration, forward]
			);
		}
		
		
		public function nextLine():void
		{
			if (!canScrollToEnd)
			{
				return;
			}
			
			stopAnimation();
			
			scrollToIndex(_firstVisibleIndex + _numItemsPerLine, !_lockAnimation);
		}
		
		public function previousLine():void
		{
			if (!canScrollToStart)
			{
				return;
			}
			
			stopAnimation();
			
			scrollToIndex(_firstVisibleIndex - _numItemsPerLine, !_lockAnimation);
		}
		
		public function get numItems():uint
		{
			if (_dataSource == null)
			{
				return 0;
			}
			
			return _dataSource.length;
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
			
			updateAutoViewPort();
		}
		
		
		protected var _columnsGap:int;
		public function get columnsGap():int
		{
			return _columnsGap;
		}
		public function set columnsGap(value:int):void
		{
			_columnsGap = value;
			
			updateAutoViewPort();
		}
		
		protected var _rowHeight:int;
		public function get rowHeight():int
		{
			return _rowHeight;
		}
		
		/**
		 * Use for autoSized viewPort
		 */
		public function set rowHeight(value:int):void
		{
			_rowHeight = value;
			
			updateAutoViewPort();
		}
		
		
		protected var _columnWidth:int;
		public function get columnWidth():int
		{
			return _columnWidth;
		}
		/**
		 * Use for autoSized viewPort
		 */
		public function set columnWidth(value:int):void
		{
			_columnWidth = value;
			
			updateAutoViewPort();
		}
		
		
		private var _numItemsPerLine:int = 1;
		public function get numItemsPerLine():int
		{
			return _numItemsPerLine;
		}
		
		public function set numItemsPerLine(value:int):void
		{
			if (value < 1)
			{
				return;
			}
			
			_numItemsPerLine = value;
			
			updateAutoViewPort();
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
			
			updateAutoViewPort();
			
			update();
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
			stopScrolling();
			stopAnimation();
			update();
		}
		
		protected function updateOnDataSourceChange():void
		{
			stopScrolling();
			stopAnimation();
			
			_container.camera.scrollX = 0;
			_container.camera.scrollY = 0;
			
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
		
		private var _listFreeEmptyItemRenderers:Array = new Array();
		private var _listAddedEmptyItemRenderers:Array = new Array();
		private function getEmptyItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:IEasyItemRenderer;
			
			while ( _listFreeEmptyItemRenderers.length > 0)
			{
				itemRenderer = _listFreeEmptyItemRenderers.pop() as IEasyItemRenderer;
			}
			
			if (itemRenderer == null)
			{
				itemRenderer = _emptyItemRendererFactory.newInstance() as IEasyItemRenderer;
			}
			
			return itemRenderer;
		}
		
		private function freeAllEmptyItemRenderers():void
		{
			if (_listAddedEmptyItemRenderers.length == 0)
			{
				return;
			}
			
			var itemRenderer:IEasyItemRenderer;
			
			for (var i:int = 0; i < _listAddedEmptyItemRenderers.length; i++) 
			{
				itemRenderer = _listAddedEmptyItemRenderers[i];
				
				var displayObject:Sprite3D = itemRenderer as Sprite3D;
				if ( displayObject != null && displayObject.parent != null )
				{
					displayObject.parent.removeChild(displayObject);
				}
				
				_listFreeEmptyItemRenderers.push(
					itemRenderer
				);	
			}
			
			_listAddedEmptyItemRenderers = new Array();
		}
		
		private function createItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:Sprite3D = _itemRendererFactory.newInstance() as Sprite3D;
			
			itemRenderer.addEventListener(Input3DMouseEvent.CLICK, onItemRendererClick);
			itemRenderer.addEventListener(Input3DMouseEvent.MOUSE_OVER, onItemRendererRollOver);
			itemRenderer.addEventListener(Input3DMouseEvent.MOUSE_OUT, onItemRendererRollOut);
			
			return itemRenderer as IEasyItemRenderer;
		}
		
		private var _listFreeItemRenderers:Array = new Array();
		private function getItemRenderer():IEasyItemRenderer
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
			
			return itemRenderer;
		}
		
		private function freeItemRenderer(itemRenderer:IEasyItemRenderer):void
		{
			if (itemRenderer == null)
			{
				return;
			}
			
			itemRenderer.itemData = null;
			itemRenderer.selected = false;
			itemRenderer.highlighted = false;
			
			(itemRenderer as Sprite3D).removeEventListener(Input3DMouseEvent.CLICK, onItemRendererClick);
			(itemRenderer as Sprite3D).removeEventListener(Input3DMouseEvent.MOUSE_OVER, onItemRendererRollOver);
			(itemRenderer as Sprite3D).removeEventListener(Input3DMouseEvent.MOUSE_OUT, onItemRendererRollOut);
			
			var displayObject:Sprite3D = itemRenderer as Sprite3D;
			if ( displayObject != null && displayObject.parent != null )
			{
				displayObject.parent.removeChild(displayObject);
			}
			
			_listFreeItemRenderers.push(
				itemRenderer
			);
		}
		
		public function getItemRendererByIndex(index:int):IEasyItemRenderer
		{
			var childIndex:int = index + (_firstVisibleIndex - dataBeginIndex);
			if (childIndex >= _container.numChildren)
			{
				return null;
			}
			
			return _container.getChildAt(childIndex) as IEasyItemRenderer;
		}
		
		private var _itemClickEnabled:Boolean = false;
		public function get itemClickEnabled():Boolean
		{
			return _itemClickEnabled;
		}
		public function set itemClickEnabled(value:Boolean):void
		{
			_itemClickEnabled = value;
		}
		
		
		/*** --------------------------------------------------------- ***/
		/***                         Selection                         ***/
		/*** --------------------------------------------------------- ***/
		private var _allowSelection:Boolean = false;
		private var _allowMultipleSelection:Boolean = false;
		
		private var _selectedItem:*;
		
		private var _dictSelectedItems:Array;
		
		public function get allowMultipleSelection():Boolean
		{
			return _allowMultipleSelection;
		}
		public function set allowMultipleSelection(value:Boolean):void
		{
			_allowMultipleSelection = value;
			
			if (_allowMultipleSelection && _dictSelectedItems == null)
				_dictSelectedItems = new Array();
		}
		
		private var _allowHighlight:Boolean = false;
		public function get allowHighlight():Boolean
		{
			return _allowHighlight;
		}
		public function set allowHighlight(value:Boolean):void
		{
			_allowHighlight = value;
		}
		
		private var _numMaxSelectedItems:int = int.MAX_VALUE;
		public function get numMaxSelectedItems():int
		{
			return _numMaxSelectedItems;
		}
		
		public function set numMaxSelectedItems(value:int):void
		{
			_numMaxSelectedItems = value;
		}
		
		public function get numSelectedItems():int
		{
			return _dictSelectedItems.length;
		}
		
		public function get allowSelection():Boolean
		{
			return _allowSelection;
		}
		public function set allowSelection(value:Boolean):void
		{
			_allowSelection = value;
		}
		
		public function get selectedItem():*
		{
			return _selectedItem;
		}
		public function set selectedItem(value:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				_dictSelectedItems = new Array();
				_dictSelectedItems.push(_selectedItem);
			}
			else
			{
				_selectedItem = value;
				//_selectedIndex = -1;// вычислить на get-ере
			}
			update();
			
		}
		
		public function get selectedItems():Array
		{
			var items:Array;
			if (_allowMultipleSelection)
			{
				items = _dictSelectedItems.concat();
			}
			else
			{
				items = _selectedItem != null ? [_selectedItem] : [];
			}
			
			return items;
		}
		public function set selectedItems(value:Array):void
		{
			setSelectedItems(value);
		}	
		
		/**
		 * value:Array or value:Collection
		 */
		protected function setSelectedItems(value:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				_dictSelectedItems = new Array();
				
				if (value != null && value.length > 0)
				{
					_selectedItem = value[0];
					for each(var element:* in value)
					{
						if (_dictSelectedItems.indexOf(element) == -1)
						{
							_dictSelectedItems.push(element);
						}
						
						if (_dictSelectedItems.length >= _numMaxSelectedItems)
						{
							break;
						}
					}
				}
				
				//_selectedIndex = -1;// вычислиться на get-ере
			}
			else
			{
				if (value != null && value.length > 0)
				{
					_selectedItem = value[0];
					//_selectedIndex = -1;// вычислиться на get-ере
				}
				else
				{
					_selectedItem = null;
					//_selectedIndex = -1;
				}
			}
			update();
			
		}
		
		public function selectAll():void
		{
			setSelectedItems(_dataSource);
		}
		
		public function unselectAll():void
		{
			selectedItems = null;
		}
		
		public function selectItem(itemData:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				if (numSelectedItems >= _numMaxSelectedItems) 
				{
					return;
				}
				
				if (_dictSelectedItems.indexOf(itemData) == -1)
				{
					_dictSelectedItems.push(itemData);
				}
				
				if (_selectedItem == null)
					_selectedItem = itemData;
				//_selectedIndex =
				// индекс искать не надо, при необходимости вычислиться на get-ере
			}
			else
			{
				_selectedItem = itemData;
				//_selectedIndex = -1;
			}
		}
		//---
		protected function unselectItem(itemData:*):void
		{
			if (_allowMultipleSelection)
			{
				var index:int = _dictSelectedItems.indexOf(itemData);
				if (index != -1)
				{
					_dictSelectedItems.splice(index, 1);
				}
			}
			else
			{
				if (_selectedItem == itemData)
				{
					_selectedItem = null;
					//_selectedIndex = -1;
				}
			}
		}
		
		protected function isItemSelected(itemData:*):Boolean
		{
			if(!_allowSelection)
			{
				return false;
			}
			var itemSelected:Boolean = false;
			if (_allowMultipleSelection)
			{
				itemSelected = _dictSelectedItems.indexOf(itemData) != -1;
			}
			else
			{
				itemSelected = _selectedItem === itemData;
			}
			
			return itemSelected;
		}
		
		
		/*** --------------------------------------------------------- ***/
		/***                           Mouse                           ***/
		/*** --------------------------------------------------------- ***/
		private function onItemRendererClick(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			var itemData:* = itemRenderer.itemData;
			
			if (_itemClickEnabled)
			{
				dispatchEvent(
					new ListEvent(ListEvent.ITEM_CLICK, itemData)
				); 
			}
			
			if (!_allowSelection || !itemRenderer.isSelectable)
				return;
			
			if (itemData == null)
				return;
			
			if (_allowMultipleSelection)
			{
				if ( isItemSelected(itemData) )
				{
					unselectItem(itemData);
				}
				else if (numSelectedItems < numMaxSelectedItems)
				{
					selectItem(itemData);
				}
			}
			else
			{
				selectItem(itemData);
			}
			
			update();
		}
		//---
		private function onItemRendererRollOver(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			if(allowHighlight)
			{
				itemRenderer.highlighted = true;
				itemRenderer.update();
			}
		}
		//---
		private function onItemRendererRollOut(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			if(allowHighlight)
			{
				itemRenderer.highlighted = false;
				itemRenderer.update();
			}
		}		
		//---------------------------------------------------------------------------------------
		
		
		//==================
		// scroll limits
		//==================
		private var _firstVisibleIndex:uint = 0;
		private var _lastVisibleIndex:uint = 0;
		
		private var _previousLinePosition:Number = 0;
		private var _secondLinePosition:Number = 0;
		private var _itemsContainerSize:Number = 0;

		
		override protected function validateBorders(scrollingCompleted:Boolean=false):Boolean
		{
			var result:Boolean = super.validateBorders(scrollingCompleted);
			
			if (scrollingCompleted && (!canScrollToEnd || !canScrollToStart))
			{
				if (_updateCallback != null)
				{
					_updateCallback();
				}
			}
			
			return result;
		}
		
		override protected function validateBottomBorder():Boolean
		{
			if (_direction == Direction.VERTICAL)
			{
				return false;
			}
			
			if (_snapToEnd)
			{
				if (_lastVisibleIndex < (_dataSource.length - 1))
				{
					while (_containerCamera.scrollY >= _secondLinePosition && _lastVisibleIndex < (_dataSource.length - 1))
					{
						_containerCamera.scrollY -= _secondLinePosition;
						_firstVisibleIndex += _numItemsPerLine;
						updateItems();
					}
				}
				
				if (_lastVisibleIndex == _dataSource.length - 1)
				{
					if (_containerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
					{
						_containerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
						return true;
					}
				}
			}
			else
			{
				while (_containerCamera.scrollY >= _secondLinePosition && _firstVisibleIndex < currentItemMax)
				{
					_containerCamera.scrollY -= _secondLinePosition;
					_firstVisibleIndex += _numItemsPerLine;
					updateItems();
				}
				
				if (_firstVisibleIndex == currentItemMax)
				{
					if (_containerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
					{
						_containerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
						return true;
					}
				}
			}
			
			return false;
		}
		
		override protected function get bottomBorder():Number
		{
			if (_container.numChildren > 0 && _itemsContainerSize > _viewPort.height)
			{
				return _itemsContainerSize - _viewPort.height - _viewPort.y + bottomGap;
			}
			else
			{
				return 0;
			}
		}
		
		override protected function validateTopBorder():Boolean
		{
			if (_direction == Direction.VERTICAL)
			{
				return false;
			}
			
			if (_firstVisibleIndex != 0)
			{
				while (_containerCamera.scrollY <= _previousLinePosition && _firstVisibleIndex != 0)
				{
					_containerCamera.scrollY -= _previousLinePosition;
					_firstVisibleIndex = Math.max(0, _firstVisibleIndex - _numItemsPerLine);
					updateItems();
				}
			}
			
			if (_firstVisibleIndex == 0)
			{
				if (_containerCamera.scrollY < topBorder - ELASCTIC_SIZE)
				{
					_containerCamera.scrollY = topBorder - ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		
		override protected function validateRightBorder():Boolean
		{
			if (_direction == Direction.HORIZONTAL)
			{
				return false;
			}
			
			if (_snapToEnd)
			{
				if (_lastVisibleIndex < (_dataSource.length - 1))
				{
					while (_containerCamera.scrollX >= _secondLinePosition && _lastVisibleIndex < (_dataSource.length - 1))
					{
						_containerCamera.scrollX -= _secondLinePosition;
						_firstVisibleIndex += _numItemsPerLine;
						updateItems();
					}
				}
				
				if (_lastVisibleIndex == _dataSource.length - 1)
				{
					if (_containerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
					{
						_containerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
						return true;
					}
				}
			}
			else
			{
				while (_containerCamera.scrollX >= _secondLinePosition && _firstVisibleIndex < currentItemMax)
				{
					_containerCamera.scrollX -= _secondLinePosition;
					_firstVisibleIndex += _numItemsPerLine;
					updateItems();
				}
				
				if (_firstVisibleIndex == currentItemMax)
				{
					if (_containerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
					{
						_containerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
						return true;
					}
				}
			}
			
			return false;
		}
		
		override protected function get rightBorder():Number
		{
			if (_container.numChildren > 0 && _itemsContainerSize > _viewPort.width)
			{
				return _itemsContainerSize - _viewPort.width - _viewPort.x + rightGap;
			}
			else
			{
				return 0;
			}
		}
		
		override protected function validateLeftBorder():Boolean
		{
			if (_direction == Direction.HORIZONTAL)
			{
				return false;
			}
			
			if (_firstVisibleIndex != 0)
			{
				while (_containerCamera.scrollX <= _previousLinePosition && _firstVisibleIndex != 0)
				{
					_containerCamera.scrollX -= _previousLinePosition;
					_firstVisibleIndex = Math.max(0, _firstVisibleIndex - _numItemsPerLine);
					updateItems();
				}
			}
			
			if (_firstVisibleIndex == 0)
			{
				if (_containerCamera.scrollX < leftBorder - ELASCTIC_SIZE)
				{
					_containerCamera.scrollX = leftBorder - ELASCTIC_SIZE;
					return true;
				}
			}
			
			return false;
		}
		
		override protected function get itemsContainerWidth():Number
		{
			return _itemsContainerSize;
		}
		
		override protected function get itemsContainerHeight():Number
		{
			return _itemsContainerSize;
		}
		
		override protected function checkCompleteScrollingPosition(targetPoint:Point):Boolean
		{
			var borderReached:Boolean = false;
			
			if (_direction == Direction.VERTICAL)
			{
				if (itemsContainerWidth <= (_scrollingMask.width + _scrollingMask.x) ||
					(_containerCamera.scrollX < leftBorder && _firstVisibleIndex == 0)
				)
				{
					targetPoint.x = leftBorder;
					borderReached = true;
				}
				else if (_containerCamera.scrollX > rightBorder && _lastVisibleIndex == (_dataSource.length - 1))
				{
					targetPoint.x = rightBorder;
					borderReached = true;
				}
			}
			else
			{
				if (itemsContainerHeight <= (_scrollingMask.height + _scrollingMask.y) ||
					(_containerCamera.scrollY < topBorder && _firstVisibleIndex == 0)
				)
				{
					targetPoint.y = topBorder;
					borderReached = true;
				}
				else if (_containerCamera.scrollY > bottomBorder && _lastVisibleIndex == (_dataSource.length - 1))
				{
					targetPoint.y = bottomBorder;
					borderReached = true;
				}
			}
			
			if (!borderReached && _snapToClosestItem)
			{
				var cameraScrollPosition:Number = _direction == Direction.HORIZONTAL ? _containerCamera.scrollY : _containerCamera.scrollX;
				var gap:Number = _direction == Direction.HORIZONTAL ? _rowsGap : _columnsGap;
				
				if (cameraScrollPosition < (_previousLinePosition + gap) / 2)
				{
					if (_direction == Direction.HORIZONTAL)
					{
						targetPoint.y = _previousLinePosition;
					}
					else
					{
						targetPoint.x = _previousLinePosition;
					}
					
					borderReached = true;
				}
				else if (cameraScrollPosition > (_secondLinePosition - gap) / 2)
				{
					if (_direction == Direction.HORIZONTAL)
					{
						targetPoint.y = _secondLinePosition;
					}
					else
					{
						targetPoint.x = _secondLinePosition;
					}
					
					borderReached = true;
				}
				else
				{
					if (_direction == Direction.HORIZONTAL)
					{
						targetPoint.y = topBorder;
					}
					else
					{
						targetPoint.x = leftBorder;
					}
					
					borderReached = true;
				}
			}
			
			return borderReached;
		}
		
		
		//==================
		// update everything
		//==================
		
		public function update():void
		{
			if (_dataSource == null)
			{
				return;
			}
			
			if (scene == null || !scene.isActive)
			{
				_delayedUpdate = true;
				return;
			}	
			
			_firstVisibleIndex = Math.min(currentItemMax, _firstVisibleIndex);
			
			updateItems();
			
			validateBorders();
			completeScrolling(false);
			
			if (_mouseScrollShortListLock)
			{
				if (_dataSource.length <= _numItemsPerLine * _numLinesPerPage)
				{
					_containerCamera.scrollX = leftBorder;
					_containerCamera.scrollY = topBorder;
				}
			}
		}
		
		private function get dataBeginIndex():int
		{
			return Math.max(_firstVisibleIndex - (_numAdditionalLinesBefore + 1) * numItemsPerLine, 0);
		}
		
		private var _helperCache:Object = new Object();
		private function updateItems():void
		{
			if (dataSource == null)
			{
				while (_container.numChildren > 0)
				{
					_container.removeChildAt(0);
				}
				return;
			}
			
			if (_showEmptyCells)
			{
				freeAllEmptyItemRenderers();
			}
			
			_previousLinePosition = 0;
			_secondLinePosition = 0;
			
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
			
			var dataBeginIdx:int = dataBeginIndex;
			
			var lastAddedIndex:uint = 0;
			
			for (var i:int = dataBeginIdx; i < dataSource.length; i++) 
			{
				if (!breakOnNextLine)
				{
					_lastVisibleIndex = i;
				}
				
				lastAddedIndex = i;
				
				if (_container.numChildren > i - dataBeginIdx)
				{
					itemRenderer = _container.getChildAt(i - dataBeginIdx) as IEasyItemRenderer;
				}
				else
				{
					itemRenderer = getItemRenderer();
					_container.addChild(itemRenderer as Sprite3D);
				}
				
				itemRenderer.itemData = dataSource[i];
				itemRenderer.selected = isItemSelected(dataSource[i]);
				itemRenderer.update();
				
				if (i < _firstVisibleIndex)
				{
					_helperCache[(i - dataBeginIdx) + "x"] = currentX;
					_helperCache[(i - dataBeginIdx) + "y"] = currentY;
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
					
					if ((i + 1) % _numItemsPerLine == 0)
					{
						currentY += rowHeight + _rowsGap;
						
						if ((i + 1) == _firstVisibleIndex)
						{
							for (j = 0; j < numVisibleItems; j++) 
							{
								//_itemsContainer.getChildAt(j).y -= currentY;
								_helperCache[j + "y"] -= currentY;
								
								child = _container.getChildAt(j);
								
								if (child.x != _helperCache[j + "x"] || child.y != _helperCache[j + "y"])
								{
									child.moveTo(
										_helperCache[j + "x"],
										_helperCache[j + "y"]
									);
								}
							}
							
							if (_previousLinePosition == 0)
							{
								_previousLinePosition = (itemRenderer as Sprite3D).y;
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
							if (i == _dataSource.length - 1)
							{
								_itemsContainerSize += rowHeight;
							}
							else
							{
								_itemsContainerSize += rowHeight + _rowsGap;
							}
						}
						
						rowHeight = 0;
						
						currentX = 0;
						
						if (i >= _firstVisibleIndex)
						{
							if (_secondLinePosition == 0 && currentY > 0)
							{
								_secondLinePosition = currentY;
							}
							
							if (currentY > _viewPort.height + _viewPort.y)
							{
								breakOnNextLine = true;
							}
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
					
					if ((i + 1) % _numItemsPerLine == 0)
					{
						currentX += rowWidth + _columnsGap;
						
						if ((i + 1) == _firstVisibleIndex)
						{
							for (j = 0; j < numVisibleItems; j++) 
							{
								//_itemsContainer.getChildAt(j).x -= currentX;
								_helperCache[j + "x"] -= currentX;
								
								child = _container.getChildAt(j);
								
								if (child.x != _helperCache[j + "x"] || child.y != _helperCache[j + "y"])
								{
									child.moveTo(
										_helperCache[j + "x"],
										_helperCache[j + "y"]
									);
								}
							}
							
							if (_previousLinePosition == 0)
							{
								_previousLinePosition = (itemRenderer as Sprite3D).x;
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
							if (i == _dataSource.length - 1)
							{
								_itemsContainerSize += rowWidth;
							}
							else
							{
								_itemsContainerSize += rowWidth + _columnsGap;
							}
						}
						
						rowWidth = 0;
						
						currentY = 0;
						
						if (i >= _firstVisibleIndex)
						{
							if (_secondLinePosition == 0 && currentX > 0)
							{
								_secondLinePosition = currentX;
							}
							
							if (currentX > _viewPort.width + _viewPort.x)
							{
								breakOnNextLine = true;
							}
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
			
			while (_container.numChildren > numVisibleItems)
			{
				freeItemRenderer(_container.removeChildAt(_container.numChildren - 1) as IEasyItemRenderer);
			}
			
			if (_showEmptyCells)
			{
				var numEmptyRenderers:uint = (lastAddedIndex + 1) % _numItemsPerLine;
				
				if (numEmptyRenderers > 0)
				{
					for (i = 0; i < numEmptyRenderers; i++) 
					{
						itemRenderer = getEmptyItemRenderer();
						
						(itemRenderer as Sprite3D).moveTo(
							currentX,
							currentY
						);
						
						if (_direction == Direction.HORIZONTAL)
						{
							currentX += (itemRenderer as Sprite3D).width + _columnsGap;
						}
						else
						{
							currentY += (itemRenderer as Sprite3D).height + _rowsGap;
						}
						
						_container.addChild(itemRenderer as Sprite3D);
						_listAddedEmptyItemRenderers.push(itemRenderer);
					}
				}
			}
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
	}
}