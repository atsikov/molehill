package molehill.easy.ui3d.list
{
	import easy.core.Direction;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	public class EasyKineticList3DScrollerBase extends Sprite3DContainer
	{
		protected var _scroller:InteractiveSprite3D;
		public function EasyKineticList3DScrollerBase()
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
		private function onScrollerMouseDown(event:Input3DMouseEvent):void
		{
			if (_list == null)
			{
				return;
			}
			
			_list.startExternalScrolling();
			
			_endHelperPoint.setTo(
				_direction == Direction.HORIZONTAL ? 0 : event.stageX,
				_direction == Direction.VERTICAL ? 0 : event.stageY
			);
			_stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseUp, false, int.MAX_VALUE);
			_stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
		}
		
		private function onStageMouseUp(event:MouseEvent):void
		{
			_stage.removeEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove);
			_stage.removeEventListener(MouseEvent.MOUSE_UP, onStageMouseUp);
			
			if (_list != null)
			{
				_list.completeExternalScrolling();
			}
		}
		
		private function onStageMouseMove(event:MouseEvent):void
		{
			if (_list == null)
			{
				return;
			}
			
			_startHelperPoint.copyFrom(_endHelperPoint);
			
			_endHelperPoint.setTo(
				_direction == Direction.HORIZONTAL ? 0 : event.stageX,
				_direction == Direction.VERTICAL ? 0 : event.stageY
			);
			// TODO Auto-generated method stub
			
			
			var diff:Number = _direction == Direction.HORIZONTAL ? 
				_endHelperPoint.y - _startHelperPoint.y :
				_endHelperPoint.x - _startHelperPoint.x;
			
			if (diff == 0)
			{
				return;
			}
			
			var scrollerPosition:Number = _direction == Direction.HORIZONTAL ? _scroller.y : _scroller.x;
			var newPercent:Number = (scrollerPosition + diff) / _size;
			
			newPercent = Math.max(newPercent, 0);
			newPercent = Math.min(newPercent, 1);
			
			_list.scrollToPercentPosition(newPercent);
		}
		
		private var _list:EasyKineticList3D;

		protected var _direction:String;
		internal function set list(value:EasyKineticList3D):void
		{
			_list = value;
			
			if (_list != null)
			{
				_direction = _list.direction;
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
		
		public function updatePosition():void
		{
			if (_list == null)
			{
				return;
			}
			
			var percent:Number = Math.max(_list.scrollPercentPosition, 0);
			percent = Math.min(percent, 1);
			var newPosition:int = int(percent * _size);
			
			_scroller.moveTo(
				_direction == Direction.HORIZONTAL ? 0 : newPosition, 
				_direction == Direction.VERTICAL ? 0 : newPosition
			);
		}
		
	}
}