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
			
			mouseEnabled = false;
			
			_scrollingMask = new InteractiveSprite3D();
			_scrollingMask.mouseEnabled = true;
			_scrollingMask.setTexture(FormsTextures.bg_blue_plate);
			addChild(_scrollingMask);
			
			_itemsContainerCamera = new CustomCamera();
			
			_itemsContainer = new UIComponent3D();
			_itemsContainer.camera = _itemsContainerCamera;
			addChild(_itemsContainer);
			
			_maskRect = new Rectangle();
			
			_itemsContainer.mask = _scrollingMask;
		}
		
		public function set backgroundMouseEnabled(value:Boolean):void
		{
			_scrollingMask.mouseEnabled = value;
			if (value)
			{
				_scrollingMask.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			}
			else
			{
				_scrollingMask.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			}
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
			_itemsContainer.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			_scrollingMask.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			super.onAddedToScene();
			
			_stage = ApplicationBase.getInstance().stage;
			var currentFPS:Number = _stage.frameRate;
			
			FRICTION = FRICTION_BASE + FRICTION_FPS_COEFF * ((currentFPS - FRICTION_DEFAULT_FPS) / FRICTION_DEFAULT_FPS);
			
			FRICTION = Math.min(FRICTION, 0.98); //just in case
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
			
			_itemsContainer.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			_scrollingMask.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			
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
		
		private var _lockAnimation:Boolean = false;
		public function set lockAnimation(value:Boolean):void
		{
			_lockAnimation = value;
		}
		
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
						PAGE_ANIMATION_DURATION / 2,
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
				if (_itemsContainerCamera.scrollY < 0)
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
				if (_itemsContainerCamera.scrollX < 0)
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
					if (_itemsContainerCamera.scrollX > (lineSize / 2))
					{
						_scrollPosition += numItemsPerLine;
						update();
						_itemsContainerCamera.scrollX -= lineSize;
					}
				}
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
		
		
		//Start Scrolling 
		private function onItemsContainerMouseDown(event:Input3DMouseEvent):void
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
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, int.MAX_VALUE);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		
		//Scrolling on mouse move
		
		private var _scrollStarted:Boolean = false;
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
				_scrollStarted = true;
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
			if (_scrollStarted)
			{
				event.stopImmediatePropagation();
				_scrollStarted = false;
			}
			
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
		
		private var _numLinesPageSlide:int = 0;
		
		/** num lines to animated slide on page change, default is page size (rowCount/columncount) */
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
			if (_numLinesPageSlide == 0)
			{
				_numLinesPageSlide = _direction == Direction.HORIZONTAL ? _rowCount : _columnCount;
			}
			
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
			
			if (_stage != null && !_lockAnimation)
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
			if (_velocity != 0)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				_itemsContainerCamera.scrollX = 0;
				_itemsContainerCamera.scrollY = 0;
				onAnimationCompleted();
			}
			
			var newPosition:uint = Math.min(scrollPositionMax, value * numItemsPerPage);
			var nextPage:Boolean = newPosition > _scrollPosition;
			
			if (value == currentPage || Math.abs(newPosition - _scrollPosition) < numItemsPerPage)
			{
				if (_scrollPosition != value * numItemsPerPage)
				{
					var numItemsToScroll:int = _scrollPosition - newPosition;
					var numLinesToScroll:int = Math.floor(
						numItemsToScroll / numItemsPerLine
					);
					
					if (_direction == Direction.HORIZONTAL)
					{
						_itemsContainerCamera.scrollY += lineSize * numLinesToScroll;
					}
					else
					{
						_itemsContainerCamera.scrollX += lineSize * numLinesToScroll;
					}
				}
				
				_scrollPosition = Math.min(scrollPositionMax, value * numItemsPerPage);
				
				_isAnimated = true;
				lockItems();
				
				update();
				
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
				
				return;
			}
			
			var immediate:Boolean = Math.abs(value - currentPage) > 1;
			
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
			
			_isAnimated = true;
			_lockUpdate = true;
			
			lockItems();
			
			var props:Object = new Object();
			var isHalf:Boolean = false;
			
			if (_direction == Direction.HORIZONTAL)
			{
				props.scrollY = nextPage ? pageSlideSize / 2 : -pageSlideSize / 2;
				isHalf = nextPage ? _itemsContainerCamera.scrollY > props.scrollY : _itemsContainerCamera.scrollY < props.scrollY;
			}
			else
			{
				props.scrollX = nextPage ? pageSlideSize / 2 : -pageSlideSize / 2;
				isHalf = nextPage ? _itemsContainerCamera.scrollX > props.scrollX : _itemsContainerCamera.scrollX < props.scrollX;
			}
			
			if (isHalf)
			{
				onAnimationPageHalfCompleted(nextPage, false);
				return;
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
		
		private function onAnimationPageHalfCompleted(nextPage:Boolean, fromTween:Boolean = true):void
		{
			_lockUpdate = false;
			update();
			
			var props:Object = new Object();
			
			if (fromTween)
			{
				if (_direction == Direction.HORIZONTAL)
				{
					_itemsContainerCamera.scrollY = nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
				}
				else
				{
					_itemsContainerCamera.scrollX = nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
				}
			}
			else
			{
				if (_direction == Direction.HORIZONTAL)
				{
					_itemsContainerCamera.scrollY += nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
				}
				else
				{
					_itemsContainerCamera.scrollX += nextPage ? -pageSlideSize / 2 : pageSlideSize / 2;
				}
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
			
			if (_stage != null && !_lockAnimation)
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
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
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
				var item:ILockableEasyItemRenderer = _listItemRenderers[i] as ILockableEasyItemRenderer;
				if (item != null)
				{
					item.locked = true;
				}
			}
		}
		
		private function unlockItems():void
		{
			for (var i:int = 0; i < _listItemRenderers.length; i++) 
			{
				var item:ILockableEasyItemRenderer = _listItemRenderers[i] as ILockableEasyItemRenderer;
				if (item != null)
				{
					item.locked = false;
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
		
		private var _numAdditionalDrawingLines:uint = 0;

		public function set numAdditionalDrawingLines(value:uint):void
		{
			_numAdditionalDrawingLines = value;
		}
		
		override public function getItemRendererByIndex(index:int):IEasyItemRenderer
		{
			return _listItemRenderers[int(numItemsPerLine + index)];
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
			
			var dataBeginIdx:int = _scrollPosition - numItemsPerLine;
			var numAdditionalLinesCoeff:uint = 2 + _numAdditionalDrawingLines;
			var dataEndIdx:int = dataBeginIdx + numItemsPerPage + numItemsPerLine * numAdditionalLinesCoeff;
			
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
			
			for (i = dataBeginIdx; i < dataEndIdx; i++)
			{
				
				switch (_direction)
				{
					case Direction.HORIZONTAL:
						viewRow		= Math.floor((i - dataBeginIdx) / columnCount) - 1;
						viewColumn	= (i - dataBeginIdx) % columnCount;
						break;
					
					case Direction.VERTICAL:
						viewRow		= (i - dataBeginIdx) % rowCount;
						viewColumn	= Math.floor((i - dataBeginIdx) / rowCount) - 1;
						break;
				}
				
				var itemData:* = i < 0 ? null : getItemData(i);
				
				if (_listItemRenderers.length < (i - dataBeginIdx) + 1)
				{
					itemRenderer = getItemRenderer();
					_itemsContainer.addChild(itemRenderer as Sprite3D);
					(itemRenderer as Sprite3D).moveTo(viewColumn * (_columnWidth + _columnsGap), viewRow * (_rowHeight + _rowsGap));
					_listItemRenderers.push(itemRenderer);
				}
				else
				{
					itemRenderer = _listItemRenderers[i - dataBeginIdx];
				}
				
				itemRenderer.itemData = itemData;
				itemRenderer.selected = isItemSelected(itemData);
				itemRenderer.highlighted = false;
				(itemRenderer as Sprite3D).visible = itemData != null;
				itemRenderer.update();
				
				
				rowHeight = Math.max(rowHeight, itemRenderer.height);
			}
			
			var numShownItems:int = dataEndIdx - dataBeginIdx;
			
			if (numShownItems < _listItemRenderers.length)
			{
				var itemsToRemove:Array = _listItemRenderers.splice(numShownItems, _listItemRenderers.length - numShownItems);
				for (var j:int = 0; j < itemsToRemove.length; j++) 
				{
					freeItemRenderer(itemsToRemove[j]);
				}
				
			}
			
			_scrollingMask.visible = numItems > 0;
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
		
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