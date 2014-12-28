package molehill.easy.ui3d.hint
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.setTimeout;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;

	public class HintManager3D
	{
		static private var _instance:HintManager3D;
		static public function getInstance():HintManager3D
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new HintManager3D();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		static private var _allowInstantion:Boolean = false;
		public function HintManager3D()
		{
			if (!_allowInstantion)
			{
				throw new Error('Use HintManager::getInstance()');
			}
		}
		
		private var _enabled:Boolean = true;
		public function get enabled():Boolean
		{
			return _enabled;
		}
		public function set enabled(value:Boolean):void
		{
			_enabled = value;
		}
		
		public function get hintLayer():Sprite3DContainer
		{
			return _hintLayer;
		}
		
		public function set hintLayer(value:Sprite3DContainer):void
		{
			_hintLayer = value;
		}
		
		private var _hintLayer:Sprite3DContainer = new Sprite3DContainer();
		
		public function hideAll():void
		{
			if(_hintCandidate != null)
			{
				hideHint(_hintCandidate);
			}
		}
		
		private var _contentRegion:Rectangle = new Rectangle(0, 0, 607, 590);
		public function get contentRegion():Rectangle
		{
			return _contentRegion;
		}
		public function set contentRegion(value:Rectangle):void
		{
			_contentRegion = value;
		}
		
		
		private function onHintableRollOver(event:Input3DMouseEvent):void
		{
			if (!_enabled)
				return;
			
			var target:InteractiveSprite3D = event.currentTarget as InteractiveSprite3D;
			
			target.removeEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			target.addEventListener(Input3DMouseEvent.MOUSE_OUT, onHintableRollOut);
			
			showHint(target);
		}
		
		private function onHintableRollOut(event:Input3DMouseEvent):void
		{
			var target:InteractiveSprite3D = event.currentTarget as InteractiveSprite3D;
			hideHint(target);
			
			target.removeEventListener(Input3DMouseEvent.MOUSE_MOVE, onStageMouseMove);
			
			target.addEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			target.removeEventListener(Input3DMouseEvent.MOUSE_OUT, onHintableRollOut);
		}
		
		private function onStageMouseMove(event:Input3DMouseEvent):void
		{
			if (_showedHint != null)
			{
				arrangeCustomHintToCursor(_showedHint);
			}
		}
		
		static private var _hintsFollowCursor:Boolean = false;
		public static function get hintsFollowCursor():Boolean
		{
			return _hintsFollowCursor;
		}
		public static function set hintsFollowCursor(value:Boolean):void
		{
			_hintsFollowCursor = value;
		}
		
		static private const HINTS_OFFSET_X:uint = 10;
		static private const HINTS_OFFSET_Y:uint = 10;
		
		private var _timeoutShowDelay:uint = 0;
		
		private var _hintCandidate:InteractiveSprite3D;
		
		private var _showedHint:Sprite3D;
		
		private function showHint(target:InteractiveSprite3D):void
		{
			if (_hintCandidate != null && _hintCandidate !== target)
			{
				hideHint(_hintCandidate);
			}
			
			_hintCandidate = target;
			
			if (_timeoutShowDelay == 0)
			{
				_timeoutShowDelay = setTimeout(doShowHint, 300);
			}
		}
		
		private function hideHint(target:InteractiveSprite3D):void
		{
			if (_hintCandidate === target)
			{
				_hintCandidate = null;
				if(_showedHint != null && _showedHint.parent != null)
				{
					_showedHint.parent.removeChild(_showedHint);
				}
			}
		}
		
		private function doShowHint():void
		{
			_timeoutShowDelay = 0;
			if (_hintCandidate == null)
			{
				return;
			}
			if (_showedHint != null)
			{
				if ( _hintLayer.contains(_showedHint) )
				{
					_hintLayer.removeChild(_showedHint);
				}
				_showedHint = null;
			}
			
			_showedHint = createHint();
			
			if (_showedHint == null)
			{
				return;
			}

			if (hintsFollowCursor)
			{
				_hintCandidate.addEventListener(Input3DMouseEvent.MOUSE_MOVE, onStageMouseMove);
			}
			
			_hintLayer.addChild(_showedHint);
		}
		
		private function createHint():Sprite3D
		{
			var point:Point = new Point(0, 0);
			_hintCandidate.localToGlobal(point);
			_hintLayer.globalToLocal(point);
			
			var targetRegion:Rectangle = new Rectangle(
				point.x, 
				point.y,
				_hintCandidate.width,
				_hintCandidate.height
			);
			
			var hintRenderer:ICustomHintRenderer3D = getCustomHintByTarget(_hintCandidate);
			if (hintRenderer != null)
			{
				var hintData:*;
				if (_hintCandidate is ICustomHintable3D && _staticHintDataByTarget[_hintCandidate] == null)
				{
					hintData = (_hintCandidate as ICustomHintable3D).hintData;
				}
				else
				{
					hintData = _staticHintDataByTarget[_hintCandidate];
				}
				hintRenderer.hintData = hintData;
				hintRenderer.update();
				
				
				if (hintsFollowCursor)
				{
					arrangeCustomHintToCursor(hintRenderer as Sprite3D);
				}
				else
				{
					arrangeCustomHint(targetRegion, hintRenderer);
				}

				
				return hintRenderer as Sprite3D;
			}
			
			return null;
		}
		
		/*** ------------- ***/
		/***  CUSTOM HINT  ***/
		/*** ------------- ***/
		
		public function registerCustomHint(target:ICustomHintable3D, hintRendererClass:Class):void
		{
			if ( _classByTarget[target] == null)
			{
				target.addEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			}
			
			if ((target as InteractiveSprite3D).hasMouseOver)
			{
				showHint(target as InteractiveSprite3D);
			}
			
			_classByTarget[target] = hintRendererClass;
		}
		
		public function unregisterCustomHint(target:ICustomHintable3D):void
		{
			target.removeEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			target.removeEventListener(Input3DMouseEvent.MOUSE_OUT, onHintableRollOut);
			
			hideHint(target as InteractiveSprite3D);
			
			delete _classByTarget[target];
		}
		
		public var targetPadding:int = 0;
		
		private function arrangeCustomHint(targetRegion:Rectangle, hint:ICustomHintRenderer3D):void
		{
			var isTop:Boolean = targetRegion.top - _contentRegion.top - targetPadding > hint.height;
			
			if (isTop)
			{
				hint.y = int(targetRegion.y - targetPadding - hint.height);
			}
			else if(hint.alwaysTop)
			{
				hint.y = _contentRegion.top;
			}
			else
			{
				hint.y = int(targetRegion.bottom + targetPadding);
			}
			hint.x = int(targetRegion.x + (targetRegion.width - hint.width) * .5);
			if (hint.x < _contentRegion.left)
			{
				hint.x = int(_contentRegion.left);
			}
			if(hint.x + hint.width > _contentRegion.right)
			{
				hint.x = int(_contentRegion.right - hint.width);
			}
			hint.setTargetBounds(new Rectangle(
				targetRegion.x - hint.x,
				targetRegion.y - hint.y,
				targetRegion.width,
				targetRegion.height
			));
		}
		
		private function arrangeCustomHintToCursor(hint:Sprite3D):void
		{
			var fixedX:Boolean = true;
			
			var minX:Number = Math.ceil(_contentRegion.left);
			var maxX:Number = int(_contentRegion.right - hint.width);
			
			var pointMouse:Point = new Point(ApplicationBase.getInstance().stage.mouseX, ApplicationBase.getInstance().stage.mouseY);
			_hintLayer.globalToLocal(pointMouse);
			
			hint.x = int(pointMouse.x + HINTS_OFFSET_X);
			if (hint.x > maxX)
			{
				hint.x = int(pointMouse.x - hint.width - HINTS_OFFSET_X);
				if (hint.x < minX)
				{
					hint.x = Math.max(minX, Math.min(maxX, hint.x));
					fixedX = false;
				}
			}
			
			var minY:Number = Math.ceil(_contentRegion.top);
			var maxY:Number = int(_contentRegion.bottom - hint.height);
			hint.y = int(pointMouse.y + HINTS_OFFSET_Y);
			if (hint.y > maxY)
			{
				hint.y = int(pointMouse.y - hint.height - HINTS_OFFSET_Y);
				if (hint.y < minY && fixedX)
				{
					hint.y = Math.max(minY, Math.min(maxY, hint.y));
				}
			}
		}
		
		private var _classByTarget:Dictionary = new Dictionary();
		
		private var _instanceByClass:Dictionary = new Dictionary();
		
		private function getCustomHintByTarget(target:InteractiveSprite3D):ICustomHintRenderer3D
		{
			if (target == null)
			{
				return null;
			}
			var clazz:Class = _classByTarget[target];
			if (clazz == null)
			{
				return null;
			}
			var hint:ICustomHintRenderer3D = _instanceByClass[clazz];
			if (hint == null)
			{
				hint = new clazz();
				_instanceByClass[clazz] = hint;
			}
			return hint;
		}
		
		/*** -------------------------- ***/
		/***     STATIC CUSTOM HINT     ***/
		/*** -------------------------- ***/
		
		private var _staticHintDataByTarget:Dictionary = new Dictionary();
		
		public function registerStaticCustomHint(
			target:InteractiveSprite3D, hintData:*, hintRendererClass:Class
		):void
		{
			target.addEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			_classByTarget[target] = hintRendererClass;
			_staticHintDataByTarget[target] = hintData;
			
			if (target.hasMouseOver)
			{
				showHint(target);
			}
		}
		
		public function unregisterStaticCustomHint(target:InteractiveSprite3D):void
		{
			hideHint(target);
			delete _classByTarget[target];
			delete _staticHintDataByTarget[target];
			target.removeEventListener(Input3DMouseEvent.MOUSE_OVER, onHintableRollOver);
			target.removeEventListener(Input3DMouseEvent.MOUSE_OUT, onHintableRollOut);
		}
	}
}