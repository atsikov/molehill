package molehill.easy.ui3d.scroll
{
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
	
	import org.goasap.interfaces.IPlayable;
	import org.opentween.OpenTween;
	
	import utils.DebugLogger;
	
	public class KineticScrollContainer3D extends Sprite3DContainer
	{
		protected var _container:UIComponent3D;
		public function get container():UIComponent3D
		{
			return _container;
		}

		protected var _containerCamera:CustomCamera;
		protected var _viewPort:Rectangle;
		protected var _scrollingMask:InteractiveSprite3D;
		
		public function KineticScrollContainer3D()
		{
			super();
			
			_scrollingMask = new InteractiveSprite3D();
			_scrollingMask.mouseEnabled = true;
			
			if (!TextureManager.getInstance().isTextureCreated("core_easy_scrolling_mask_texture"))
			{
				TextureManager.createTexture(
					new BitmapData(1, 1, false, 0),
					"core_easy_scrolling_mask_texture"
				);
			}
			
			_scrollingMask.setTexture("core_easy_scrolling_mask_texture");
			addChild(_scrollingMask);
			
			_containerCamera = new CustomCamera();
			
			_container = new UIComponent3D();
			_container.camera = _containerCamera;
			addChild(_container);
			
			_container.mask = _scrollingMask;
			
			_viewPort = new Rectangle();
		}
		
		public function set viewPort(value:Rectangle):void
		{
			_viewPort.copyFrom(value);
			_scrollingMask.moveTo(_viewPort.x, _viewPort.y);
			_scrollingMask.setSize(_viewPort.width, _viewPort.height);
		}
		
		protected var _scrollDirection:String = KineticScrollContainerDirection.VERTICAL;
		public function get scrollDirection():String
		{
			return _scrollDirection;
		}
		public function set scrollDirection(value:String):void
		{
			if (_scrollDirection == value)
				return;
			
			_scrollDirection = value;
		}
		
		private var _snapCameraToPixels:Boolean = true;
		public function get snapCameraToPixel():Boolean 
		{ 
			return _snapCameraToPixels; 
		}
		
		public function set snapCameraToPixel(value:Boolean):void
		{
			_snapCameraToPixels = value;
		}
		
		
		
		// ===== SCROLLING PARAMS ====== //
		private var FRICTION:Number = 0.92;
		private const FRICTION_BASE:Number = 0.92;
		private const FRICTION_FPS_COEFF:Number = 0.026;
		private const FRICTION_DEFAULT_FPS:Number = 24;
		
		private const LIST_VELOCITY_LENGTH:uint = 4;
		private const MIN_VELOCITY:Number = 2;
		private const MIN_DETECTED_VELOCITY:Number = 0.2;
		
		private const MIN_DIFF_TO_SCROLL:uint = 5;
		
		private const SPEED_COEFF:Number = 24;
		
		protected var ELASCTIC_SIZE:int = 60;
		
		public var COMPLETE_SCROLLING_ANIMATION_TIME:Number = 0.3;
		// =========================== //
		
		private var _diff:Point = new Point();
		private var _velocityX:Number = 0;
		private var _velocityY:Number = 0;
		private var _newPosition:Point = new Point();
		private var _lastPosition:Point = new Point();
		private var _newTime:uint = 0;
		private var _lastTime:uint = 0;
		private var _listVelocityX:Array = new Array();
		private var _listVelocityY:Array = new Array();
		
		private var _startPoint:Point = new Point();
		
		protected var _animation:IPlayable;
		
		protected var _stage:Stage;
		
		override protected function onAddedToScene():void
		{
			_container.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
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
			
			_container.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			_scrollingMask.removeEventListener(Input3DMouseEvent.MOUSE_DOWN, onItemsContainerMouseDown);
			
			_velocityX = 0;
			_velocityY = 0;
			
			onAnimationCompleted();
			
			stopAnimation();
		}
		
		protected function onScrollStarted():void
		{
			
		}
		
		protected function onScrollCompleted():void
		{
			
		}
		
		public function stopScrolling():void
		{
			_velocityX = 0;
			_velocityY = 0;
		}
		
		protected function onItemsContainerMouseDown(event:Input3DMouseEvent):void
		{
			stopAnimation();
			
			_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
			
			_listVelocityX.splice(0, _listVelocityX.length);
			_listVelocityY.splice(0, _listVelocityY.length);
			
			_startPoint.setTo(
				_scrollDirection == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
				_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
			);
			
			_lastTime = 0;
			_velocityX = 0;
			_velocityY = 0;
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, int.MAX_VALUE);
			
			_endHelperPoint.setTo(
				_scrollDirection == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
				_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
			);
			
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		//Scrolling on mouse move
		private var _startHelperPoint:Point = new Point();
		private var _endHelperPoint:Point = new Point();
		private function onStageMouseMove(event:MouseEvent):void
		{
			_startHelperPoint.x = _endHelperPoint.x;
			_startHelperPoint.y = _endHelperPoint.y;
			
			_endHelperPoint.setTo(
				_scrollDirection == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
				_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
			);
			
			if (!_scrollStarted)
			{
				var diff:Number = Point.distance(_startPoint, _endHelperPoint);
				
				if (Math.abs(diff) < MIN_DIFF_TO_SCROLL)
				{
					return;
				}
			}
			
			if (_lastTime == 0)
			{
				_scrollStarted = true;
				
				onScrollStarted();
				
				_lastTime = getTimer();
				_lastPosition.setTo(
					_scrollDirection == KineticScrollContainerDirection.VERTICAL ? 0 : _stage.mouseX,
					_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? 0 : _stage.mouseY
				);
				
				_stage.addEventListener(Event.ENTER_FRAME, onScrollEnterFrame);
			}
			
			scrollOn(_endHelperPoint.x - _startHelperPoint.x, _endHelperPoint.y - _startHelperPoint.y);
		}
		
		private function onScrollEnterFrame(event:Event):void
		{
			if (_stage == null)
			{
				_velocityX = 0;
				_velocityY = 0;
				return;
			}
			
			_newTime = getTimer();
			
			if (_newTime == _lastTime)
			{
				return;
			}
			
			_newPosition.setTo(
				_scrollDirection == KineticScrollContainerDirection.VERTICAL ? 0 : _stage.mouseX,
				_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? 0 : _stage.mouseY
			);
			
			_velocityX = (_newPosition.x - _lastPosition.x) / (_newTime - _lastTime);
			_velocityY = (_newPosition.y - _lastPosition.y) / (_newTime - _lastTime);
			
			_listVelocityX.push(_velocityX);
			_listVelocityY.push(_velocityY);
			
			if (_listVelocityX.length > LIST_VELOCITY_LENGTH)
			{
				_listVelocityX.shift();
			}
			if (_listVelocityY.length > LIST_VELOCITY_LENGTH)
			{
				_listVelocityY.shift();
			}
			
			_lastTime = _newTime;
			_lastPosition.copyFrom(_newPosition);
		}
		
		//Scroll on mouse release
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
			
			if (_listVelocityX.length == 0 && _lastTime != 0)
			{
				onScrollEnterFrame(null);
			}
			
			_velocityX = 0;
			_velocityY = 0;
			
			if (_listVelocityX.length == 0)
			{
				onKineticEnterFrame(null);
				return;
			}
			
			for (var i:int = 0; i < LIST_VELOCITY_LENGTH; i++) 
			{
				if (i < _listVelocityX.length)
				{
					_velocityX += _listVelocityX[i];
				}
				if (i < _listVelocityY.length)
				{
					_velocityY += _listVelocityY[i];
				}
			}
			
			_velocityX = _velocityX / _listVelocityX.length;
			_velocityY = _velocityY / _listVelocityY.length;
			
			if (Math.abs(_velocityX) < MIN_DETECTED_VELOCITY)
			{
				_velocityX = 0;
			}
			
			if (Math.abs(_velocityY) < MIN_DETECTED_VELOCITY)
			{
				_velocityY = 0;
			}
			
			if (_velocityX == 0 && _velocityY == 0)
			{
				onKineticEnterFrame(null);
				return;
			}
			
			if (_velocityX != 0 && Math.abs(_velocityX) < MIN_VELOCITY)
			{
				_velocityX = _velocityX < 0 ? -MIN_VELOCITY : MIN_VELOCITY;
			}
			
			if (_velocityY != 0 && Math.abs(_velocityY) < MIN_VELOCITY)
			{
				_velocityY = _velocityY < 0 ? -MIN_VELOCITY : MIN_VELOCITY;
			}
			
			_velocityX = _velocityX * SPEED_COEFF;
			_velocityY = _velocityY * SPEED_COEFF;
			
			_stage.addEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
		}
		
		private function onKineticEnterFrame(event:Event):void
		{
			var borderReached:Boolean = scrollOn(_velocityX, _velocityY);
			
			_velocityX *= FRICTION;
			_velocityY *= FRICTION;
			
			if (borderReached || (Math.abs(_velocityX) < 1 && Math.abs(_velocityY) < 1))
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
				completeScrolling();
			}
		}
		
		protected function scrollOn(diffX:Number, diffY:Number):Boolean
		{
			_containerCamera.scrollX -= diffX;
			_containerCamera.scrollY -= diffY;
			
			return validateBorders();
		}
		
		protected function validateBorders(scrollingCompleted:Boolean = false):Boolean
		{
			var borderReached:Boolean = false;
			
			if (validateLeftBorder())
			{
				borderReached = true;
			}
			else if (validateRightBorder())
			{
				borderReached = true;
			}
			
			if (validateTopBorder())
			{
				borderReached = true;
			}
			else if (validateBottomBorder())
			{
				borderReached = true;
			}
			
			if (scrollingCompleted)
			{
				onAnimationCompleted();
			}
			
			if (_scroller != null)
			{
				_scroller.updatePosition();
			}
			
			return borderReached;
		}
		
		protected function get itemsContainerWidth():Number
		{
			return _container.width;
		}
		
		protected function get itemsContainerHeight():Number
		{
			return _container.height;
		}
		
		private var _scrollStarted:Boolean;
		protected function completeScrolling(animate:Boolean = true):void
		{
			stopAnimation();
			
			_endHelperPoint.setTo(
				_containerCamera.scrollX,
				_containerCamera.scrollY
			);
			
			var borderReached:Boolean = checkCompleteScrollingPosition(_endHelperPoint);
			
			if (animate && borderReached)
			{
				_animation = OpenTween.go(
					_containerCamera,
					{
						scrollX : _endHelperPoint.x,
						scrollY : _endHelperPoint.y
					},
					COMPLETE_SCROLLING_ANIMATION_TIME,
					0,
					Linear.easeOut,
					validateBorders,
					completeScrollingTweenUpdate,
					[true]
				);
			}
			else
			{
				_containerCamera.scrollX = _endHelperPoint.x;
				_containerCamera.scrollY = _endHelperPoint.y;
				
				validateBorders(true);
			}
		}
		
		protected function completeScrollingTweenUpdate():void
		{
			if (_scroller != null)
			{
				_scroller.updatePosition();
			}
		}
		
		/**
		 * Check borders on scrolling completed. Returns true if border reached
		 * param @targetPoint target container mask scroll position point, would be modified if border reached
		 */
		protected function checkCompleteScrollingPosition(targetPoint:Point):Boolean
		{
			var borderReached:Boolean = false;
			
			if (_containerCamera.scrollX < leftBorder || itemsContainerWidth <= _scrollingMask.width)
			{
				targetPoint.x = leftBorder;
				borderReached = true;
			}
			else if (_containerCamera.scrollX > rightBorder)
			{
				targetPoint.x = rightBorder;
				borderReached = true;
			}
			
			if (_containerCamera.scrollY < topBorder || itemsContainerHeight <= _scrollingMask.height)
			{
				targetPoint.y = topBorder;
				borderReached = true;
			}
			else if (_containerCamera.scrollY > bottomBorder)
			{
				targetPoint.y = bottomBorder;
				borderReached = true;
			}
			
			return borderReached;
		}
		
		protected function stopAnimation():void
		{
			if (_animation != null)
			{
				_animation.stop();
			}
			
			if (_stage != null)
			{
				_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
			}
		}
		
		protected function onAnimationCompleted():void
		{
			if (_snapCameraToPixels)
			{
				_containerCamera.scrollX = int(_containerCamera.scrollX);
				_containerCamera.scrollY = int(_containerCamera.scrollY);
			}
			
			onScrollCompleted();
		}
		
		
		/* =================== */
		/* ===== BORDERS ===== */
		
		// ---- LEFT ---- //
		protected function validateLeftBorder():Boolean
		{
			if (_containerCamera.scrollX < leftBorder - ELASCTIC_SIZE)
			{
				_containerCamera.scrollX = leftBorder - ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get leftBorder():Number
		{
			return 0;
		}
		
		// ---- RIGHT ---- //
		protected function validateRightBorder():Boolean
		{
			if (_containerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
			{
				_containerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get rightBorder():Number
		{
			if (_container.width > _scrollingMask.width)
			{
				return _container.width - _scrollingMask.width - _scrollingMask.x + _rightGap;
			}
			else
			{
				return 0;
			}
		}
		
		private var _rightGap:Number = 0;
		public function get rightGap():Number 
		{ 
			return _rightGap; 
		}
		
		public function set rightGap(value:Number):void
		{
			_rightGap = value;
		}
		
		// ---- TOP ---- //
		protected function validateTopBorder():Boolean
		{
			if (_containerCamera.scrollY < topBorder - ELASCTIC_SIZE)
			{
				_containerCamera.scrollY = topBorder - ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get topBorder():Number
		{
			return 0;
		}
		
		// ---- BOTTOM ---- //
		protected function validateBottomBorder():Boolean
		{
			if (_containerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
			{
				_containerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get bottomBorder():Number
		{
			if (_container.height > _scrollingMask.height)
			{
				return _container.height - _scrollingMask.height - _scrollingMask.y + _bottomGap;
			}
			else
			{
				return 0;
			}
		}
		
		private var _bottomGap:Number = 0;
		public function get bottomGap():Number 
		{ 
			return _bottomGap; 
		}
		
		public function set bottomGap(value:Number):void
		{
			_bottomGap = value;
		}
		/* =================== */
		
		//==================
		// scroller interface
		//==================
		
		
		
		protected var _scroller:KineticScrollContainer3DScrollerBase;
		public function get scroller():KineticScrollContainer3DScrollerBase 
		{ 
			return _scroller; 
		}
		
		/**
		 * Would not work with FREE scroll direction
		 */
		public function set scroller(value:KineticScrollContainer3DScrollerBase):void
		{
			if (_scroller == value || _scrollDirection == KineticScrollContainerDirection.FREE)
				return;
			if (_scroller != null)
			{
				_scroller.scrollContainer = null;
			}
			
			_scroller = value;
			
			if (_scroller != null)
			{
				_scroller.scrollContainer = this;
			}
		}
		
		public function startExternalScrolling():void
		{
			onScrollStarted();
		}
		
		public function completeExternalScrolling():void
		{
			completeScrolling(true);
		}
		
		public function scrollToPercentPosition(position:Number):void
		{
			scrollOn(
				_scrollDirection == KineticScrollContainerDirection.HORIZONTAL ? _containerCamera.scrollX - (rightBorder - leftBorder) * position : 0,
				_scrollDirection == KineticScrollContainerDirection.VERTICAL ? _containerCamera.scrollY - (bottomBorder - topBorder) * position : 0
			);
		}
		
		public function get scrollPercentPosition():Number
		{
			if (_scrollDirection == KineticScrollContainerDirection.HORIZONTAL)
			{
				return _containerCamera.scrollX / (rightBorder - leftBorder);
			}
			
			return _containerCamera.scrollY / (_container.height + _bottomGap);
		}
	}
}