package molehill.core.sprite
{
	import easy.collections.BinarySearchTree;
	import easy.collections.TreeNode;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.BlendMode;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	
	use namespace molehill_internal;

	public class Sprite3DContainer extends InteractiveSprite3D
	{
		private var _listChildren:Vector.<Sprite3D>
		
		private var _childCoordsX0:BinarySearchTree;
		private var _childCoordsY0:BinarySearchTree;
		private var _childCoordsX1:BinarySearchTree;
		private var _childCoordsY1:BinarySearchTree;
		private var _childCoordsX2:BinarySearchTree;
		private var _childCoordsY2:BinarySearchTree;
		private var _childCoordsX3:BinarySearchTree;
		private var _childCoordsY3:BinarySearchTree;
		
		public function Sprite3DContainer()
		{
			_listChildren = new Vector.<Sprite3D>();
			localTreeRoot = new TreeNode(this);

			_childCoordsX0 = new BinarySearchTree();
			_childCoordsY0 = new BinarySearchTree();
			_childCoordsX1 = new BinarySearchTree();
			_childCoordsY1 = new BinarySearchTree();
			_childCoordsX2 = new BinarySearchTree();
			_childCoordsY2 = new BinarySearchTree();
			_childCoordsX3 = new BinarySearchTree();
			_childCoordsY3 = new BinarySearchTree();
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
			
			child.parentX0Node = _childCoordsX0.insertElement(child, child._x0);
			child.parentY0Node = _childCoordsY0.insertElement(child, child._y0);
			
			child.parentX1Node = _childCoordsX1.insertElement(child, child._x1);
			child.parentY1Node = _childCoordsY1.insertElement(child, child._y1);
			
			child.parentX2Node = _childCoordsX2.insertElement(child, child._x2);
			child.parentY2Node = _childCoordsY2.insertElement(child, child._y2);
			
			child.parentX3Node = _childCoordsX3.insertElement(child, child._x3);
			child.parentY3Node = _childCoordsY3.insertElement(child, child._y3);
			
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
			
			child.parentX0Node = _childCoordsX0.insertElement(child, child._x0);
			child.parentY0Node = _childCoordsY0.insertElement(child, child._y0);
			
			child.parentX1Node = _childCoordsX1.insertElement(child, child._x1);
			child.parentY1Node = _childCoordsY1.insertElement(child, child._y1);
			
			child.parentX2Node = _childCoordsX2.insertElement(child, child._x2);
			child.parentY2Node = _childCoordsY2.insertElement(child, child._y2);
			
			child.parentX3Node = _childCoordsX3.insertElement(child, child._x3);
			child.parentY3Node = _childCoordsY3.insertElement(child, child._y3);
			
			child.updateParentShiftAndScale();
			updateNumTotalChildren(child);
			
			return child;
		}
		
		private var _containerX:int = 0;
		private var _containerY:int = 0;
		private var _containerRight:int = 0;
		private var _containerBottom:int = 0;
		molehill_internal function updateDimensions(child:Sprite3D):void
		{
			
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
			
			_childCoordsX0.removeNode(child.parentX0Node);
			_childCoordsY0.removeNode(child.parentY0Node);
			_childCoordsX1.removeNode(child.parentX1Node);
			_childCoordsY1.removeNode(child.parentY1Node);
			_childCoordsX2.removeNode(child.parentX2Node);
			_childCoordsY2.removeNode(child.parentY2Node);
			_childCoordsX3.removeNode(child.parentX3Node);
			_childCoordsY3.removeNode(child.parentY3Node);
			
			child.parentX0Node = null;
			child.parentY0Node = null;
			child.parentX1Node = null;
			child.parentY1Node = null;
			child.parentX2Node = null;
			child.parentY2Node = null;
			child.parentX3Node = null;
			child.parentY3Node = null;
			
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
			
			_childCoordsX0.removeNode(child.parentX0Node);
			_childCoordsY0.removeNode(child.parentY0Node);
			_childCoordsX1.removeNode(child.parentX1Node);
			_childCoordsY1.removeNode(child.parentY1Node);
			_childCoordsX2.removeNode(child.parentX2Node);
			_childCoordsY2.removeNode(child.parentY2Node);
			_childCoordsX3.removeNode(child.parentX3Node);
			_childCoordsY3.removeNode(child.parentY3Node);
			
			child.parentX0Node = null;
			child.parentY0Node = null;
			child.parentX1Node = null;
			child.parentY1Node = null;
			child.parentX2Node = null;
			child.parentY2Node = null;
			child.parentX3Node = null;
			child.parentY3Node = null;
			
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
		molehill_internal function get numSimpleChildren():uint
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
		
		override molehill_internal function set hasChanged(value:Boolean):void
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
		
		molehill_internal var textureAtlasChanged:Boolean = false;
		molehill_internal var treeStructureChanged:Boolean = false;
		molehill_internal var scrollRectAdded:Boolean = false;
		
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
		
		override molehill_internal function hitTestCoords(localX:Number, localY:Number):Boolean
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
		
		override molehill_internal function setScene(value:Scene3D):void
		{
			super.setScene(value);
			for each (var child:Sprite3D in _listChildren)
			{
				child.setScene(value);
			}
		}
		
		molehill_internal var localTreeRoot:TreeNode;
		
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
		
		// cached parent properties
		override molehill_internal function set parentShiftX(value:Number):void
		{
			super.parentShiftX = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = value + _shiftX * _scaleX;
			}
		}
		
		override molehill_internal function set parentShiftY(value:Number):void
		{
			super.parentShiftY = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = value + _shiftY * _scaleY;
			}
		}
		
		override molehill_internal function set parentShiftZ(value:Number):void
		{
			super.parentShiftZ = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftZ = value + _shiftZ;
			}
		}
		
		override molehill_internal function set parentScaleX(value:Number):void
		{
			super.parentScaleX = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = value * _scaleX;
			}
		}
		
		override molehill_internal function set parentScaleY(value:Number):void
		{
			super.parentScaleY = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleY = value * _scaleY;
			}
		}
		
		override molehill_internal function set parentRed(value:Number):void
		{
			super.parentRed = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRed = value * _redMultiplier;
			}
		}
		
		override molehill_internal function set parentGreen(value:Number):void
		{
			super.parentGreen = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentGreen = value * _greenMultiplier;
			}
		}
		
		override molehill_internal function set parentBlue(value:Number):void
		{
			super.parentBlue = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentBlue = value * _blueMultiplier;
			}
		}
		
		override molehill_internal function set parentAlpha(value:Number):void
		{
			super.parentAlpha = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentAlpha = value * _alpha;
			}
		}
		
		override molehill_internal function set parentRotation(value:Number):void
		{
			super.parentRotation = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRotation = value + _rotation;
			}
		}
		// ----
		
		// self properties
		override public function set x(value:Number):void
		{
			super.x = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = _parentShiftX + _shiftX * _scaleX;
			}
		}
		
		override public function set y(value:Number):void
		{
			super.y = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = _parentShiftY + _shiftY * _scaleY;
			}
		}
		
		override public function set scaleX(value:Number):void
		{
			super.scaleX = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = _parentScaleX * _scaleX;
			}
		}
		
		override public function set scaleY(value:Number):void
		{
			super.scaleY = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleY = _parentScaleY * _scaleY;
			}
		}
		
		override public function moveTo(x:Number, y:Number, z:Number=0):void
		{
			super.moveTo(x, y, z);
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = _parentShiftX + _shiftX * _scaleX;
				_listChildren[i].parentShiftY = _parentShiftY + _shiftY * _scaleY;
			}
		}
		
		override public function setScale(scaleX:Number, scaleY:Number):void
		{
			super.setScale(scaleX, scaleY);
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = _parentScaleX * _scaleX;
				_listChildren[i].parentScaleY = _parentScaleY * _scaleY;
			}
		}
		
		override public function set redMultiplier(value:Number):void
		{
			super.redMultiplier = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRed = _parentRed * _redMultiplier;
			}
		}
		
		override public function set greenMultiplier(value:Number):void
		{
			super.greenMultiplier = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentGreen = _parentGreen * _greenMultiplier;
			}
		}
		
		override public function set blueMultiplier(value:Number):void
		{
			super.blueMultiplier = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentBlue = _parentBlue * _blueMultiplier;
			}
		}
		
		override public function set alpha(value:Number):void
		{
			super.alpha = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentAlpha = _parentAlpha * _alpha;
			}
		}
		
		override public function set darkenColor(value:uint):void
		{
			super.darkenColor = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRed = _parentRed * _redMultiplier;
				_listChildren[i].parentGreen = _parentGreen * _greenMultiplier;
				_listChildren[i].parentBlue = _parentBlue * _blueMultiplier;
			}
		}
		
		override public function set rotation(value:Number):void
		{
			super.rotation = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRotation = _parentRotation + _rotation;
			}
		}
	}
}