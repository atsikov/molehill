package molehill.core.render
{
	import easy.collections.BinarySearchTree;
	import easy.collections.TreeNode;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import molehill.core.render.shader.Shader3D;

	public class Sprite3DContainer extends InteractiveSprite3D
	{
		private var _listChildren:Vector.<Sprite3D>
		
		private var _childCoordsTLx:BinarySearchTree;
		private var _childCoordsTLy:BinarySearchTree;
		private var _childCoordsBRx:BinarySearchTree;
		private var _childCoordsBRy:BinarySearchTree;
		
		public function Sprite3DContainer()
		{
			_listChildren = new Vector.<Sprite3D>();
			localTreeRoot = new TreeNode(this);

			_childCoordsTLx = new BinarySearchTree();
			_childCoordsTLy = new BinarySearchTree();
			_childCoordsBRx = new BinarySearchTree();
			_childCoordsBRy = new BinarySearchTree();
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
		
		private var _hashNodesByChild:Dictionary = new Dictionary();
		private function getNodeByChild(child:Sprite3D):TreeNode
		{
			return _hashNodesByChild[child];
		}
		
		public function addChild(child:Sprite3D):Sprite3D
		{
			if (child.parent === this)
			{
				return child;
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
			
			var currentShader:Shader3D = shader;
			if (currentShader != null)
			{
				child.shader = currentShader;
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
			_numChildren++;
			if (!(child is Sprite3DContainer)) 
			{
				_numSimpleChildren++;
			}
			treeStructureChanged = true;
			
			if (_scene != null)
			{
				_scene._needUpdateBatchers = true;
			}
			
			child.parentTLxNode = _childCoordsTLx.insertElement(child, child.x);
			child.parentTLyNode = _childCoordsTLy.insertElement(child, child.y);
			child.parentBRxNode = _childCoordsBRx.insertElement(child, child.x + child.width);
			child.parentBRyNode = _childCoordsBRy.insertElement(child, child.y + child.height);
			
			child.updateParentShiftAndScale();
			//updateNumTotalChildren(child);
			
			return child;
		}
		
		public function addChildAt(child:Sprite3D, index:int):Sprite3D
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
			_numChildren++;
			if (!(child is Sprite3DContainer)) 
			{
				_numSimpleChildren++;
			}
			treeStructureChanged = true;
			
			if (_scene != null)
			{
				_scene._needUpdateBatchers = true;
			}
			
			child.parentTLxNode = _childCoordsTLx.insertElement(child, child.x);
			child.parentTLyNode = _childCoordsTLy.insertElement(child, child.y);
			child.parentBRxNode = _childCoordsBRx.insertElement(child, child.x + child.width);
			child.parentBRyNode = _childCoordsBRy.insertElement(child, child.y + child.height);
			
			child.updateParentShiftAndScale();
			updateNumTotalChildren(child);
			
			return child;
		}
		
		private var _containerX:int = 0;
		private var _containerY:int = 0;
		private var _containerRight:int = 0;
		private var _containerBottom:int = 0;
		internal function updateDimensions(child:Sprite3D):void
		{
			if (child is Sprite3DContainer)
			{
				var container:Sprite3DContainer = child as Sprite3DContainer;
				if (container._containerX < _containerX)
				{
					_containerX = container._containerX;
				}
				if (container._containerY < _containerY)
				{
					_containerY = container._containerY;
				}
				if (container._containerRight < _containerRight)
				{
					_containerRight = container._containerRight;
				}
				if (container._containerBottom > _containerBottom)
				{
					_containerBottom = container._containerBottom;
				}
			}
			else
			{
				if (child._shiftX + child._parentShiftX < _containerX)
				{
					_containerX = child._shiftX + child._parentShiftX;
				}
				if (child._shiftY + child._parentShiftY < _containerY)
				{
					_containerY = child._shiftY + child._parentShiftY;
				}
				if (child._shiftX + child._parentShiftX + child._cachedWidth > _containerRight)
				{
					_containerRight = child._shiftX + child._cachedWidth + child._parentShiftX;
				}
				if (child._shiftY + child._parentShiftY + child._cachedHeight > _containerBottom)
				{
					_containerBottom = child._shiftY + child._cachedHeight + child._parentShiftY;
				}
			}
		}
		
		private function updateAllDimensions(node:TreeNode = null):void
		{
			return;
			
			if (localTreeRoot == null)
			{
				_containerX = int.MAX_VALUE;
				_containerY = int.MAX_VALUE;
				_containerBottom = int.MIN_VALUE;
				_containerRight = int.MIN_VALUE;
			}
			
			var node:TreeNode = node == null ? localTreeRoot.firstChild : node.firstChild;
			while (node != null)
			{
				if (node.hasChildren)
				{
					updateAllDimensions(node);
				}
				else
				{
					updateDimensions(node.value as Sprite3D);
				}
				
				node = node.nextSibling;
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
		
		public function getChildAbsoluteIndex(child:Sprite3D):int
		{
			var index:int = 0;
			var found:Boolean = false;
			for (var i:int = 0; i < _listChildren.length; i++)
			{
				var candidate:Sprite3D = _listChildren[i];
				if (candidate === child)
				{
					found = true;
					break;
				}
				else
				{
					if (candidate is Sprite3DContainer)
					{
						var innerIndex:int = (candidate as Sprite3DContainer).getChildAbsoluteIndex(child);
						if (innerIndex == -1)
						{
							index += (candidate as Sprite3DContainer).numTotalChildren;
						}
						else
						{
							index += innerIndex;
							found = true;
							break;
						}
					}
				}
			}
			
			return found ? index : -1;
		}
		
		public function contains(child:Sprite3D):Boolean
		{
			return _hashNodesByChild[child] != null;
		}
		
		public function removeChild(child:Sprite3D):Sprite3D
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
				_scene._needUpdateBatchers = true;
			}
			
			delete _hashNodesByChild[child];
			_numChildren--;
			if (!(child is Sprite3DContainer)) 
			{
				_numSimpleChildren--;
			}
			treeStructureChanged = true;
			
			_childCoordsTLx.removeNode(child.parentTLxNode);
			_childCoordsTLy.removeNode(child.parentTLyNode);
			_childCoordsBRx.removeNode(child.parentBRxNode);
			_childCoordsBRy.removeNode(child.parentBRyNode);
			
			child.parentTLxNode = null;
			child.parentTLyNode = null;
			child.parentBRxNode = null;
			child.parentBRyNode = null;
			
			updateAllDimensions();
			
			updateNumTotalChildren(child, false);
			
			return child;
		}
		
		public function removeChildAt(index:int):Sprite3D
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
				_scene._needUpdateBatchers = true;
			}
			
			delete _hashNodesByChild[child];
			_numChildren--;
			if (!(child is Sprite3DContainer)) 
			{
				_numSimpleChildren--;
			}
			treeStructureChanged = true;
			
			_childCoordsTLx.removeNode(child.parentTLxNode);
			_childCoordsTLy.removeNode(child.parentTLyNode);
			_childCoordsBRx.removeNode(child.parentBRxNode);
			_childCoordsBRy.removeNode(child.parentBRyNode);
			
			child.parentTLxNode = null;
			child.parentTLyNode = null;
			child.parentBRxNode = null;
			child.parentBRyNode = null;
			
			updateAllDimensions();
			
			updateNumTotalChildren(child, false);
			
			return child;
		}
		
		private var _numChildren:uint = 0;
		private var _numSimpleChildren:uint = 0;
		// number of all child instances, both Sprites and Containers
		public function get children():Vector.<Sprite3D>
		{
			return _listChildren;
		}
		
		public function get numChildren():uint
		{
			return _numChildren;
		}
		
		// number of Sprite3D instances, for batch update purposes only
		internal function get numSimpleChildren():uint
		{
			return _numSimpleChildren;
		}
		
		private var _numTotalChildren:uint;
		private function updateNumTotalChildren(child:Sprite3D, increment:Boolean = true):void
		{
			var delta:uint = 0;
			if (!(child is Sprite3DContainer))
			{
				delta = 1;
			}
			else
			{
				var container:Sprite3DContainer = child as Sprite3DContainer;
				for (var i:int = 0; i < container.numChildren; i++)
				{
					var nextChild:Sprite3D = container.getChildAt(i);
					delta += nextChild is Sprite3DContainer ? (nextChild as Sprite3DContainer).numTotalChildren : 1;
				}
			}
			
			if (increment)
			{
				_numTotalChildren += delta;
			}
			else
			{
				_numTotalChildren -= delta;
			}
			
			//InputManager.getInstance().sortListeners();
		}
		
		public function get numTotalChildren():uint
		{
			return _numTotalChildren;
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
		
		internal var textureAtlasChanged:Boolean = false;
		internal var treeStructureChanged:Boolean = false;
		internal var scrollRectAdded:Boolean = false;
		
		override public function hitTestPoint(point:Point):Boolean
		{
			var pointX:Number = point.x;
			var pointY:Number = point.y;
			
			if (pointX - _shiftX * _parentScaleX < _containerX ||
				pointY - _shiftY * _parentScaleY < _containerY ||
				pointX - _shiftX * _parentScaleX > _containerRight ||
				pointY - _shiftY * _parentScaleY > _containerBottom
			)
			{
				return false;
			}
			
			for each (var child:Sprite3D in _listChildren)
			{
				if (child.hitTestCoords(pointX - _shiftX * _parentScaleX, pointY - _shiftY * _parentScaleY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		override internal function hitTestCoords(localX:Number, localY:Number):Boolean
		{
			for each (var child:Sprite3D in _listChildren)
			{
				if (child.hitTestCoords(localX - _shiftX, localY - _shiftY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function getObjectsUnderPoint(point:Point, list:Vector.<Sprite3D> = null):Vector.<Sprite3D>
		{
			var childrenUnderPoint:Vector.<Sprite3D> = list == null ? new Vector.<Sprite3D>() : list;
			
			point.x -= _shiftX * _parentScaleX;
			point.y -= _shiftY * _parentScaleY;
			
			for (var i:int = 0; i < _listChildren.length; i++)
			{
				var child:Sprite3D = _listChildren[i];
				if (!child.visible)
				{
					continue;
				}
				
				if (child is Sprite3DContainer)
				{
					var container:Sprite3DContainer = child as Sprite3DContainer;
					if (container.scrollRect != null)
					{
						point.x += container.scrollRect.x;
						point.y += container.scrollRect.y;
					}
					
					if (container.hitTestPoint(point))
					{
						//childrenUnderPoint.push(container);
						container.getObjectsUnderPoint(point, childrenUnderPoint);
					}
					
					if (container.scrollRect != null)
					{
						point.x -= container.scrollRect.x;
						point.y -= container.scrollRect.y;
					}
				}
				else if (child.hitTestPoint(point))
				{
					childrenUnderPoint.push(child);
				}
			}
			
			point.x += _shiftX * _parentScaleX;
			point.y += _shiftY * _parentScaleY;
			
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
		
		override public function set isBackground(value:Boolean):void
		{
			super.isBackground = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child.isBackground = value;
			}
		}
		
		override public function get width():Number
		{
			return _containerRight - _containerX;
		}
		
		override public function get height():Number
		{
			return _containerBottom - _containerY;
		}
		
		private var _scrollRect:Rectangle;
		public function get scrollRect():Rectangle
		{
			return _scrollRect;
		}
		
		public function set scrollRect(value:Rectangle):void
		{
			if (_scrollRect == null)
			{
				_scrollRect = value.clone();
				_scene._needUpdateBatchers = true;
				scrollRectAdded = true;
			}
			else
			{
				_scrollRect.x = value.x;
				_scrollRect.y = value.y;
				_scrollRect.width = value.width;
				_scrollRect.height = value.height;
			}
		}
	}
}