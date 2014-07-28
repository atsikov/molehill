package molehill.core.sprite
{
	import easy.collections.BinarySearchTree;
	import easy.collections.TreeNode;
	
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.BlendMode;
	import molehill.core.render.InteractiveSprite3D;
	import molehill.core.render.Scene3D;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3D;
	
	import utils.CachingFactory;
	
	use namespace molehill_internal;
	
	/**
	 * 
	 * Container for sprites. Allows to arrange sprites by depth and apply transformations to them.
	 * 
	 **/
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
			super();
			
			_x0 = int.MIN_VALUE;
			_x1 = int.MIN_VALUE;
			_x2 = int.MAX_VALUE;
			_x3 = int.MAX_VALUE;
			
			_y0 = int.MAX_VALUE;
			_y1 = int.MIN_VALUE;
			_y2 = int.MIN_VALUE;
			_y3 = int.MAX_VALUE;
			
			_containerX = _x0;
			_containerY = _y0;
			_containerRight = _x2;
			_containerBottom = _y2;
			
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
		
		/**
		 * 
		 * Adds new child to container.
		 * 
		 **/
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
			
			child.syncedInUIComponent = false;
			
			updateChildParentValues(child);
			child.updateValues();
			
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
			
			updateDimensionsTree(child);
			
			return child;
		}
		
		/**
		 * 
		 * Adds new child to container to certain depth.
		 * 
		 **/
		public function addChildAt(child:Sprite3D, index:int):Sprite3D
		{
			if (child.parent != null)
			{
				child.parent.removeChild(child);
			}
			
			child.syncedInUIComponent = false;
			
			updateChildParentValues(child);
			child.updateValues();
			
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
			
			updateDimensionsTree(child);
			
			return child;
		}
		
		private function updateDimensionsTree(child:Sprite3D):void
		{
			var cx0:Number = child._x0;
			var cx1:Number = child._x1;
			var cx2:Number = child._x2;
			var cx3:Number = child._x3;
			
			var cy0:Number = child._y0;
			var cy1:Number = child._y1;
			var cy2:Number = child._y2;
			var cy3:Number = child._y3;
			
			if (cx0 > int.MIN_VALUE)
			{
				var minX:Number;
				var maxX:Number;
				var minY:Number;
				var maxY:Number;
				
				if (child._rotation == 0 && child._parentRotation == 0)
				{
					minX = Math.min(cx0, cx2);
					maxX = Math.max(cx0, cx2);
					minY = Math.min(cy0, cy2);
					maxY = Math.max(cy0, cy2);
				}
				else
				{
					minX = Math.min(
						cx0 < cx1 ? cx0 : cx1,
						cx2 < cx3 ? cx2 : cx3
					);
					maxX = Math.max(
						cx0 > cx1 ? cx0 : cx1,
						cx2 > cx3 ? cx2 : cx3
					);
					minY = Math.min(
						cy0 < cy1 ? cy0 : cy1,
						cy2 < cy3 ? cy2 : cy3
					);
					maxY = Math.max(
						cy0 > cy1 ? cy0 : cy1,
						cy2 > cy3 ? cy2 : cy3
					);
				}
				
				child.parentMinXNode = _childCoordsMinX.insertElement(child, minX);
				child.parentMinYNode = _childCoordsMinY.insertElement(child, minY);
				
				child.parentMaxXNode = _childCoordsMaxX.insertElement(child, maxX);
				child.parentMaxYNode = _childCoordsMaxY.insertElement(child, maxY);
				
				var dimensionsChanged:Boolean = updateContainerSize();
				
				if (dimensionsChanged && _parent != null)
				{
					_parent.updateDimensions(this);
				}
			}
		}
		
		protected function updateChildParentValues(child:Sprite3D):void
		{
			var dx:Number = _shiftX * _parentScaleX;
			var dy:Number = _shiftY * _parentScaleY;
			
			child.parentShiftX = _parentShiftX + dx * _rotationCos - dy * _rotationSin;
			child.parentShiftY = _parentShiftY + dx * _rotationSin + dy * _rotationCos;
			child.parentShiftZ = _parentShiftZ + _shiftZ;
			
			child.parentScaleX = _parentScaleX * _scaleX;
			child.parentScaleY = _parentScaleY * _scaleY;
			
			child.parentRotation = _parentRotation + _rotation;
			
			child.parentAlpha = _parentAlpha * _alpha;
			child.parentRed = _parentRed * _redMultiplier;
			child.parentGreen = _parentGreen * _greenMultiplier;
			child.parentBlue = _parentBlue * _blueMultiplier;
			
			child.parentShaderChanged = true;
			
			child.parentVisible = visible;
			
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
		public function get containerX():int
		{
			return _containerX;
		}

		protected var _containerY:int = 0;
		public function get containerY():int
		{
			return _containerY;
		}

		protected var _containerRight:int = 0;
		public function get containerRight():int
		{
			return _containerRight;
		}

		protected var _containerBottom:int = 0;
		public function get containerBottom():int
		{
			return _containerBottom;
		}
		
		private var _dimensionsChanged:Boolean = false;
		molehill_internal function updateDimensions(child:Sprite3D, needUpdateParent:Boolean = true):void
		{
			var needUpdateDimensions:Boolean = false;
			if (child is Sprite3DContainer)
			{
				var container:Sprite3DContainer = child as Sprite3DContainer;
				if (container._containerX == int.MIN_VALUE)
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
				
				var cx0:Number = child._x0;
				var cx1:Number = child._x1;
				var cx2:Number = child._x2;
				var cx3:Number = child._x3;
				
				var cy0:Number = child._y0;
				var cy1:Number = child._y1;
				var cy2:Number = child._y2;
				var cy3:Number = child._y3;
				
				if (child._rotation == 0 && child._parentRotation == 0)
				{
					minX = Math.min(cx0, cx2);
					maxX = Math.max(cx0, cx2);
					minY = Math.min(cy0, cy2);
					maxY = Math.max(cy0, cy2);
				}
				else
				{
					minX = Math.min(
						cx0 < cx1 ? cx0 : cx1,
						cx2 < cx3 ? cx2 : cx3
					);
					maxX = Math.max(
						cx0 > cx1 ? cx0 : cx1,
						cx2 > cx3 ? cx2 : cx3
					);
					minY = Math.min(
						cy0 < cy1 ? cy0 : cy1,
						cy2 < cy3 ? cy2 : cy3
					);
					maxY = Math.max(
						cy0 > cy1 ? cy0 : cy1,
						cy2 > cy3 ? cy2 : cy3
					);
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
				
			}
			
			var dimensionsChanged:Boolean = updateContainerSize();
			_dimensionsChanged ||= dimensionsChanged;
			if (_dimensionsChanged && _parent != null && needUpdateParent)
			{
				_parent.updateDimensions(this, needUpdateParent);
				_dimensionsChanged = false;
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
			
			child.syncedInUIComponent = false;
			
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
			
			child.syncedInUIComponent = false;
			
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
			if (_visible == value)
			{
				return;
			}
			
			super.visible = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child._visibilityChanged ||= _visibilityChanged;
				
				child.parentVisible = value;
			}
		}
		
		override molehill_internal function set parentVisible(value:Boolean):void
		{
			if (_parentVisible == value)
			{
				return;
			}
			
			super.parentVisible = value;
			
			for each (var child:Sprite3D in _listChildren)
			{
				child.parentVisible = visible && value;
			}
		}
		
		override molehill_internal function markChanged(value:Boolean, updateParent:Boolean=true):void
		{
			for each (var child:Sprite3D in _listChildren)
			{
				child.markChanged(value, false);
			}
			
			super.markChanged(value);
		}
		
		override molehill_internal function updateValues():void
		{
			for each (var child:Sprite3D in _listChildren)
			{
				child.updateValues();
				child.updateParent(false);
			}
			
			if (child != null)
			{
				child.updateParent(true);
			}
		}
		
		molehill_internal var _textureAtlasChanged:Boolean = false;
		molehill_internal function get textureAtlasChanged():Boolean
		{
			return _textureAtlasChanged;
		}

		molehill_internal function set textureAtlasChanged(value:Boolean):void
		{
			if (value && _parent != null)
			{
				_parent.textureAtlasChanged = value;
			}
			
			_textureAtlasChanged = value;
		}

		molehill_internal var _treeStructureChanged:Boolean = true;
		molehill_internal function get treeStructureChanged():Boolean
		{
			return _treeStructureChanged;
		}
		
		molehill_internal function set treeStructureChanged(value:Boolean):void
		{
			if (value && _parent != null)
			{
				_parent.treeStructureChanged = value;
			}
			
			_treeStructureChanged = value;
		}
		
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
				
				if (child is Sprite3DContainer && (child.scene == null || !child.scene.isActive))
				{
					continue;
				}
				
				var childMask:Sprite3D = child.mask;
				if (childMask != null)
				{
					if (!childMask.hitTestPoint(point))
					{
						continue;
					}
				}
				
				var childCamera:CustomCamera = child.camera;
				if (childCamera != null)
				{
					point.x += childCamera.scrollX;
					point.y += childCamera.scrollY;
					
					point.x /= childCamera.scale;
					point.y /= childCamera.scale;
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
						if (childCamera != null)
						{
							point.x *= childCamera.scale;
							point.y *= childCamera.scale;
							
							point.x -= childCamera.scrollX;
							point.y -= childCamera.scrollY;
						}
						
						continue;
					}
					
					if (!container.visible)
					{
						if (childCamera != null)
						{
							point.x *= childCamera.scale;
							point.y *= childCamera.scale;
							
							point.x -= childCamera.scrollX;
							point.y -= childCamera.scrollY;
						}
						
						continue;
					}
					
					container.getObjectsUnderPoint(point, childrenUnderPoint);
				}
				else if (child.hitTestPoint(point))
				{
					if (!child.visible)
					{
						if (childCamera != null)
						{
							point.x *= childCamera.scale;
							point.y *= childCamera.scale;
							
							point.x -= childCamera.scrollX;
							point.y -= childCamera.scrollY;
						}
						
						continue;
					}
					
					childrenUnderPoint.push(child);
				}
				
				if (childCamera != null)
				{
					point.x *= childCamera.scale;
					point.y *= childCamera.scale;
					
					point.x -= childCamera.scrollX;
					point.y -= childCamera.scrollY;
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
		
		override public function get width():Number
		{
			if (_containerX == int.MIN_VALUE)
			{
				return 0;
			}
			
			return _containerRight - _containerX;
		}
		
		override public function set width(value:Number):void
		{
			scaleX = value / width;
		}
		
		override public function get height():Number
		{
			if (_containerX == int.MIN_VALUE)
			{
				return 0;
			}
			
			return _containerBottom - _containerY;
		}
		
		override public function set height(value:Number):void
		{
			scaleY = value / height;
		}
		
		// cached parent properties
		override molehill_internal function set parentShiftX(value:Number):void
		{
			super.parentShiftX = value;
			x = _shiftX;
			/*
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = value + _shiftX * _parentScaleX;
			}
			*/
		}
		
		override molehill_internal function set parentShiftY(value:Number):void
		{
			super.parentShiftY = value;
			y = _shiftY;
			/*
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = value + _shiftY * _parentScaleY * _parentRotationSin;
			}
			*/
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
			moveTo(_shiftX, _shiftY);
		}
		// ----
		
		// self properties
		override public function set x(value:Number):void
		{
			var dx:Number = value * _parentScaleX;
			var dy:Number = _shiftY * _parentScaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = _parentShiftX + dx * _parentRotationCos - dy * _parentRotationSin;
			}
			
			super.x = value;
		}
		
		override public function set y(value:Number):void
		{
			var dx:Number = _shiftX * _parentScaleX;
			var dy:Number = value * _parentScaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftY = _parentShiftY + dx * _parentRotationSin + dy * _parentRotationCos;
			}
			
			super.y = value;
		}
		
		override public function set scaleX(value:Number):void
		{
			var sx:Number = _parentScaleX * value;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = sx;
				_listChildren[i].parentShiftX = _listChildren[i]._parentShiftX;
			}
			
			super.scaleX = value;
		}
		
		override public function set scaleY(value:Number):void
		{
			var sy:Number = _parentScaleY * value;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleY = sy;
				_listChildren[i].parentShiftY = _listChildren[i]._parentShiftY;
			}
			
			super.scaleY = value;
		}
		
		override public function moveTo(x:Number, y:Number, z:Number=0):void
		{
			var dx:Number = x * _parentScaleX;
			var dy:Number = y * _parentScaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentShiftX = _parentShiftX + dx * _parentRotationCos - dy * _parentRotationSin;
				_listChildren[i].parentShiftY = _parentShiftY + dx * _parentRotationSin + dy * _parentRotationCos;
			}
			
			super.moveTo(x, y, z);
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			setScale(w / width, h / height);
		}
		
		override public function setScale(scaleX:Number, scaleY:Number):void
		{
			var sx:Number = _parentScaleX * scaleX;
			var sy:Number = _parentScaleY * scaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentScaleX = sx;
				_listChildren[i].parentScaleY = sy;
				
				_listChildren[i].parentShiftX = _listChildren[i]._parentShiftX;
				_listChildren[i].parentShiftY = _listChildren[i]._parentShiftY;
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
			super.rotation = value;
			
			var dx:Number = x * _parentScaleX;
			var dy:Number = y * _parentScaleY;
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				_listChildren[i].parentRotation = _parentRotation + value;
			}
			moveTo(_shiftX, _shiftY);
		}
		
		override public function set updateOnRender(value:Boolean):void
		{
			super.updateOnRender = value;
			
			for (var i:int = 0; i < _listChildren.length; i++) 
			{
				if (!_listChildren[i].updateOnRenderChanged)
				{
					_listChildren[i].updateOnRender = value;
				}
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
		
		override public function set shader(value:Shader3D):void
		{
			if (shader === value)
			{
				return;
			}
			
			super.shader = value;
			
			for (var i:int = 0; i < children.length; i++)
			{
				children[i].parentShaderChanged = true;
			}
		}
		
		override molehill_internal function set parentShaderChanged(value:Boolean):void
		{
			super.parentShaderChanged = value;
			
			for (var i:int = 0; i < children.length; i++)
			{
				children[i].parentShaderChanged = true;
			}
		}
		
		// Special properties for UIComponent3D
		
		private var _uiHasDynamicTexture:Boolean = false;
		/**
		 * 
		 * While located in UIComponent3D container sprites with uiHasDynamicTexture set to true will be moved to the middle while rendering, between other sprites and text.<br>
		 * This can help to batch UI textures and present UI component with less draw calls. 
		 * 
		 * @see molehill.core.render.UIComponent3D
		 * 
		 **/
		public function get uiHasDynamicTexture():Boolean
		{
			return _uiHasDynamicTexture;
		}
		
		public function set uiHasDynamicTexture(value:Boolean):void
		{
			_uiHasDynamicTexture = value;
		}
		
		private var _uiMoveToForeground:Boolean = false;
		/**
		 * 
		 * While located in UIComponent3D container sprites with uiMoveToForeground set to true will be moved to the front while rendering, even over text.<br>
		 * This allows to draw sprites over text for certain cases without workarounds with differnt UI containers. 
		 * 
		 * @see molehill.core.render.UIComponent3D
		 * 
		 **/
		public function get uiMoveToForeground():Boolean
		{
			return _uiMoveToForeground;
		}
		
		public function set uiMoveToForeground(value:Boolean):void
		{
			_uiMoveToForeground = value;
		}
	}
	
}