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
	
	import org.goasap.PlayStates;
	import org.goasap.managers.LinearGoRepeater;
	import org.opentween.OpenTween;

	public class EasyScrollabelList3D extends KineticScrollContainer
	{
		public function EasyScrollabelList3D()
		{
			super();
		}
		
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
		
		
		private var _snapToEnd:Boolean = false;
		
		/** set to true to snap end of list to the bottom of view port
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
		
		/** Enables snapping to closest item in the end of kinetic or mouse scroll.
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
		}

		
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
			
			itemIndex = Math.min(itemIndex, _dataSource.length - 1);
			var targetIndex:uint = Math.floor(itemIndex / _numItemsPerLine) * _numItemsPerLine;
			
			scrollToIndex(targetIndex, !_lockAnimation);
		}
		
		public function get currentItemMax():uint
		{
			if (_dataSource == null)
			{
				return 0;
			}
			
			return Math.floor((_dataSource.length - 1) / (numLinesPerPage * numItemsPerLine)) * numLinesPerPage * _numItemsPerLine;
		}
		
		public function get currentPage():int
		{
			return Math.floor(_firstVisibleIndex / _numItemsPerLine / _numLinesPerPage);
		}
		
		public function set currentPage(value:int):void
		{
			value = Math.max(0, value);
			
			var targetIndex:uint = Math.min(value * _numItemsPerLine * _numLinesPerPage, _dataSource.length - 1);
			
			scrollToIndex(targetIndex, !_lockAnimation);
		}
		
		private function scrollToIndex(index:int, animate:Boolean = true):void
		{
			if (index == _firstVisibleIndex)
			{
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
				
				while (_lastVisibleIndex == _dataSource.length - 1)
				{
					_firstVisibleIndex -= _numItemsPerLine;
					updateItems();
					
					scrolledBack = true;
				}
				
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
			
			_itemsContainerCamera.scrollX = Direction.VERTICAL ? nextPosition : 0;
			_itemsContainerCamera.scrollY =  Direction.VERTICAL ? 0 : nextPosition;
			
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
				_itemsContainerCamera,
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
		
		public function getItemRendererByIndex(index:int):IEasyItemRenderer
		{
			var childIndex:int = index + (_firstVisibleIndex - dataBeginIndex);
			if (childIndex >= _itemsContainer.numChildren)
			{
				return null;
			}
			
			return _itemsContainer.getChildAt(childIndex) as IEasyItemRenderer;
		}
		
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
			
			if (scrollingCompleted)
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
			if (_snapToEnd)
			{
				if (_lastVisibleIndex < (_dataSource.length - 1))
				{
					while (_itemsContainerCamera.scrollY >= _secondLinePosition && _lastVisibleIndex < (_dataSource.length - 1))
					{
						_itemsContainerCamera.scrollY -= _secondLinePosition;
						_firstVisibleIndex += _numItemsPerLine;
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
			}
			else
			{
				while (_itemsContainerCamera.scrollY >= _secondLinePosition && _firstVisibleIndex < currentItemMax)
				{
					_itemsContainerCamera.scrollY -= _secondLinePosition;
					_firstVisibleIndex += _numItemsPerLine;
					updateItems();
				}
				
				if (_firstVisibleIndex == currentItemMax)
				{
					if (_itemsContainerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
					{
						_itemsContainerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
						return true;
					}
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
		
		override protected function validateTopBorder():Boolean
		{
			if (_firstVisibleIndex != 0)
			{
				while (_itemsContainerCamera.scrollY <= _previousLinePosition && _firstVisibleIndex != 0)
				{
					_itemsContainerCamera.scrollY -= _previousLinePosition;
					_firstVisibleIndex = Math.max(0, _firstVisibleIndex - _numItemsPerLine);
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
		
		
		override protected function validateRightBorder():Boolean
		{
			if (_snapToEnd)
			{
				if (_lastVisibleIndex < (_dataSource.length - 1))
				{
					while (_itemsContainerCamera.scrollX >= _secondLinePosition && _lastVisibleIndex < (_dataSource.length - 1))
					{
						_itemsContainerCamera.scrollX -= _secondLinePosition;
						_firstVisibleIndex += _numItemsPerLine;
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
			}
			else
			{
				while (_itemsContainerCamera.scrollX >= _secondLinePosition && _firstVisibleIndex < currentItemMax)
				{
					_itemsContainerCamera.scrollX -= _secondLinePosition;
					_firstVisibleIndex += _numItemsPerLine;
					updateItems();
				}
				
				if (_firstVisibleIndex == currentItemMax)
				{
					if (_itemsContainerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
					{
						_itemsContainerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
						return true;
					}
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
		
		override protected function validateLeftBorder():Boolean
		{
			if (_firstVisibleIndex != 0)
			{
				while (_itemsContainerCamera.scrollX <= _previousLinePosition && _firstVisibleIndex != 0)
				{
					_itemsContainerCamera.scrollX -= _previousLinePosition;
					_firstVisibleIndex = Math.max(0, _firstVisibleIndex - _numItemsPerLine);
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
			
			if (itemsContainerWidth <= _scrollingMask.width ||
				(_itemsContainerCamera.scrollX < leftBorder && _firstVisibleIndex == 0)
			)
			{
				targetPoint.x = leftBorder;
				borderReached = true;
			}
			else if (_itemsContainerCamera.scrollX > rightBorder && _lastVisibleIndex == (_dataSource.length - 1))
			{
				targetPoint.x = rightBorder;
				borderReached = true;
			}
			
			if (itemsContainerHeight <= _scrollingMask.height ||
				(_itemsContainerCamera.scrollY < topBorder && _firstVisibleIndex == 0)
			)
			{
				targetPoint.y = topBorder;
				borderReached = true;
			}
			else if (_itemsContainerCamera.scrollY > bottomBorder && _lastVisibleIndex == (_dataSource.length - 1))
			{
				targetPoint.y = bottomBorder;
				borderReached = true;
			}
			
			if (!borderReached && _snapToClosestItem)
			{
				var cameraScrollPosition:Number = _direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY : _itemsContainerCamera.scrollX;
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
			if (_firstVisibleIndex > _dataSource.length - 1)
			{
				_firstVisibleIndex = Math.max(_dataSource.length - _numItemsPerLine, 0);
			}
			
			updateItems();
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
				while (_itemsContainer.numChildren > 0)
				{
					_itemsContainer.removeChildAt(0);
				}
				return;
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
			
			for (var i:int = dataBeginIdx; i < dataSource.length; i++) 
			{
				if (!breakOnNextLine)
				{
					_lastVisibleIndex = i;
				}
				
				if (_itemsContainer.numChildren > i - dataBeginIdx)
				{
					itemRenderer = _itemsContainer.getChildAt(i - dataBeginIdx) as IEasyItemRenderer;
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
								
								child = _itemsContainer.getChildAt(j);
								
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
							_itemsContainerSize += rowHeight + _rowsGap;
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
								
								child = _itemsContainer.getChildAt(j);
								
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
							_itemsContainerSize += rowWidth + _columnsGap;
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