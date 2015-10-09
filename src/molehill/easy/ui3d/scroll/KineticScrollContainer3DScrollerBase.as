package molehill.easy.ui3d.scroll
{
	import easy.core.Direction;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	public class KineticScrollContainer3DScrollerBase extends Sprite3DContainer
	{
		protected var _scroller:InteractiveSprite3D;
		public function KineticScrollContainer3DScrollerBase()
		{
			super();
			
			_scroller = createScroller();
			_scroller.mouseEnabled = true;
			_scroller.buttonMode = true;
			addChild(_scroller);
		}
		
		protected var _size:Number = 1;
		public function get size():Number
		{
			return _size;
		}

		public function set size(value:Number):void
		{
			_size = value;
			
			resize();
		}
		
		protected function resize():void
		{
			updatePosition();
		}
		
		protected function createScroller():InteractiveSprite3D
		{
			return null;
		}
		
		protected var _stage:Stage;
		override protected function onAddedToScene():void
		{
			_scroller.addEventListener(Input3DMouseEvent.MOUSE_DOWN, onScrollerMouseDown);
			super.onAddedToScene();
			
			_stage = ApplicationBase.getInstance().stage;
		}
		
		private var _startHelperPoint:Point = new Point();
		private var _endHelperPoint:Point = new Point();
		private var _limitMousePoint:Point = new Point();
		private function onScrollerMouseDown(event:Input3DMouseEvent):void
		{
			if (_scrollContainer == null)
			{
				return;
			}
			
			_scrollContainer.startExternalScrolling();
			
			_endHelperPoint.setTo(
				_direction == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
				_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
			);
			
			if (_currentPosition == 0 || _currentPosition == 1)
			{
				_limitMousePoint.setTo(
					_direction == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
					_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
				);
			}
			
//			_endHelperPoint.setTo(
//				_direction == KineticScrollContainerDirection.VERTICAL ? 0 : _stage.mouseX,
//				_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : _stage.mouseY
//			);
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, int.MAX_VALUE);
			_stage.addEventListener(Event.ENTER_FRAME, onMouseEnterFrame);
//			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		private function onStageMouseUp(event:MouseEvent):void
		{
//			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			_stage.removeEventListener(Event.ENTER_FRAME, onMouseEnterFrame);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			
			if (_scrollContainer != null)
			{
				_scrollContainer.completeExternalScrolling();
			}
		}
		
		private function onMouseEnterFrame(event:Event):void
		{
			if (_scrollContainer == null)
			{
				return;
			}
			
			_startHelperPoint.copyFrom(_endHelperPoint);
			
			_endHelperPoint.setTo(
				_direction == KineticScrollContainerDirection.VERTICAL ? 0 : _stage.mouseX,
				_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : _stage.mouseY
			);
			
			var limitDiff:Number = _direction == KineticScrollContainerDirection.VERTICAL ? 
				_endHelperPoint.y - _limitMousePoint.y :
				_endHelperPoint.x - _limitMousePoint.x;
			
			if (_currentPosition == 0 && limitDiff < 0)
			{
				_startHelperPoint.copyFrom(_limitMousePoint);
				return;
			}
			if (_currentPosition == 1 && limitDiff > 0)
			{
				_startHelperPoint.copyFrom(_limitMousePoint);
				return;
			}
			
			
			var diff:Number = _direction == KineticScrollContainerDirection.VERTICAL ? 
				_endHelperPoint.y - _startHelperPoint.y :
				_endHelperPoint.x - _startHelperPoint.x;
			
			if (diff == 0)
			{
				return;
			}
			
			
			var scrollerPosition:Number = _direction == KineticScrollContainerDirection.VERTICAL ? _scroller.y : _scroller.x;
			var newPercent:Number = (scrollerPosition + diff) / _size;
			
			newPercent = Math.max(newPercent, 0);
			newPercent = Math.min(newPercent, 1);
			
			if (newPercent == _currentPosition)
			{
				return;
			}
			
			_scrollContainer.scrollToPercentPosition(newPercent);
			
			if (_stage != null && (_currentPosition == 0 || _currentPosition == 1))
			{
				var limitValue:Number;
				
				_limitMousePoint.setTo(
					_currentPosition == 0 ? 0 : _scroller.width,
					_currentPosition == 0 ? 0 : _scroller.height
				);
				
				_scroller.localToGlobal(_limitMousePoint);
				
				if (_direction == KineticScrollContainerDirection.VERTICAL)
				{
					_limitMousePoint.setTo(
						0,
						_currentPosition == 0 ? Math.max(_stage.mouseY, _limitMousePoint.y) : Math.min(_stage.mouseY, _limitMousePoint.y)
					);
				}
				else
				{
					_limitMousePoint.setTo(
						_currentPosition == 0 ? Math.max(_stage.mouseX, _limitMousePoint.x) : Math.min(_stage.mouseX, _limitMousePoint.x),
						0
					);
				}
			}
		}
		
		private function onStageMouseMove(event:MouseEvent):void
		{
			if (_scrollContainer == null)
			{
				return;
			}
			
			_startHelperPoint.copyFrom(_endHelperPoint);
			
			_endHelperPoint.setTo(
				_direction == KineticScrollContainerDirection.VERTICAL ? 0 : event.stageX,
				_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : event.stageY
			);
			
			var limitDiff:Number = _direction == KineticScrollContainerDirection.VERTICAL ? 
				_endHelperPoint.y - _limitMousePoint.y :
				_endHelperPoint.x - _limitMousePoint.x;
			
			if (_currentPosition == 0 && limitDiff < 0)
			{
				_startHelperPoint.copyFrom(_limitMousePoint);
				return;
			}
			if (_currentPosition == 1 && limitDiff > 0)
			{
				_startHelperPoint.copyFrom(_limitMousePoint);
				return;
			}
			
			var diff:Number = _direction == KineticScrollContainerDirection.VERTICAL ? 
				_endHelperPoint.y - _startHelperPoint.y :
				_endHelperPoint.x - _startHelperPoint.x;
			
			if (diff == 0)
			{
				return;
			}
			
			var scrollerPosition:Number = _direction == KineticScrollContainerDirection.VERTICAL ? _scroller.y : _scroller.x;
			var newPercent:Number = (scrollerPosition + diff) / _size;
			
			newPercent = Math.max(newPercent, 0);
			newPercent = Math.min(newPercent, 1);
			
			if (newPercent == _currentPosition)
			{
				return;
			}
			
			_scrollContainer.scrollToPercentPosition(newPercent);
			
			if (_stage != null && (_currentPosition == 0 || _currentPosition == 1))
			{
				var limitValue:Number;
				
				_limitMousePoint.setTo(
					_currentPosition == 0 ? 0 : _scroller.width,
					_currentPosition == 0 ? 0 : _scroller.height
				);
				
				_scroller.localToGlobal(_limitMousePoint);
				
				if (_direction == KineticScrollContainerDirection.VERTICAL)
				{
					_limitMousePoint.setTo(
						0,
						_currentPosition == 0 ? Math.max(event.stageY, _limitMousePoint.y) : Math.min(event.stageY, _limitMousePoint.y)
					);
				}
				else
				{
					_limitMousePoint.setTo(
						_currentPosition == 0 ? Math.max(event.stageX, _limitMousePoint.x) : Math.min(event.stageX, _limitMousePoint.x),
						0
					);
				}
			}
		}
		
		private var _scrollContainer:KineticScrollContainer3D;

		protected var _direction:String;
		internal function set scrollContainer(value:KineticScrollContainer3D):void
		{
			_scrollContainer = value;
			
			if (_scrollContainer != null)
			{
				_direction = _scrollContainer.scrollDirection;
				resize();
			}
		}
		
		internal function onDataChanged():void
		{
			updateOnListDataChanged();
		}
		
		protected function updateOnListDataChanged():void
		{
			// TODO Auto Generated method stub
			
		}
		
		protected var _currentPosition:Number;
		public function updatePosition():void
		{
			if (_scrollContainer == null)
			{
				return;
			}
			
			var percent:Number = Math.max(_scrollContainer.scrollPercentPosition, 0);
			percent = Math.min(percent, 1);
			var newPosition:int = int(percent * _size);
			
			_currentPosition = percent;
			
			_scroller.moveTo(
				_direction == KineticScrollContainerDirection.VERTICAL ? 0 : newPosition, 
				_direction == KineticScrollContainerDirection.HORIZONTAL ? 0 : newPosition
			);
		}
		
	}
}