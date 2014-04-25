package molehill.core.sprite
{
	import easy.collections.BinarySearchTree;
	import easy.collections.TreeNode;
	
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.BlendMode;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	import molehill.core.render.shader.Shader3D;
	
	import utils.CachingFactory;
	
	use namespace molehill_internal;

	public class Sprite3DContainer extends InteractiveSprite3D
	{
		molehill_internal static var _cacheTreeNodes:CachingFactory;
		
		private var _listChildren:Vector.<Sprite3D>
		
		private var _childCoordsMinX:BinarySearchTree;
		private var _childCoordsMinY:BinarySearchTree;
		private var _childCoordsMaxX:BinarySearchTree;
		private var _childCoordsMaxY:BinarySearchTree;
		
		public function Sprite3DContainer()
		{
			if (_cacheTreeNodes == null)
			{
				_cacheTreeNodes = new CachingFactory(TreeNode, 1000);
			}
			
			_listChildren = new Vector.<Sprite3D>();
			localRenderTree = _cacheTreeNodes.newInstance();
			localRenderTree.value = this;

			_childCoordsMinX = new BinarySearchTree();
			_childCoordsMinY = new BinarySearchTree();
			_childCoordsMaxX = new BinarySearchTree();
			_childCoordsMaxY = new BinarySearchTree();
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
			if (child === this)
			{
				throw new Error("Cannot place sprite into itself");
			}
			
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
				node = (child as Sprite3DContainer).localRenderTree;
			}
			else
			{
				node = _cacheTreeNodes.newInstance();
				node.value = child;
			}
			
			localRenderTree.addNode(node);
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
			
			if (!(child is Sprite3DContainer) || (child as Sprite3DContainer).numChildren > 0)
			{
				var minX:Number;
				var maxX:Number;
				var minY:Number;
				var maxY:Number;
				if (child._rotation == 0 && child._parentRotation == 0)
				{
					minX = Math.min(child._x0, child._x2);
					maxX = Math.max(child._x0, child._x2);
					minY = Math.min(child._y0, child._y2);
					maxY = Math.max(child._y0, child._y2);
				}
				else
				{
					minX = Math.min(child._x0, child._x1, child._x2, child._x3);
					maxX = Math.max(child._x0, child._x1, child._x2, child._x3);
					minY = Math.min(child._y0, child._y1, child._y2, child._y3);
					maxY = Math.max(child._y0, child._y1, child._y2, child._y3);
				}
				
				child.parentMinXNode = _childCoordsMinX.insertElement(child, minX);
				child.parentMinYNode = _childCoordsMinY.insertElement(child, minY);
				
				child.parentMaxXNode = _childCoordsMaxX.insertElement(child, maxX);
				child.parentMaxYNode = _childCoordsMaxY.insertElement(child, maxY);
			}
			
			updateChildParentValues(child);
			child.updateValues();
			
			updateContainerSize();
			
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
			
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
				node = (child as Sprite3DContainer).localRenderTree;
			}
			else
			{
				node = _cacheTreeNodes.newInstance();
				node.value = child;
			}
			
			if (index == 0)
			{
				localRenderTree.addAsFirstNode(node);
				_listChildren.unshift(child);
			}
			else if (index < _listChildren.length)
			{
				var prevNode:TreeNode = getNodeByChild(_listChildren[index - 1]);
				localRenderTree.insertNodeAfter(prevNode, node);
				_listChildren.splice(index, 0, child);
			}
			else
			{
				localRenderTree.addNode(node);
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
			
			
			if (!(child is Sprite3DContainer) || (child as Sprite3DContainer).numChildren > 0)
			{
				var minX:Number;
				var maxX:Number;
				var minY:Number;
				var maxY:Number;
				if (child._rotation == 0 && child._parentRotation == 0)
				{
					minX = Math.min(child._x0, child._x2);
					maxX = Math.max(child._x0, child._x2);
					minY = Math.min(child._y0, child._y2);
					maxY = Math.max(child._y0, child._y2);
				}
				else
				{
					minX = Math.min(child._x0, child._x1, child._x2, child._x3);
					maxX = Math.max(child._x0, child._x1, child._x2, child._x3);
					minY = Math.min(child._y0, child._y1, child._y2, child._y3);
					maxY = Math.max(child._y0, child._y1, child._y2, child._y3);
				}
				
				child.parentMinXNode = _childCoordsMinX.insertElement(child, minX);
				child.parentMinYNode = _childCoordsMinY.insertElement(child, minY);
				
				child.parentMaxXNode = _childCoordsMaxX.insertElement(child, maxX);
				child.parentMaxYNode = _childCoordsMaxY.insertElement(child, maxY);
			}
			
			var dimensionsChanged:Boolean = updateContainerSize();
			
			updateChildParentValues(child);
			child.updateValues();
			
			if (dimensionsChanged && _parent != null/* && notifyParentOnChange*/)
			{
				_parent.updateDimensions(this);
			}
			
			return child;
		}
		
		protected function updateChildParentValues(child:Sprite3D):void
		{
			child.parentShiftX = _parentShiftX + _shiftX * _parentScaleX;
			child.parentShiftY = _parentShiftY + _shiftY * _parentScaleY;
			child.parentShiftZ = _parentShiftZ + _shiftZ;
			
			child.parentScaleX = _parentScaleX * _scaleX;
			child.parentScaleY = _parentScaleY * _scaleY;
			
			child.parentRotation = _parentRotation + _rotation;
			
			child.parentAlpha = _parentAlpha * _alpha;
			child.parentRed = _parentRed * _redMultiplier;
			child.parentGreen = _parentGreen * _greenMultiplier;
			child.parentBlue = _parentBlue * _blueMultiplier;
			
			if (!child.updateOnRenderChanged)
			{
				child.updateOnRender = updateOnRender;
			}
			/*
			if (!child.notifyParentChanged)
			{
				child.notifyParentOnChange = notifyParentOnChange;
			}
			*/
		}
		
		protected var _containerX:int = 0;
		protected var _containerY:int = 0;
		protected var _containerRight:int = 0;
		protected var _containerBottom:int = 0;
		molehill_internal function updateDimensions(child:Sprite3D):void
		{
			var needUpdateDimensions:Boolean = false;
			if (child is Sprite3DContainer)
			{
				var container:Sprite3DContainer = child as Sprite3DContainer;
				if (container.numChildren == 0)
				{
					if (container.parentMinXNode != null)
					{
						_childCoordsMinX.removeNode(child.parentMinXNode);
						_childCoordsMinY.removeNode(child.parentMinYNode);
						_childCoordsMaxX.removeNode(child.parentMaxXNode);
						_childCoordsMaxY.removeNode(child.parentMaxYNode);
						
						child.parentMinXNode = null;
						child.parentMinYNode = null;
						child.parentMaxXNode = null;
						child.parentMaxYNode = null;
						
						needUpdateDimensions = true;
					}
					else
					{
						return;
					}
				}
			}
			
			if (!needUpdateDimensions)
			{
				var minX:Number;
				var maxX:Number;
				var minY:Number;
				var maxY:Number;
				if (child._rotation == 0 && child._parentRotation == 0)
				{
					minX = Math.min(child._x0, child._x2);
					maxX = Math.max(child._x0, child._x2);
					minY = Math.min(child._y0, child._y2);
					maxY = Math.max(child._y0, child._y2);
				}
				else
				{
					minX = Math.min(child._x0, child._x1, child._x2, child._x3);
					maxX = Math.max(child._x0, child._x1, child._x2, child._x3);
					minY = Math.min(child._y0, child._y1, child._y2, child._y3);
					maxY = Math.max(child._y0, child._y1, child._y2, child._y3);
				}
				
				if (child.parentMinXNode == null)
				{
					child.parentMinXNode = _childCoordsMinX.insertElement(child, minX);
					child.parentMinYNode = _childCoordsMinY.insertElement(child, minY);
					child.parentMaxXNode = _childCoordsMaxX.insertElement(child, maxX);
					child.parentMaxYNode = _childCoordsMaxY.insertElement(child, maxY);
				}
				else
				{
					_childCoordsMinX.updateNodeWeight(child.parentMinXNode, minX);
					_childCoordsMinY.updateNodeWeight(child.parentMinYNode, minY);
					_childCoordsMaxX.updateNodeWeight(child.parentMaxXNode, maxX);
					_childCoordsMaxY.updateNodeWeight(child.parentMaxYNode, maxY);
				}
				
				needUpdateDimensions = true;
			}
			
			var dimensionsChanged:Boolean = updateContainerSize();
			if (dimensionsChanged && _parent != null/* && notifyParentOnChange*/)
			{
				_parent.updateDimensions(this);
			}
		}
		
		private function updateContainerSize():Boolean
		{
			_containerX = _childCoordsMinX.minWeight;
			_containerY = _childCoordsMinY.minWeight;
			_containerRight = _childCoordsMaxX.maxWeight;
			_containerBottom = _childCoordsMaxY.maxWeight;
			
			var dimensionsChanged:Boolean =
				_x0 != _containerX ||
				_y0 != _containerY ||
				_x2 != _containerRight ||
				_y2 != _containerBottom;
			
			if (dimensionsChanged)
			{
				_x0 = _containerX;
				_y0 = _containerY;
				
				_x1 = _containerX;
				_y1 = _containerBottom;
				
				_x2 = _containerRight
				_y2 = _containerBottom
				
				_x3 = _containerRight
				_y3 = _containerY;
			}
			
			return dimensionsChanged;
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
			localRenderTree.removeNode(node);
			
			if (!(child is Sprite3DContainer))
			{
				node.reset();
				_cacheTreeNodes.storeInstance(node);
			}
			
			child.setScene(null);
			child._parent = null;
			
			var childIndex:int = _listChildren.indexOf(child);
			if (childIndex == 0)
			{
				_listChildren.shift();
			}
			else if (childIndex == _numChildren - 1)
			{
				_listChildren.pop();
			}
			else
			{
				_listChildren.splice(childIndex, 1);
			}
			
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
			
			if (child.parentMinXNode != null)
			{
				_childCoordsMinX.removeNode(child.parentMinXNode);
				_childCoordsMinY.removeNode(child.parentMinYNode);
				_childCoordsMaxX.removeNode(child.parentMaxXNode);
				_childCoordsMaxY.removeNode(child.parentMaxYNode);
				
				child.parentMinXNode = null;
				child.parentMinYNode = null;
				child.parentMaxXNode = null;
				child.parentMaxYNode = null;
				
				updateContainerSize();
			}
			
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
			
			return child;
		}
		
		public function removeChildAt(index:int):Sprite3D
		{
			var child:Sprite3D = _listChildren[index];
			var node:TreeNode = getNodeByChild(child);
			localRenderTree.removeNode(node);
			
			if (!(child is Sprite3DContainer))
			{
				node.reset();
				_cacheTreeNodes.storeInstance(node);
			}
			
			if (child is AnimatedSprite3D)
			{
				(child as AnimatedSprite3D).stop();
			}
			
			child.setScene(null);
			child._parent = null;
			if (index == 0)
			{
				_listChildren.shift();
			}
			else if (index == _numChildren - 1)
			{
				_listChildren.pop();
			}
			else
			{
				_listChildren.splice(index, 1);
			}
			
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
			
			if (child.parentMinXNode != null)
			{
				_childCoordsMinX.removeNode(child.parentMinXNode);
				_childCoordsMinY.removeNode(child.parentMinYNode);
				_childCoordsMaxX.removeNode(child.parentMaxXNode);
				_childCoordsMaxY.removeNode(child.parentMaxYNode);
				
				child.parentMinXNode = null;
				child.parentMinYNode = null;
				child.parentMaxXNode = null;
				child.parentMaxYNode = null;
				
				updateContainerSize();
			}
			
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
			
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
				
				child.parentVisible = value;
			}
		}
		
		override molehill_internal function set parentVisible(value:Boolean):void
		{
			super.parentVisible = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child.parentVisible = _visible && value;
			}
		}
		
		override molehill_internal function set hasChanged(value:Boolean):void
		{
			for each (var child:Sprite3D in _listChildren)
			{
				child.hasChanged = value;
			}
			
			super.hasChanged = value;
		}
		
		override molehill_internal function updateValues():void
		{
			for each (var child:Sprite3D in _listChildren)
			{
				child.updateValues();
			}
		}
		
		molehill_internal var textureAtlasChanged:Boolean = false;
		molehill_internal var treeStructureChanged:Boolean = false;
		
		override public function hitTestPoint(point:Point):Boolean
		{
			var pointX:Number = point.x;
			var pointY:Number = point.y;
			
			if (pointX < _containerX ||
				pointY < _containerY ||
				pointX > _containerRight ||
				pointY > _containerBottom
			)
			{
				return false;
			}
			
			for each (var child:Sprite3D in _listChildren)
			{
				if (child.hitTestCoords(pointX, pointY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		override molehill_internal function hitTestCoords(globalX:Number, globalY:Number):Boolean
		{
			if (globalX < _containerX ||
				globalY < _containerY ||
				globalX > _containerRight ||
				globalY > _containerBottom
			)
			{
				return false;
			}
			
			for each (var child:Sprite3D in _listChildren)
			{
				if (child.hitTestCoords(globalX, globalY))
				{
					return true;
				}
			}
			
			return false;
		}
		
		public function getObjectsUnderPoint(point:Point, list:Vector.<Sprite3D> = null):Vector.<Sprite3D>
		{
			var childrenUnderPoint:Vector.<Sprite3D> = list == null ? new Vector.<Sprite3D>() : list;
			if (point.x < _containerX ||
				point.y < _containerY ||
				point.x > _containerRight ||
				point.y > _containerBottom
			)
			{
				return childrenUnderPoint;
			}
			
			for (var i:int = 0; i < _listChildren.length; i++)
			{
				var child:Sprite3D = _listChildren[i];
				
				if (child.scene == null)
				{
					continue;
				}
				
				if (child.camera != null)
				{
					point.x += child.camera.scrollX;
					point.y += child.camera.scrollY;
					
					point.x /= child.camera.scale;
					point.y /= child.camera.scale;
				}
				
				if (child is Sprite3DContainer)
				{
					var container:Sprite3DContainer = child as Sprite3DContainer;
					
					if (point.x < container._containerX ||
						point.y < container._containerY ||
						point.x > container._containerRight ||
						point.y > container._containerBottom
					)
					{
						if (child.camera != null)
						{
							point.x *= child.camera.scale;
							point.y *= child.camera.scale;
							
							point.x -= child.camera.scrollX;
							point.y -= child.camera.scrollY;
						}
						
						continue;
					}
					
					if (!container.visible)
					{
						if (child.camera != null)
						{
							point.x *= child.camera.scale;
							point.y *= child.camera.scale;
							
							point.x -= child.camera.scrollX;
							point.y -= child.camera.scrollY;
						}
						
						continue;
					}
					
					container.getObjectsUnderPoint(point, childrenUnderPoint);
				}
				else if (child.hitTestPoint(point))
				{
					if (!child.visible)
					{
						if (child.camera != null)
						{
							point.x *= child.camera.scale;
							point.y *= child.camera.scale;
							
							point.x -= child.camera.scrollX;
							point.y -= child.camera.scrollY;
						}
						
						continue;
					}
					
					childrenUnderPoint.push(child);
				}
				
				if (child.camera != null)
				{
					point.x *= child.camera.scale;
					point.y *= child.camera.scale;
					
					point.x -= child.camera.scrollX;
					point.y -= child.camera.scrollY;
				}
			}
			
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
		
		molehill_internal var localRenderTree:TreeNode;
		
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
		
		// cached parent properties
		override molehill_internal function set parentShiftX(value:Number):void
		{
			super.parentShiftX = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = value + _shiftX * _parentScaleX;
			}
		}
		
		override molehill_internal function set parentShiftY(value:Number):void
		{
			super.parentShiftY = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = value + _shiftY * _parentScaleY;
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
			var dx:Number = _parentShiftX + value * _scaleX;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = dx;
			}
			
			super.x = value;
		}
		
		override public function set y(value:Number):void
		{
			var dy:Number = _parentShiftY + value * _scaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = dy;
			}
			
			super.y = value;
		}
		
		override public function set scaleX(value:Number):void
		{
			var sx:Number = _parentScaleX * value;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = sx;
			}
			
			super.scaleX = value;
		}
		
		override public function set scaleY(value:Number):void
		{
			var sy:Number = _parentScaleY * value;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleY = sy;
			}
			
			super.scaleY = value;
		}
		
		override public function moveTo(x:Number, y:Number, z:Number=0):void
		{
			var dx:Number = x * _parentScaleX;
			var dy:Number = y * _parentScaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = _parentShiftX + dx;
				_listChildren[i].parentShiftY = _parentShiftY + dy;
			}
			
			super.moveTo(x, y, z);
		}
		
		override public function setScale(scaleX:Number, scaleY:Number):void
		{
			var sx:Number = _parentScaleX * scaleX;
			var sy:Number = _parentScaleY * scaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = sx;
				_listChildren[i].parentScaleY = sy;
			}
			
			super.setScale(scaleX, scaleY);
		}
		
		override public function set redMultiplier(value:Number):void
		{
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRed = _parentRed * value;
			}
			
			super.redMultiplier = value;
		}
		
		override public function set greenMultiplier(value:Number):void
		{
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentGreen = _parentGreen * value;
			}
			
			super.greenMultiplier = value;
		}
		
		override public function set blueMultiplier(value:Number):void
		{
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentBlue = _parentBlue * value;
			}
			
			super.blueMultiplier = value;
		}
		
		override public function set alpha(value:Number):void
		{
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentAlpha = _parentAlpha * value;
			}
			
			super.alpha = value;
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
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRotation = _parentRotation + value;
			}
			
			super.rotation = value;
		}
		
		override public function set updateOnRender(value:Boolean):void
		{
			super.updateOnRender = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].updateOnRender = value;
			}
			
		}
		
		override public function isPixelTransparent(localX:int, localY:int):Boolean
		{
			return false;
		}
		
		/*
		override public function set notifyParentOnChange(value:Boolean):void
		{
			super.notifyParentOnChange = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].notifyParentOnChange = value;
			}
			
		}
		*/
	}
}