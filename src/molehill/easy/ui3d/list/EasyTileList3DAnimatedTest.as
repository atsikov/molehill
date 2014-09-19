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
	
	public class EasyTileList3DAnimatedTest extends EasyList3D
	{
		private var _itemsContainer:UIComponent3D;
		private var _itemsContainerBack:InteractiveSprite3D;
		private var _itemsContainerCamera:CustomCamera;
		private var _scrollingMask:Sprite3D;
		public function EasyTileList3DAnimatedTest()
		{
			super();
			
			mouseEnabled = true;
			
			_scrollingMask = new Sprite3D();
			_scrollingMask.setTexture(FormsTextures.bg_blue_plate);
			_scrollingMask.mouseEnabled = true;
			addChild(_scrollingMask);
			
			_itemsContainerCamera = new CustomCamera();
			
			_itemsContainerBack = new InteractiveSprite3D();
			_itemsContainerBack.setTexture(FormsTextures.bg_blue_plate);
			_itemsContainerBack.mouseEnabled = true;
			_itemsContainerBack.alpha = 0;
			addChild(_itemsContainerBack);
			
			_itemsContainer = new UIComponent3D();
			_itemsContainer.camera = _itemsContainerCamera;
			addChild(_itemsContainer);
			
			_maskRect = new Rectangle();
			
			_itemsContainer.mask = _scrollingMask;
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
			
			var maxItem:int = scrollItemMax;
			var crntItem:int = currentItem;
			if (crntItem > maxItem)
			{
				crntItem = maxItem;
			}
			if (crntItem < 0)
			{
				crntItem = 0;
			}
			
			switch (_direction)
			{
				case Direction.HORIZONTAL:
					_scrollPosition = crntItem * columnCount;
					break;
				
				case Direction.VERTICAL:
					_scrollPosition = crntItem * rowCount;
					break;
			}
			
			//update();
		}
		
		protected var _rowCount:int;
		public function get rowCount():int
		{
			if (direction == Direction.VERTICAL)
			{
				if (dataSource != null)
				{
					return Math.ceil( uint(dataSource['length']) / columnCount );
				}
			}
			
			return _rowCount;
		}
		
		protected var _columnCount:int = 1;
		public function get columnCount():int
		{
			return _columnCount;
		}
		
		protected var _rowHeight:int;
		public function get rowHeight():int
		{
			return _rowHeight;
		}
		
		protected var _columnWidth:int;
		public function get columnWidth():int
		{
			return _columnWidth;
		}
		
		protected var _rowsGap:int;
		public function get rowsGap():int
		{
			return _rowsGap;
		}
		
		protected var _columnsGap:int;
		public function get columnsGap():int
		{
			return _columnsGap;
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
		
		private var _maskRect:Rectangle;
		private function set updateMask(value:Rectangle):void
		{
			_maskRect = value;
			_scrollingMask.moveTo(value.x, value.y);
			_scrollingMask.setSize(value.width, value.height);
			
			_itemsContainerBack.moveTo(value.x, value.y);
			_itemsContainerBack.setSize(value.width, value.height);
		}
		
		
		override protected function onAddedToScene():void
		{
			_itemsContainer.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			_itemsContainerBack.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
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
			_itemsContainerBack.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			
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
			return scrollPageMax * pageSize + (lineSize / 3);
		}
		
		private function get scrollDiffMin():int
		{
			return -lineSize / 3;
		}
		
		/** Scrolls list on @diff from current position and returns num lines scrolled on this iteration
		 *  numLines > 0 - forward, numLines < 0 - backward
		 */
		
		private function scrollOn(diff:Number):void
		{
			var numLines:Number = (_direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY : _itemsContainerCamera.scrollX) / lineSize;
			
			var newPosition:int = Math.min(Math.ceil(numLines) * numItemsPerLine, scrollPositionMax);
			
			if (_scrollPosition != newPosition)
			{
				_scrollPosition = newPosition;
				
				if (_updateCallback != null)
				{
					_updateCallback();
				}
			}
			
			
			//diff += coeff * numLines * lineSize;
			
			if (_direction == Direction.HORIZONTAL)
			{
				_itemsContainerCamera.scrollY = diff < 0 ? 
					Math.min(scrollDiffMax, _itemsContainerCamera.scrollY - diff) :
					Math.max(scrollDiffMin, _itemsContainerCamera.scrollY - diff);
			}
			else
			{
				_itemsContainerCamera.scrollX = diff < 0 ? 
					Math.min(scrollDiffMax, _itemsContainerCamera.scrollX - diff) :
					Math.max(scrollDiffMin, _itemsContainerCamera.scrollX - diff);
			}
		}
		
		private function moveToClosestLine():void
		{
			var pageToScroll:int = -1;
			
			var cameraScroll:Number = _direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY : _itemsContainerCamera.scrollX;
			if (_snapToClosestItem)
			{
				var diff:Number = cameraScroll - currentPage * pageSize;
				if (Math.abs(diff) < (lineSize / 2))
				{
					pageToScroll = currentPage;
				}
				else
				{
					pageToScroll = diff > 0 ? currentPage + 1 : currentPage - 1;
					_scrollPosition += diff > 0 ? 1 : -1;
				}
			}
			else if	(cameraScroll > scrollPageMax * pageSize ||
					cameraScroll < 0)
			{
				pageToScroll = currentPage;
			}
			
			
			if (pageToScroll == -1)
			{
				onAnimationCompleted();
				return;
			}
			
			OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : _direction == Direction.HORIZONTAL ? 0 : pageToScroll * pageSize,
					scrollY : _direction == Direction.HORIZONTAL ? pageToScroll * pageSize : 0
				},
				PAGE_ANIMATION_DURATION / 4,
				0,
				Linear.easeNone,
				onAnimationCompleted
			);
		}
		
		
		//Start Scrolling
		private var _mouseCheckPoint:Point = new Point(); 
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
			
			_mouseCheckPoint.x = event.stageX;
			_mouseCheckPoint.y = event.stageY;
			
			if (!_scrollingMask.hitTestPoint(_mouseCheckPoint))
			{
				return;
			}
			
			_isAnimated = true;
			
			_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
			
			_startPoint.x = event.stageX;
			_startPoint.y = event.stageY;
			
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
			
			scrollOn(diff);
			
			_startPoint.y += diff;
			_startPoint.x += diff;
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
			
			if (_newTime == _lastTime)
			{
				_newTime = _lastTime + 1;
			}
			
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
			
			_stage.addEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
		}
		
		private function onKineticEnterFrame(event:Event):void
		{
			scrollOn(_velocity);
			
			_velocity *= FRICTION;
			
			if (Math.abs(_velocity) < 1)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				moveToClosestLine();
				return;
			}
			
			var checkValue:Number = _direction == Direction.HORIZONTAL ? _itemsContainerCamera.scrollY : _itemsContainerCamera.scrollX;
			if (checkValue >= scrollDiffMax)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				moveToClosestLine();
			}
			else if (checkValue <= scrollDiffMin)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				moveToClosestLine();
			}
		}
		
		
		
		private function get scrollPositionMax():int
		{
			return Math.max(0, Math.ceil(numItems / numItemsPerLine) * numItemsPerLine - numItemsPerPage);
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
		
		protected var _scrollPosition:int = 0;
		public function get currentPage():int
		{
			return _scrollPosition > (numItems - numItemsPerPage) ? Math.ceil(_scrollPosition / numItemsPerPage) : Math.floor(_scrollPosition / numItemsPerPage);
		}
		
		// animate per page and per item scrolling
		
		public function set currentPage(value:int):void
		{
			//TODO currentPage
			var pageMax:int = this.scrollPageMax;			
			if (value > pageMax)
				value = pageMax;
			if (value < 0)
				value = 0;
			
			if ((value * numItemsPerPage) == _scrollPosition)
				return;
			
			_scrollPosition = Math.min(scrollPositionMax, value * numItemsPerPage);
			
			if (_stage != null)
			{
				lockItems();
				OpenTween.go(
					_itemsContainerCamera,
					{
						scrollX : _direction == Direction.HORIZONTAL ? 0 : currentPage * pageSize,
						scrollY : _direction == Direction.HORIZONTAL ? currentPage * pageSize : 0
					},
					PAGE_ANIMATION_DURATION,
					0,
					Linear.easeNone,
					onAnimationCompleted
				);
			}
			else
			{
				_itemsContainerCamera.scrollX = _direction == Direction.HORIZONTAL ? 0 : currentPage * pageSize;
				_itemsContainerCamera.scrollY = _direction == Direction.HORIZONTAL ? currentPage * pageSize : 0;
			}
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
		}
		
		private var _lockMoreThanOnePageAnimation:Boolean = false;
		
		/** play page animation (false) on scrolling more than on one page or not (true) */ 
		public function set lockMoreThanOnePageAnimation(value:Boolean):void
		{
			_lockMoreThanOnePageAnimation = value;
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
				
		/** use currentItem++ / currentItem-- only with list with single row for Direction.VERTICAL or with single column for Direction.HORIZONTAL */ 
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
			
			_scrollPosition = _direction == Direction.HORIZONTAL ? value * columnCount : value * rowCount;
			_scrollPosition = Math.min(scrollPositionMax, _scrollPosition);
			
			if (_stage != null)
			{
				lockItems();
				OpenTween.go(
					_itemsContainerCamera,
					{
						scrollX : _direction == Direction.HORIZONTAL ? 0 : currentPage * pageSize,
						scrollY : _direction == Direction.HORIZONTAL ? currentPage * pageSize : 0
					},
					PAGE_ANIMATION_DURATION,
					0,
					Linear.easeNone,
					onAnimationCompleted
				);
			}
			else
			{
				_itemsContainerCamera.scrollX = _direction == Direction.HORIZONTAL ? 0 : currentPage * pageSize;
				_itemsContainerCamera.scrollY = _direction == Direction.HORIZONTAL ? currentPage * pageSize : 0;
			}
			
			if (_updateCallback != null)
			{
				_updateCallback();
			}
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
		
		protected function get numItemsPerPage():int
		{
			return rowCount * columnCount;
		}
		
		private function get pageSize():uint
		{
			return _direction == Direction.HORIZONTAL ? _rowCount * (_rowHeight + _rowsGap) : _columnCount * (_columnWidth + _columnsGap);
		}
		
		private function get numLinesPerPage():uint
		{
			return _direction == Direction.HORIZONTAL ? _rowCount : _columnCount;
		}
		
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
		
		private var _listItemRenderers:Array = new Array();
		private var _updatePositions:Boolean = true;
		
		override protected function doUpdate():void
		{
			var numItemsLength:int = numItems;
			trace("update");
			
			for (var i:int = 0; i < numItemsLength; i++) 
			{
				var itemRenderer:IEasyItemRenderer = _listItemRenderers.length > i ? _listItemRenderers[i] : getItemRenderer();
				var containsItem:Boolean = _itemsContainer.contains(itemRenderer as Sprite3D);
				if (!containsItem)
				{
					_itemsContainer.addChild(itemRenderer as Sprite3D);
				}
				if (!containsItem || _updatePositions)
				{
					if (_direction == Direction.HORIZONTAL)
					{
						(itemRenderer as Sprite3D).moveTo(
							(i % numItemsPerLine) * (columnWidth + columnsGap),
							Math.floor(i / numItemsPerLine) * (rowHeight + rowsGap)
						);
					}
					else
					{
						(itemRenderer as Sprite3D).moveTo(
							Math.floor(i / numItemsPerLine) * (columnWidth + columnsGap),
							(i % numItemsPerLine) * (rowHeight + rowsGap)
						);
					}
				}
				
				var itemData:* = getItemData(i);
				itemRenderer.itemData = itemData;
				itemRenderer.selected = isItemSelected(itemData);
				itemRenderer.highlighted = false;
				itemRenderer.update();
				if (_listItemRenderers.length <= i)
				{
					_listItemRenderers.push(itemRenderer);
				}
			}
			
			if (numItemsLength < _listItemRenderers.length)
			{
				var listRenderersToRemove:Array = _listItemRenderers.splice(numItemsLength, _listItemRenderers.length - numItemsLength);
				for (i = 0; i < listRenderersToRemove.length; i++) 
				{
					freeItemRenderer(listRenderersToRemove[i]);
				}
			}
			
			_updatePositions = false;
			
			
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
				rect.width = _columnWidth * _columnCount + _columnsGap * (_columnCount - 1);
				rect.height = _rowHeight * _rowCount + _rowsGap * (_rowCount - 1);
			}
			
			updateMask = rect;
		}
		
		public function set columnCount(value:int):void
		{
			_columnCount = value;
			
			updateMaskRect();
			
			_updatePositions = true;
			update();
		}
		
		public function set columnWidth(value:int):void
		{
			_columnWidth = value;
			
			updateMaskRect();
		}
		
		public function set columnsGap(value:int):void
		{
			_columnsGap = value;
			
			updateMaskRect();
		}
		
		public function set rowCount(value:int):void
		{
			_rowCount = value;
			
			updateMaskRect();
			
			_updatePositions = true;
			update();
		}
		
		public function set rowHeight(value:int):void
		{
			_rowHeight = value;
			
			updateMaskRect();
		}
		
		public function set rowsGap(value:int):void
		{
			_rowsGap = value;
			
			updateMaskRect();
		}
	}
}