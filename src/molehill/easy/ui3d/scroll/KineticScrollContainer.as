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
	
	import org.opentween.OpenTween;
	
	public class KineticScrollContainer extends Sprite3DContainer
	{
		public static const FREE:String = "free";
		public static const HORIZONTAL:String = "horizontal";
		public static const VERTICAL:String = "vertical";
		
		protected var _itemsContainer:UIComponent3D;
		public function get itemsContainer():UIComponent3D
		{
			return _itemsContainer;
		}

		protected var _itemsContainerCamera:CustomCamera;
		protected var _viewPort:Rectangle;
		private var _scrollingMask:InteractiveSprite3D;
		
		public function KineticScrollContainer()
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
			
			_itemsContainerCamera = new CustomCamera();
			
			_itemsContainer = new UIComponent3D();
			_itemsContainer.camera = _itemsContainerCamera;
			addChild(_itemsContainer);
			
			_itemsContainer.mask = _scrollingMask;
			
			_viewPort = new Rectangle();
		}
		
		public function set viewPort(value:Rectangle):void
		{
			_viewPort.copyFrom(value);
			_scrollingMask.moveTo(_viewPort.x, _viewPort.y);
			_scrollingMask.setSize(_viewPort.width, _viewPort.height);
		}
		
		protected var _scrollDirection:String = VERTICAL;
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
		
		private var _stage:Stage;
		
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
			
			_velocityX = 0;
			_velocityY = 0;
			
			onAnimationCompleted();
		}
		
		protected function onScrollStarted():void
		{
			
		}
		
		protected function onScrollCompleted():void
		{
			
		}
		
		private function onItemsContainerMouseDown(event:Input3DMouseEvent):void
		{
			_isAnimated = true;
			
			_stage.removeEventListener(Event.ENTER_FRAME, onKineticEnterFrame);
			
			_listVelocityX.splice(0, _listVelocityX.length);
			_listVelocityY.splice(0, _listVelocityY.length);
			
			_startPoint.setTo(
				_scrollDirection == VERTICAL ? 0 : event.stageX,
				_scrollDirection == HORIZONTAL ? 0 : event.stageY
			);
			
			_lastTime = 0;
			_velocityX = 0;
			_velocityY = 0;
			
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, int.MAX_VALUE);
			
			_endHelperPoint.setTo(
				_scrollDirection == VERTICAL ? 0 : event.stageX,
				_scrollDirection == HORIZONTAL ? 0 : event.stageY
			);
			
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		//Scrolling on mouse move
		private var _startHelperPoint:Point = new Point();
		private var _endHelperPoint:Point = new Point();
		private function onStageMouseMove(event:MouseEvent):void
		{
			_startHelperPoint.x = _startHelperPoint.x == _endHelperPoint.x ? _startHelperPoint.x : _endHelperPoint.x;
			_startHelperPoint.y = _startHelperPoint.y == _endHelperPoint.y ? _startHelperPoint.y : _endHelperPoint.y;
			
			_endHelperPoint.setTo(
				_scrollDirection == VERTICAL ? 0 : event.stageX,
				_scrollDirection == HORIZONTAL ? 0 : event.stageY
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
					_scrollDirection == VERTICAL ? 0 : _stage.mouseX,
					_scrollDirection == HORIZONTAL ? 0 : _stage.mouseY
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
				_stage.removeEventListener(Event.ENTER_FRAME, onScrollEnterFrame);
				return;
			}
			
			_newTime = getTimer();
			_newPosition.setTo(
				_scrollDirection == VERTICAL ? 0 : _stage.mouseX,
				_scrollDirection == HORIZONTAL ? 0 : _stage.mouseY
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
			
			if (_listVelocityX.length == 0)
			{
				moveToClosestLine();
				return;
			}
			
			_velocityX = 0;
			_velocityY = 0;
			
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
				moveToClosestLine();
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
				moveToClosestLine();
			}
		}
		
		private function scrollOn(diffX:Number, diffY:Number):Boolean
		{
			_itemsContainerCamera.scrollX -= diffX;
			_itemsContainerCamera.scrollY -= diffY;
			
			var borderReached:Boolean = false;
			
			if (checkLeftBorder())
			{
				borderReached = true;
			}
			else if (checkRightBorder())
			{
				borderReached = true;
			}
			
			if (checkTopBorder())
			{
				borderReached = true;
			}
			else if (checkBottomBorder())
			{
				borderReached = true;
			}
			
			return borderReached;
		}
		
		
		private var _isAnimated:Boolean;
		private var _scrollStarted:Boolean;
		private function moveToClosestLine():void
		{
			_endHelperPoint.setTo(
				_itemsContainerCamera.scrollX,
				_itemsContainerCamera.scrollY
			);
			
			if (_itemsContainerCamera.scrollX < leftBorder || _itemsContainer.width <= _scrollingMask.width)
			{
				_endHelperPoint.x = leftBorder;
			}
			else if (_itemsContainerCamera.scrollX > rightBorder)
			{
				_endHelperPoint.x = rightBorder;
			}
			
			if (_itemsContainerCamera.scrollY < topBorder || _itemsContainer.height <= _scrollingMask.height)
			{
				_endHelperPoint.y = topBorder;
			}
			else if (_itemsContainerCamera.scrollY > bottomBorder)
			{
				_endHelperPoint.y = bottomBorder;
			}
			
			OpenTween.go(
				_itemsContainerCamera,
				{
					scrollX : _endHelperPoint.x,
					scrollY : _endHelperPoint.y
				},
				0.3,
				0,
				Linear.easeOut,
				onAnimationCompleted
			);
		}
		
		private function onAnimationCompleted():void
		{
			if (_snapCameraToPixels)
			{
				_itemsContainerCamera.scrollX = int(_itemsContainerCamera.scrollX);
				_itemsContainerCamera.scrollY = int(_itemsContainerCamera.scrollY);
			}
			
			onScrollCompleted();
		}
		
		
		/* =================== */
		/* ===== BORDERS ===== */
		
		// ---- LEFT ---- //
		protected function checkLeftBorder():Boolean
		{
			if (_itemsContainerCamera.scrollX < leftBorder - ELASCTIC_SIZE)
			{
				_itemsContainerCamera.scrollX = leftBorder - ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get leftBorder():Number
		{
			return 0;
		}
		
		// ---- RIGHT ---- //
		protected function checkRightBorder():Boolean
		{
			if (_itemsContainerCamera.scrollX > rightBorder + ELASCTIC_SIZE)
			{
				_itemsContainerCamera.scrollX = rightBorder + ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get rightBorder():Number
		{
			if (_itemsContainer.width > _scrollingMask.width)
			{
				return _itemsContainer.width - _scrollingMask.width + _rightGap;
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
		protected function checkTopBorder():Boolean
		{
			if (_itemsContainerCamera.scrollY < topBorder - ELASCTIC_SIZE)
			{
				_itemsContainerCamera.scrollY = topBorder - ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get topBorder():Number
		{
			return 0;
		}
		
		// ---- BOTTOM ---- //
		protected function checkBottomBorder():Boolean
		{
			if (_itemsContainerCamera.scrollY > bottomBorder + ELASCTIC_SIZE)
			{
				_itemsContainerCamera.scrollY = bottomBorder + ELASCTIC_SIZE;
				return true;
			}
			
			return false;
		}
		
		protected function get bottomBorder():Number
		{
			if (_itemsContainer.height > _scrollingMask.height)
			{
				return _itemsContainer.height - _scrollingMask.height + _bottomGap;
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
	}
}