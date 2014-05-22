package molehill.easy.ui3d.list
{
	import easy.core.Direction;
	import easy.ui.IEasyItemRenderer;
	import easy.ui.ILockableEasyItemRenderer;
	
	import fl.motion.easing.Linear;
	
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
	
	import org.opentween.OpenTween;
	
	import tempire.model.types.textures.FormsTextures;

	public class EasyTileList3DAnimated extends EasyTileList3D
	{
		private var _itemsContainer:UIComponent3D;
		private var _itemsContainerCamera:CustomCamera;
		private var _scrollingMask:InteractiveSprite3D;
		public function EasyTileList3DAnimated()
		{
			super();
			
			mouseEnabled = true;
			
			_scrollingMask = new InteractiveSprite3D();
			_scrollingMask.setTexture(FormsTextures.bg_blue_plate);
			addChild(_scrollingMask);
			
			_itemsContainerCamera = new CustomCamera();
			
			_itemsContainer = new UIComponent3D();
			_itemsContainer.camera = _itemsContainerCamera;
			addChild(_itemsContainer);
			
			_maskRect = new Rectangle();
			
			_itemsContainer.mask = _scrollingMask;
		}
		
		private var _maskRect:Rectangle;
		private function set updateMask(value:Rectangle):void
		{
			_maskRect = value;
			_scrollingMask.moveTo(value.x, value.y);
			_scrollingMask.setSize(value.width, value.height);
		}
			
		
		override protected function onAddedToScene():void
		{
			_itemsContainer.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onMouseDown);
			super.onAddedToScene();
			
			_stage = Application.getInstance().stage;
			var currentFPS:Number = _stage.frameRate;
			
			FRICTION = FRICTION_BASE + FRICTION_FPS_COEFF * ((currentFPS - FRICTION_DEFAULT_FPS) / FRICTION_DEFAULT_FPS);
			
			FRICTION = Math.min(FRICTION, 0.98); //just in case
			/*
			var rect:Rectangle = scrollRect;
			
			if (rect == null)
			{
				return;
			}
			
			//Do this hack here to not changing parent form size when it centered first time
			
			_itemsContainer.graphics.clear();
			_itemsContainer.graphics.beginFill(0, 0.01); //hack for removing black back
			
			if (_direction == Direction.HORIZONTAL)
			{
				_itemsContainer.graphics.drawRect(rect.x, rect.y - 2 * (_rowHeight + _rowsGap), rect.width, rect.height + 4 * (_rowHeight + _rowsGap));
			}
			else
			{
				_itemsContainer.graphics.drawRect(rect.x - 2 * (_columnsGap + _columnWidth), rect.y, rect.width + 4 * (_columnWidth + _columnsGap), rect.height);
			}
			
			_itemsContainer.graphics.endFill();
			*/
		}
		
		override protected function onRemovedFromScene():void
		{
			if (_stage != null)
			{
				_stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				_stage = null;
			}
			
			removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onMouseDown);
			
			_itemsContainerCamera.scrollX = 0;
			_itemsContainerCamera.scrollY = 0;
			onAnimationCompleted();
		}
		
		private var _mouseScrollingEnabled:Boolean = true;
		
		/** enable/disable mouse scrolling */
		public function set mouseScrollingEnabled(value:Boolean):void
		{
			_mouseScrollingEnabled = value;
		}
		
		
		private var _mouseScrollShortListLock:Boolean = false;
		
		/** set to true to disable mouse scrolling, when numItems < numItemsPerPage */
		public function set mouseScrollShortListLock(value:Boolean):void
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

		
		/* ANIMATION */
		
		private var _isAnimated:Boolean = false;
		private var _lockUpdate:Boolean = false;
		
		private var _startPoint:Point = new Point();
		
		private var _velocity:Number = 0;
		private var _newPosition:Number = 0;
		private var _lastPosition:Number = 0;
		private var _newTime:uint = 0;
		private var _lastTime:uint = 0;
		private var _listVelocity:Array = new Array();
		
		private var _stage:Stage;
		
		private const LIST_VELOCITY_LENGTH:uint = 4;
		private const MIN_VELOCITY:Number = 2;
		private const MIN_DETECTED_VELOCITY:Number = 0.2;
		
		private const PAGE_ANIMATION_DURATION:Number = 0.1;
		
		private const MIN_DIFF_TO_SCROLL:uint = 5;
		
		private const SPEED_COEFF:Number = 24;
		
		private function get scrollDiffMax():int
		{
			return scrollPageMax == 0 ? -(lineSize / 3) : (-( Math.ceil(numItems / numItemsPerLine) - (_scrollPosition + numItemsPerPage) / numItemsPerLine)) * lineSize - (lineSize / 3);
		}
		
		private function get scrollDiffMin():int
		{
			return (_scrollPosition / numItemsPerLine) * lineSize + (lineSize / 3);
		}
		
		/** Scrolls list on @diff from current position and returns num lines scrolled on this iteration
		 *  numLines > 0 - forward, numLines < 0 - backward
		 */
		private function scrollOn(diff:Number):int
		{
			var numLines:int = 0;
			var coeff:int = diff >= 0 ? -1 : 1;
			
			if (diff < 0)
			{
				diff = Math.max(scrollDiffMax, diff);
			}
			else
			{
				diff = Math.min(scrollDiffMin, diff);
			}
			
			numLines = Math.floor(Math.abs(diff) / lineSize);
			
			if (numLines != 0)
			{
				_scrollPosition += coeff * numItemsPerLine * numLines;
				
				update();
			}
			
			
			diff += coeff * numLines * lineSize;
			
			if (_direction == Direction.HORIZONTAL)
			{
				_itemsContainerCamera.scrollY = -diff;
			}
			else
			{
				_itemsContainerCamera.scrollX = -diff;
			}
			
			return numLines * coeff;
		}
		
		private function moveToClosestLine():void
		{
			if (!_snapToClosestItem)
			{
				if ((currentItem == 0 && (-_itemsContainerCamera.scrollY > 0 || -_itemsContainerCamera.scrollX > 0)) ||
					(currentItem == scrollItemMax && (-_itemsContainerCamera.scrollY < 0 || -_itemsContainerCamera.scrollX < 0)))
				{
					OpenTween.go(
						_itemsContainerCamera,
						{
							scrollX : 0,
							scrollY : 0
						},
						PAGE_ANIMATION_DURATION / 4,
						0,
						Linear.easeNone,
						onAnimationCompleted
					);
					return;
				}
				
				onAnimationCompleted();
				return;
			}
			
			if (_direction == Direction.HORIZONTAL)
			{
				if (_itemsContainerCamera.scrollY > 0)
				{
					if (_itemsContainerCamera.scrollY < -(lineSize / 2))
					{
						_scrollPosition -= numItemsPerLine;
						_scrollPosition = Math.max(0, _scrollPosition);
						update();
						_itemsContainerCamera.scrollY += lineSize;
					}
				}
				else
				{
					if (_itemsContainerCamera.scrollY > (lineSize / 2))
					{
						_scrollPosition += numItemsPerLine;
						update();
						_itemsContainerCamera.scrollY -= lineSize;
					}
				}
			}
			else
			{
				if (_itemsContainerCamera.scrollX > 0)
				{
					if (_itemsContainerCamera.scrollX < -(lineSize / 2))
					{
						_scrollPosition -= numItemsPerLine;
						_scrollPosition = Math.max(0, _scrollPosition);
						update();
						_itemsContainerCamera.scrollX += lineSize;
					}
				}
				else
				{
					if (_itemsContainerCamera.scrollX > +(lineSize / 2))
					{
						_scrollPosition += numItemsPerLine;
						update();
						_itemsContainerCamera.scrollX == lineSize;
					}
				}
			}
			
			OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : 0,
					scrollY : 0
				},
				PAGE_ANIMATION_DURATION / 4,
				0,
				Linear.easeNone,
				onAnimationCompleted
			);
		}
		
		
		//Start Scrolling
		
		private function onMouseDown(event:Input3DMouseEvent):void
		{
			if (!_mouseScrollingEnabled)
			{
				return;
			}
			
			if (_mouseScrollShortListLock)
			{
				if (numItems <= numItemsPerPage)
				{
					return;
				}
			}
			
			_isAnimated = true;
			
			_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
			
			_startPoint.x = event.stageX + _itemsContainerCamera.scrollX;
			_startPoint.y = event.stageY + _itemsContainerCamera.scrollY;
			
			_listVelocity.splice(0, _listVelocity.length);
			
			_lastTime = 0;
			_velocity = 0;
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		
		//Scrolling on mouse move
		
		private function onStageMouseMove(event:MouseEvent):void
		{
			var diff:Number;
			
			diff = _direction == Direction.HORIZONTAL ? (event.stageY - _startPoint.y) : (event.stageX - _startPoint.x);
			
			
			
			if (Math.abs(diff) < MIN_DIFF_TO_SCROLL)
			{
				return;
			}
			
			if (_lastTime == 0)
			{
				lockItems();
				_lastTime = getTimer();
				_lastPosition =  _direction == Direction.HORIZONTAL ? _stage.mouseY : _stage.mouseX;
				
				_stage.addEventListener(Event.ENTER_FRAME, onScrollEnterFrame);
			}
			
			var numLines:int = scrollOn(diff);
			
			if (numLines != 0)
			{
				_startPoint.y -= numLines * lineSize;
				_startPoint.x -= numLines * lineSize;
			}
		}
		
		private function onScrollEnterFrame(event:Event):void
		{
			if (_stage == null)
			{
				_velocity = 0;
				_stage.removeEventListener(Event.ENTER_FRAME, onScrollEnterFrame);
				return;
			}
			
			_newTime = getTimer();
			_newPosition = _direction == Direction.HORIZONTAL ? _stage.mouseY : _stage.mouseX;
			
			_velocity = (_newPosition - _lastPosition) / (_newTime - _lastTime);
			
			_listVelocity.push(_velocity);
			
			if (_listVelocity.length > LIST_VELOCITY_LENGTH)
			{
				_listVelocity.shift();
			}
			
			_lastTime = _newTime;
			_lastPosition = _newPosition;
		}		
		
		//Scroll on mouse release
		
		private var FRICTION:Number = 0.92;
		private const FRICTION_BASE:Number = 0.92;
		private const FRICTION_FPS_COEFF:Number = 0.026;
		private const FRICTION_DEFAULT_FPS:Number = 24;
		private var _diff:int = 0;
		
		private function onStageMouseUp(event:MouseEvent):void
		{
			if (_stage != null)
			{
				_stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
				_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			}
			
			_stage.removeEventListener(Event.ENTER_FRAME, onScrollEnterFrame);
			
			if (_listVelocity.length == 0 && _lastTime != 0)
			{
				onScrollEnterFrame(null);
			}
			
			if (_listVelocity.length == 0)
			{
				moveToClosestLine();
				return;
			}
			
			_velocity = 0;
			
			for (var i:int = 0; i < _listVelocity.length; i++) 
			{
				_velocity += _listVelocity[i];
			}
			
			_velocity = _velocity / _listVelocity.length;
			
			if (Math.abs(_velocity) < MIN_DETECTED_VELOCITY)
			{
				moveToClosestLine();
				return;
			}
			
			if (Math.abs(_velocity) < MIN_VELOCITY)
			{
				_velocity = _velocity < 0 ? -MIN_VELOCITY : MIN_VELOCITY;
			}
			
			_velocity = _velocity * SPEED_COEFF;
			
			_diff = _direction == Direction.HORIZONTAL ? -_itemsContainerCamera.scrollY : -_itemsContainerCamera.scrollX;
			
			_stage.addEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
		}
		
		private function onKineticEnterFrame(event:Event):void
		{
			_diff += _velocity;
			
			if (scrollOn(_diff) != 0)
			{
				_diff -= _diff;
			}
			
			_velocity *= FRICTION;
			
			if (Math.abs(_velocity) < 1)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				moveToClosestLine();
			}
			
			if (_diff < 0)
			{
				if (_diff < scrollDiffMax)
				{
					_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
					moveToClosestLine();
				}
			}
			else 
			{
				if (_diff > scrollDiffMin)
				{
					_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
					moveToClosestLine();
				}
			}
		}
		
		
		
		// animate per page and per item scrolling
		
		private var _numLinesPageSlide:int = 1;
		
		/** num lines to animated slide on page change */
		public function set numLinesPageSlide(value:int):void
		{
			_numLinesPageSlide = Math.max(
				1,
				Math.min(
					_direction == Direction.HORIZONTAL ? _rowCount : _columnCount,
					value
				)
			);
		}
		
		private function get pageSlideSize():Number
		{
			return _numLinesPageSlide * lineSize;
		}
		
		private function get scrollPositionMax():int
		{
			return Math.max(0, Math.ceil(numItems / numItemsPerLine) * numItemsPerLine - numItemsPerPage);
		}
		
		override public function get currentPage():int
		{
			return _scrollPosition > (numItems - numItemsPerPage) ? Math.ceil(_scrollPosition / numItemsPerPage) : Math.floor(_scrollPosition / numItemsPerPage);
		}
		
		override public function set currentPage(value:int):void
		{
			var pageMax:int = this.scrollPageMax;			
			if (value > pageMax)
				value = pageMax;
			if (value < 0)
				value = 0;
			
			if ((value * numItemsPerPage) == _scrollPosition)
				return;
			
			if (_stage != null)
			{
				animatePage(value);
			}
			else
			{
				_scrollPosition = Math.min(scrollPositionMax, value * numItemsPerPage);
				_itemsContainerCamera.scrollX = 0;
				_itemsContainerCamera.scrollY = 0;
				update();
			}
		}
		
		private var _lockMoreThanOnePageAnimation:Boolean = false;
		
		/** play page animation (false) on scrolling more than on one page or not (true) */ 
		public function set lockMoreThanOnePageAnimation(value:Boolean):void
		{
			_lockMoreThanOnePageAnimation = value;
		}

		
		private function animatePage(value:int):void
		{
			var nextPage:Boolean = value > currentPage;
			var immediate:Boolean = Math.abs(value - currentPage) > 1;
			
			if (_velocity != 0)
			{
				removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				_itemsContainerCamera.scrollX = 0;
				_itemsContainerCamera.scrollY = 0;
				onAnimationCompleted();
			}
			
			_scrollPosition = Math.min(scrollPositionMax, value * numItemsPerPage);
			
			if (_isAnimated || (_lockMoreThanOnePageAnimation && immediate))
			{
				if (immediate)
				{
					_itemsContainerCamera.scrollX = 0;
					_itemsContainerCamera.scrollY = 0;
				}
				update();
				return;
			}
			
			_itemsContainerCamera.scrollX = 0;
			_itemsContainerCamera.scrollY = 0;
			
			_isAnimated = true;
			_lockUpdate = true;
			
			lockItems();
			
			var props:Object = new Object();
			
			if (_direction == Direction.HORIZONTAL)
			{
				props.scrollX = nextPage ? pageSlideSize / 2 : -pageSlideSize / 2;
			}
			else
			{
				props.scrollY = nextPage ? pageSlideSize / 2 : -pageSlideSize / 2;
			}
			
			OpenTween.go(
				_itemsContainerCamera,
				props,
				PAGE_ANIMATION_DURATION / 2,
				0,
				Linear.easeNone,
				onAnimationPageHalfCompleted,
				null,
				[nextPage]
			);
				
		}
		
		private function onAnimationPageHalfCompleted(nextPage:Boolean):void
		{
			_lockUpdate = false;
			update();
			
			var props:Object = new Object();
			
			if (_direction == Direction.HORIZONTAL)
			{
				_itemsContainerCamera.scrollY = nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
			}
			else
			{
				_itemsContainerCamera.scrollX = nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
			}
			
			OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : 0,
					scrollY : 0
				},
				PAGE_ANIMATION_DURATION / 2,
				0,
				Linear.easeNone,
				onAnimationCompleted
			);
		}
		
		/** use currentItem++ / currentItem-- only with list with single row for Direction.VERTICAL or with single column for Direction.HORIZONTAL */ 
		override public function set currentItem(value:int):void
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
			
			if (_stage != null)
			{
				animateItem(value);
			}
			else
			{
				_scrollPosition = _direction == Direction.HORIZONTAL ? value * columnCount : value * rowCount;
				_scrollPosition = Math.min(scrollPositionMax, _scrollPosition);
				_itemsContainerCamera.scrollX = 0;
				_itemsContainerCamera.scrollY = 0;
				update();
			}
		}
		
		private function animateItem(value:int):void
		{
			var nextItem:Boolean = value > currentItem;
			var immediate:Boolean = Math.abs(value - currentItem) > 1;
			
			if (_velocity != 0)
			{
				removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				_itemsContainerCamera.scrollX = 0;
				_itemsContainerCamera.scrollY = 0;
				onAnimationCompleted();
			}
			
			if (_isAnimated || immediate)
			{
				_scrollPosition = _direction == Direction.HORIZONTAL ? value * columnCount : value * rowCount;
				_scrollPosition = Math.min(scrollPositionMax, _scrollPosition);
				
				if (immediate)
				{
					_itemsContainerCamera.scrollX = 0;
					_itemsContainerCamera.scrollY = 0;
				}
				
				update();
				return;
			}
			
			_isAnimated = true;
			_lockUpdate = true;
			
			lockItems();
			
			var props:Object = new Object();
			
			if (_direction == Direction.HORIZONTAL)
			{
				props.scrollY = nextItem ? (_rowHeight + _rowsGap) : -(_rowHeight + _rowsGap);
			}
			else
			{
				props.scrollX = nextItem ? (_columnWidth + _columnsGap) : -(_columnWidth + _columnsGap);
			}
			
			if ((currentItem == 0 && (props.y > 0 || props.x > 0)) ||
				(currentItem == scrollItemMax && (props.y < 0 || props.x < 0)))
			{
				props.scrollX = 0;
				props.scrollY = 0;
			}
			
			_scrollPosition = _direction == Direction.HORIZONTAL ? value * columnCount : value * rowCount;
			_scrollPosition = Math.min(scrollPositionMax, _scrollPosition);
			
			OpenTween.go(
				_itemsContainerCamera,
				props,
				PAGE_ANIMATION_DURATION,
				0,
				Linear.easeNone,
				onItemAnimationCompleted
			);
		}		
		
		private function onItemAnimationCompleted():void
		{
			onAnimationCompleted();
			_lockUpdate = false;
			
			update();
			
			_itemsContainerCamera.scrollX = 0;
			_itemsContainerCamera.scrollY = 0;
		}
		
		private function onAnimationCompleted():void
		{
			_isAnimated = false;
			_velocity = 0;
			
			unlockItems();
		}
		
		private function lockItems():void
		{
			for (var i:int = 0; i < _listItemRenderers.length; i++) 
			{
				var item:Sprite3D = _listItemRenderers[i] as Sprite3D;
				if (item != null)
				{
					item.mouseEnabled = false;
				}
			}
		}
		
		private function unlockItems():void
		{
			for (var i:int = 0; i < _listItemRenderers.length; i++) 
			{
				var item:Sprite3D = _listItemRenderers[i] as Sprite3D;
				if (item != null)
				{
					item.mouseEnabled = true;
				}
			}
		}
		
		/* end of animation */
		
		
		private function get lineSize():Number
		{
			return _direction == Direction.HORIZONTAL ? _rowHeight + _rowsGap : _columnWidth + _columnsGap;
		}
		
		private function get numItemsPerLine():uint
		{
			return _direction == Direction.HORIZONTAL ? _columnCount : _rowCount;
		}
		
		private var _updateCallback:Function;

		public function set updateCallback(value:Function):void
		{
			_updateCallback = value;
		}

		
		private var _listItemRenderers:Array = new Array();
		private var _listFreeItemRenderers:Array = new Array();
		
		override protected function doUpdate():void
		{
			if (_lockUpdate)
			{
				return;
			}
			
			var maxScrollPosition:int = scrollPositionMax;
			
			if (_scrollPosition > maxScrollPosition)
			{
				_scrollPosition = maxScrollPosition;
			}
			
			_listItemRenderers.splice(0, _listItemRenderers.length);
			
			var dataBeginIdx:int = Math.max(0, _scrollPosition - numItemsPerLine);
			var dataEndIdx:int = dataBeginIdx + numItemsPerPage + (_scrollPosition == 0 ? numItemsPerLine : numItemsPerLine * 2);
			
			var numItems:int = this.numItems;
			if (dataEndIdx >= numItems)
				dataEndIdx = numItems;
			
			//---
			var offsetRows:int = dataBeginIdx / columnCount;
			var offsetColumns:int = dataBeginIdx % columnCount;
			//---
			var viewRow:int = 0;
			var viewColumn:int = -1;
			var itemRenderer:IEasyItemRenderer;
			
			var cy:int = 0;
			var rowHeight:int = 0;
			var i:int = 0;
			
			
			for (var previousItemData:* in _dictCurrentStateItemRenderersByData)
			{
				for (i = dataBeginIdx; i < dataEndIdx; i++)
				{
					var newItemData:* = getItemData(i);
					if (previousItemData === newItemData)
					{
						break;
					}
				}
				
				if (i < dataEndIdx)
				{
					continue;
				}
				
				_listFreeItemRenderers.push(_dictCurrentStateItemRenderersByData[previousItemData]);
				
				delete _dictCurrentStateItemRenderersByData[previousItemData];
			}
			
			for (i = dataBeginIdx; i < dataEndIdx; i++)
			{
				
				switch (_direction)
				{
					case Direction.HORIZONTAL:
						viewRow		= Math.floor((i - dataBeginIdx) / columnCount) - (_scrollPosition >= numItemsPerLine ? 1 : 0);
						viewColumn	= (i - dataBeginIdx) % columnCount;
						break;
					
					case Direction.VERTICAL:
						viewRow		= (i - dataBeginIdx) % rowCount;
						viewColumn	= Math.floor((i - dataBeginIdx) / rowCount) - (_scrollPosition >= numItemsPerLine ? 1 : 0);
						break;
				}
				
				var itemData:* = getItemData(i);
				itemRenderer = _dictCurrentStateItemRenderersByData[itemData] as IEasyItemRenderer;
				if (itemRenderer == null)
				{
					if (_listFreeItemRenderers.length == 0)
					{
						itemRenderer = getItemRenderer();
						_itemsContainer.addChild(itemRenderer as Sprite3D);
					}
					else
					{
						itemRenderer = _listFreeItemRenderers.shift();
					}
				}
				
				itemRenderer.x = viewColumn * (_columnWidth + _columnsGap);
				itemRenderer.y = viewRow * (_rowHeight + _rowsGap);
				itemRenderer.itemData = itemData;
				itemRenderer.selected = isItemSelected(itemData);
				itemRenderer.highlighted = false;
				if (!(itemRenderer is ILockableEasyItemRenderer) || !(itemRenderer as ILockableEasyItemRenderer).locked)
					itemRenderer.update();
				
				_listItemRenderers.push(itemRenderer);
				
				rowHeight = Math.max(rowHeight, itemRenderer.height);
				
				_dictCurrentStateItemRenderersByData[itemData] = itemRenderer;
			}
			/*
			height = Math.max(
				cy + rowHeight,
				0
			);
			*/
			//---
			
			
			while (_listFreeItemRenderers.length > 0)
			{
				itemRenderer = _listFreeItemRenderers.shift();
				if (itemRenderer == null)
					continue;
				
				freeItemRenderer(itemRenderer);
			}
			
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
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
		
		private var _gradientBorderEnabled:Boolean = false;
		
		
		/** Enables gradient mask on borders of list;
		 * It would move list on gradientBorderSize, which is equals to columnsGap/rowsGap by default
		 */
		/*
		public function set gradientBorderEnabled(value:Boolean):void
		{
			_gradientBorderEnabled = value;
			
			blendMode = _gradientBorderEnabled ? BlendMode.LAYER : BlendMode.NORMAL;
			
			if (_gradientBorderEnabled)
			{
				
			}
			else
			{
				_itemsContainer.graphics.clear();
			}
			
			updateMaskRect();
		}
		
		
		private var _gradientBorderSize:Number = 0;

		/** size of gradient borders, if set to zero - columnsGap/rowsGap would be used (default 0) *
		public function set gradientBorderSize(value:Number):void
		{
			_gradientBorderSize = Math.max(0, value);
			
			updateMaskRect();
		}
		*/
		
		/* scroll rect update */
		
		private var _scrollRectWidth:Number = 0;
		
		public function set scrollRectWidth(value:Number):void
		{
			_scrollRectWidth = value;
			
			updateMaskRect();
		}
		
		private var _scrollRectHeight:Number = 0;
		
		public function set scrollRectHeight(value:Number):void
		{
			_scrollRectHeight = value;
			
			updateMaskRect();
		}
		
		private var _maskRectCustom:Rectangle;

		public function set maskRectCustom(value:Rectangle):void
		{
			_maskRectCustom = value;
			
			updateMaskRect();
		}

		
		private function updateMaskRect():void
		{
			var rect:Rectangle = _maskRect;
			
			if (rect == null)
			{
				rect = new Rectangle();
			}
			
			if (_maskRectCustom != null)
			{
				rect = _maskRectCustom.clone();
			}
			else
			{
				rect.x = 0;
				rect.y = 0;
				rect.width = _scrollRectWidth == 0 ? _columnWidth * _columnCount + _columnsGap * (_columnCount - 1) : _scrollRectWidth;
				rect.height = _scrollRectHeight == 0 ? _rowHeight * _rowCount + _rowsGap * (_rowCount - 1) : _scrollRectHeight;
			}
			
			updateMask = rect;
		}
		
		override public function set columnCount(value:int):void
		{
			super.columnCount = value;
			
			updateMaskRect();
			
			update();
		}
		
		override public function set columnWidth(value:int):void
		{
			super.columnWidth = value;
			
			updateMaskRect();
		}
		
		override public function set columnsGap(value:int):void
		{
			super.columnsGap = value;
			
			updateMaskRect();
		}
		
		override public function set rowCount(value:int):void
		{
			super.rowCount = value;
			
			updateMaskRect();
			
			update();
		}
		
		override public function set rowHeight(value:int):void
		{
			super.rowHeight = value;
			
			updateMaskRect();
		}
		
		override public function set rowsGap(value:int):void
		{
			super.rowsGap = value;
			
			updateMaskRect();
		}
	}
}