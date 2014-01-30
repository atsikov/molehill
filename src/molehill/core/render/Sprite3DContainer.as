package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;

	public class Sprite3DContainer extends InteractiveSprite3D
	{
		private var _listChildren:Vector.<Sprite3D>
		public function Sprite3DContainer()
		{
			_listChildren = new Vector.<Sprite3D>();
			localTreeRoot = new TreeNode(this);
		}
		
		override public function set blendMode(value:String):void
		{
			if (value == BlendMode.NORMAL)
			{
				value = null;
			}
			
			_blendMode = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child.blendMode = value;
			}
		}
		
		private var _staticBatching:Boolean = false;
		public function get staticBatching():Boolean
		{
			return _staticBatching;
		}
		
		public function set staticBatching(value:Boolean):void
		{
			_staticBatching = value;
		}
		
		private var _hashNodesByChild:Dictionary = new Dictionary();
		private function getNodeByChild(child:Sprite3D):TreeNode
		{
			return _hashNodesByChild[child];
		}
		
		public function addChild(child:Sprite3D):void
		{
			if (child.parent == this)
			{
				return;
			}
			
			if (child.parent != null)
			{
				child.parent.removeChild(child);
			}
			
			child._parent = this;
			child.setScene(_scene);
			
			if (_blendMode != null)
			{
				child.blendMode = _blendMode;
			}
			
			var node:TreeNode;
			if (child is Sprite3DContainer)
			{
				node = (child as Sprite3DContainer).localTreeRoot;
			}
			else
			{
				node = new TreeNode(child);
			}
			localTreeRoot.addNode(node);
			_hashNodesByChild[child] = node;
			_listChildren.push(child);
			
			if (_scene != null)
			{
				if (!_staticBatching)
				{
					_scene._needUpdateBatchers = true;
				}
				else
				{
					_scene.staticContainerChanged(this);
				}
			}
		}
		
		public function addChildAt(child:Sprite3D, index:int):void
		{
			if (child.parent != null)
			{
				child.parent.removeChild(child);
			}
			child._parent = this;
			child.setScene(_scene);
			
			if (_blendMode != null)
			{
				child.blendMode = _blendMode;
			}
			
			var node:TreeNode;
			if (child is Sprite3DContainer)
			{
				node = (child as Sprite3DContainer).localTreeRoot;
			}
			else
			{
				node = new TreeNode(child);
			}
			if (index == 0)
			{
				localTreeRoot.addAsFirstNode(node);
				_listChildren.splice(index, 0, child);
			}
			else if (index < _listChildren.length)
			{
				var prevNode:TreeNode = getNodeByChild(_listChildren[index - 1]);
				localTreeRoot.insertNodeAfter(prevNode, node);
				_listChildren.splice(index, 0, child);
			}
			else
			{
				localTreeRoot.addNode(node);
				_listChildren.push(child);
			}
			_hashNodesByChild[child] = node;
			
			if (_scene != null)
			{
				if (!_staticBatching)
				{
					_scene._needUpdateBatchers = true;
				}
				else
				{
					_scene.staticContainerChanged(this);
				}
			}
		}
		
		public function getChildAt(index:int):Sprite3D
		{
			return _listChildren[index];
		}
		
		public function getChildIndex(child:Sprite3D):int
		{
			return _listChildren.indexOf(child);
		}
		
		public function contains(child:Sprite3D):Boolean
		{
			return _hashNodesByChild[child] != null;
		}
		
		public function removeChild(child:Sprite3D):void
		{
			var node:TreeNode = getNodeByChild(child);
			localTreeRoot.removeNode(node);
			
			child.setScene(null);
			child._parent = null;
			_listChildren.splice(
				_listChildren.indexOf(child), 1
			);
			
			if (_scene != null)
			{
				if (!_staticBatching)
				{
					_scene._needUpdateBatchers = true;
				}
				else
				{
					_scene.staticContainerChanged(this);
				}
			}
			
			delete _hashNodesByChild[child];
		}
		
		public function removeChildAt(index:int):void
		{
			var child:Sprite3D = _listChildren[index];
			var node:TreeNode = getNodeByChild(child);
			localTreeRoot.removeNode(node);
			
			if (child is AnimatedSprite3D)
			{
				(child as AnimatedSprite3D).stop();
			}
			
			child.setScene(null);
			child._parent = null;
			_listChildren.splice(index, 1);
			
			if (_scene != null)
			{
				if (!_staticBatching)
				{
					_scene._needUpdateBatchers = true;
				}
				else
				{
					_scene.staticContainerChanged(this);
				}
			}
			
			delete _hashNodesByChild[child];
		}
		
		public function get children():Vector.<Sprite3D>
		{
			return _listChildren;
		}
		
		public function get numChildren():uint
		{
			return _listChildren.length;
		}
		
		override public function set visible(value:Boolean):void
		{
			super.visible = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child._visibilityChanged = _visibilityChanged;
			}
		}
		
		override internal function set hasChanged(value:Boolean):void
		{
			for each (var child:Sprite3D in _listChildren)
			{
				if (!(child is Sprite3DContainer) && child.hasChanged)
				{
					continue;
				}
				
				child.hasChanged = value;
			}
			
			super.hasChanged = value;
		}
		
		override public function hitTestPoint(point:Point):Boolean
		{
			if (!mouseEnabled)
			{
				return false;
			}
			
			var pointX:Number = point.x;
			var pointY:Number = point.y;
			for each (var child:Sprite3D in _listChildren)
			{
				if ((child is Sprite3DContainer) && !child.mouseEnabled)
				{
					continue;
				}
				
				if (child.hitTestCoords(pointX - _shiftX, pointY - _shiftY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		override internal function hitTestCoords(localX:Number, localY:Number):Boolean
		{
			if (!mouseEnabled)
			{
				return false;
			}
			
			for each (var child:Sprite3D in _listChildren)
			{
				if ((child is Sprite3DContainer) && !child.mouseEnabled)
				{
					continue;
				}
				
				if (child.hitTestCoords(localX - _shiftX, localY - _shiftY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function getObjectsUnderPoint(point:Point):Vector.<Sprite3D>
		{
			var childrenUnderPoint:Vector.<Sprite3D> = new Vector.<Sprite3D>();
			
			point.x -= _shiftX;
			point.y -= _shiftY;
			
			for each (var child:Sprite3D in _listChildren)
			{
				if (!child.mouseEnabled)
				{
					continue;
				}
				
				if (!child.visible)
				{
					continue;
				}
				
				if (child.hitTestPoint(point))
				{
					childrenUnderPoint.push(child);
				}
			}
			
			return childrenUnderPoint;
		}
		
		override internal function setScene(value:Scene3D):void
		{
			super.setScene(value);
			for each (var child:Sprite3D in _listChildren)
			{
				child.setScene(value);
			}
		}
		
		internal var localTreeRoot:TreeNode;
	}
}