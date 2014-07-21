package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.text.TextField;
	import flash.utils.Dictionary;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	import molehill.easy.ui3d.list.EasyTileList3DAnimated;
	
	import tempire.view.ui.forms.CheatsForm;
	
	import utils.ObjectUtils;
	import utils.StringUtils;
	
	use namespace molehill_internal;
	/**
	 * 
	 *  Class creates special render tree where all texts are moved to one subtree which minimizes draw calls.
	 *  Also sprites with changing textures can be placed in separate subtree using Sprite3DContainer.uiHasDynamicTexture flag to optimize batching.
	 * 
	 *  @see molehill.core.sprite.Sprite3DContainer
	 * 
	 **/
	public class UIComponent3D extends Sprite3DContainer
	{
		public function UIComponent3D()
		{
			super();
			
			mouseEnabled = true;
			
			_containerGeneric = new Sprite3DContainer();
			_containerTexts = new Sprite3DContainer();
			_containerDynamic = new Sprite3DContainer();
			_containerForeground = new Sprite3DContainer();
		}
		
		molehill_internal var flattenedRenderTree:TreeNode;
		
		private var _localTreeGeneric:TreeNode;
		private var _localTreeDynamic:TreeNode;
		private var _localTreeText:TreeNode;
		private var _localTreeForeground:TreeNode;
		
		private var _localTreeGenericCursor:TreeNode;
		private var _localTreeDynamicCursor:TreeNode;
		private var _localTreeTextCursor:TreeNode;
		private var _localTreeForegroundCursor:TreeNode;
		
		private var _containerGeneric:Sprite3DContainer;
		private var _containerDynamic:Sprite3DContainer;
		private var _containerTexts:Sprite3DContainer;
		private var _containerForeground:Sprite3DContainer;
		
		molehill_internal function updateFlattnedTree():void
		{
			//if (flattenedRenderTree == null || !precheckLocalRenderTree(localRenderTree))
			{
				if (flattenedRenderTree == null)
				{
					flattenedRenderTree = _cacheTreeNodes.newInstance();
					flattenedRenderTree.value = this;
					
					_localTreeGeneric = _cacheTreeNodes.newInstance()
					_localTreeGeneric.value = _containerGeneric;
					
					_localTreeDynamic = _cacheTreeNodes.newInstance();
					_localTreeDynamic.value = _containerDynamic;
					
					_localTreeText = _cacheTreeNodes.newInstance();
					_localTreeText.value = _containerTexts;
					
					_localTreeForeground = _cacheTreeNodes.newInstance();
					_localTreeForeground.value = _containerForeground;
				}
				else
				{
					//traceTrees();
					
					flattenedRenderTree.removeNode(_localTreeText);
					flattenedRenderTree.removeNode(_localTreeDynamic);
					flattenedRenderTree.removeNode(_localTreeGeneric);
					flattenedRenderTree.removeNode(_localTreeForeground);
				}
				
				syncTrees(localRenderTree.firstChild);
				
				flattenedRenderTree.addNode(_localTreeGeneric);
				flattenedRenderTree.addNode(_localTreeDynamic);
				flattenedRenderTree.addNode(_localTreeText);
				flattenedRenderTree.addNode(_localTreeForeground);
				
				_containerDynamic.textureAtlasChanged = textureAtlasChanged;
				_containerDynamic.treeStructureChanged = treeStructureChanged;
				
				_containerGeneric.textureAtlasChanged = textureAtlasChanged;
				_containerGeneric.treeStructureChanged = treeStructureChanged;
				
				_containerTexts.textureAtlasChanged = textureAtlasChanged;
				_containerTexts.treeStructureChanged = treeStructureChanged;
				
				_containerForeground.textureAtlasChanged = textureAtlasChanged;
				_containerForeground.treeStructureChanged = treeStructureChanged;
				
			}
			
			//traceTrees();
		}
		
		private function precheckLocalRenderTree(src:TreeNode):Boolean
		{
			var spriteContainer:Sprite3DContainer = src.value as Sprite3DContainer;
			if (spriteContainer == null)
			{
				return true;
			}
			
			if (src !== localRenderTree && (src.value is UIComponent3D))
			{
				return true;
			}
			
			if (spriteContainer.treeStructureChanged || spriteContainer.textureAtlasChanged)
			{
				return false;
			}
			
			if (src.hasChildren)
			{
				if (!precheckLocalRenderTree(src.firstChild))
				{
					return false;
				}
				
				var nextSibling:TreeNode = src.firstChild.nextSibling;
				while (nextSibling != null)
				{
					if (!precheckLocalRenderTree(nextSibling))
					{
						return false;
					}
					
					nextSibling = nextSibling.nextSibling;
				}
			}
			
			return true;
		}
		
		private function cacheAllNodes(node:TreeNode):void
		{
			if (node == null)
			{
				return;
			}
			
			if (node.hasChildren)
			{
				cacheAllNodes(node.firstChild);
			}
			
			var currentNode:TreeNode = node;
			var nextNode:TreeNode = currentNode.nextSibling;
			
			if (currentNode.parent != null)
			{
				currentNode.parent.removeNode(currentNode);
			}
			currentNode.reset();
			_cacheTreeNodes.storeInstance(currentNode);
			
			cacheAllNodes(nextNode);
		}
		
		private function syncTrees(src:TreeNode):void
		{
			_localTreeDynamicCursor = null;
			_localTreeGenericCursor = null;
			_localTreeTextCursor = null;
			_localTreeForegroundCursor = null;
			
			//trace("==============================================================================================================================");
			
			cacheAllNodes(_localTreeGeneric.firstChild);
			cacheAllNodes(_localTreeDynamic.firstChild);
			cacheAllNodes(_localTreeText.firstChild);
			cacheAllNodes(_localTreeForeground.firstChild);
			
			doSyncTrees(src);
			/*
			if (_localTreeGenericCursor == null)
			{
				_localTreeGenericCursor = _localTreeGeneric.firstChild;
			}
			else
			{
				_localTreeGenericCursor = _localTreeGenericCursor.nextSibling;
			}
			cleanupTail(_localTreeGenericCursor);
			
			if (_localTreeDynamicCursor == null)
			{
				_localTreeDynamicCursor = _localTreeDynamic.firstChild;
			}
			else
			{
				_localTreeDynamicCursor = _localTreeDynamicCursor.nextSibling;
			}
			cleanupTail(_localTreeDynamicCursor);
			
			if (_localTreeTextCursor == null)
			{
				_localTreeTextCursor = _localTreeText.firstChild;
			}
			else
			{
				_localTreeTextCursor = _localTreeTextCursor.nextSibling;
			}
			cleanupTail(_localTreeTextCursor);
			
			if (_localTreeForegroundCursor == null)
			{
				_localTreeForegroundCursor = _localTreeForeground.firstChild;
			}
			else
			{
				_localTreeForegroundCursor = _localTreeForegroundCursor.nextSibling;
			}
			cleanupTail(_localTreeForegroundCursor);
			*/
		}
		
		private function cleanupTail(tree:TreeNode):void
		{
			while (tree != null)
			{
				var next:TreeNode = tree.nextSibling;
				tree.parent.removeNode(tree);
				cacheAllNodes(tree);
				
				tree = next;
			}
		}
		
		private var _addAsChild:Boolean = false;
		
		private var _needMoveCursorBack:Object;
		
		private function doSyncTrees(src:TreeNode):void
		{
			//trace('syncing subtree');
			while (src != null)
			{
				updateTreeFlags(src.value as Sprite3DContainer);
				
				addChildToTree(src.value);
				
				if (src.value is Sprite3DContainer && !(src.value is UIComponent3D))
				{
					if (src.hasChildren)
					{
						_addAsChild = true;
						
						doSyncTrees(src.firstChild);
						
						moveCursorToParent();
					}
				}
				
				restoreFlags(src.value as Sprite3DContainer);
				
				/*if (this is CheatsForm)
				{
					trace(src.value);
					trace("flags: " + _isDynamic + " " + _isText + " " + _isForeground);
					trace("cursors: " + StringUtils.getObjectAddress(_localTreeGenericCursor) +" " +
						StringUtils.getObjectAddress(_localTreeDynamicCursor) + " " +
						StringUtils.getObjectAddress(_localTreeTextCursor) + " " +
						StringUtils.getObjectAddress(_localTreeForegroundCursor)
					);
					traceTrees();
				}*/
				
				src = src.nextSibling;
			}
		}
		
		private var _isDynamic:Boolean = false;
		private var _isForeground:Boolean = false;
		private var _isText:Boolean = false;
		
		private var _lastDynamicContainer:Sprite3DContainer;
		private var _lastTextContainer:Sprite3DContainer;
		private var _lastForegroundContainer:Sprite3DContainer;
		private function updateTreeFlags(value:Sprite3DContainer):void
		{
			if (value == null)
			{
				return;
			}
			
			if (_isForeground)
			{
				return;
			}
			else if (value.uiMoveToForeground)
			{
				_isForeground = true;
				_lastForegroundContainer = value;
			}
			
			if (value.uiHasDynamicTexture && !_isDynamic)
			{
				_isDynamic = true;
				_lastDynamicContainer = value;
			}
			
			if (value is TextField3D && !_isText)
			{
				_isText = true;
				_lastTextContainer = value;
			}
		}
		
		private function restoreFlags(value:Sprite3DContainer):void
		{
			if (value == null)
			{
				return;
			}
			
			if (value === _lastForegroundContainer)
			{
				_isForeground = false;
				_lastForegroundContainer = null;
			}
			
			if (value === _lastDynamicContainer)
			{
				_isDynamic = false;
				_lastDynamicContainer = null;
			}
			
			if (value === _lastTextContainer)
			{
				_isText = false;
				_lastTextContainer = null;
			}
		}
		
		private function addChildToTree(child:Sprite3D):void
		{
			var targetNode:TreeNode;
			var targetRoot:TreeNode;
			
			if (_isForeground)
			{
				targetRoot = _localTreeForeground;
				targetNode = _localTreeForegroundCursor;
			}
			else if (_isText)
			{
				targetRoot = _localTreeText;
				targetNode = _localTreeTextCursor;
			}
			else if (_isDynamic)
			{
				targetRoot = _localTreeDynamic;
				targetNode = _localTreeDynamicCursor;
			}
			else
			{
				targetRoot = _localTreeGeneric;
				targetNode = _localTreeGenericCursor;
			}
			
			var node:TreeNode = _cacheTreeNodes.newInstance();
			node.value = child;
			
			if (targetNode == null)
			{
				targetRoot.addAsFirstNode(node);
			}
			else
			{
				if (_addAsChild)
				{
					targetNode.addNode(node);
				}
				else
				{
					targetNode.parent.insertNodeAfter(
						targetNode,
						node
					);
				}
			}
			
			if (targetRoot === _localTreeForeground)
			{
				_localTreeForegroundCursor = node;
			}
			else if (targetRoot === _localTreeText)
			{
				_localTreeTextCursor = node;
			}
			else if (targetRoot === _localTreeDynamic)
			{
				_localTreeDynamicCursor = node;
			}
			else
			{
				_localTreeGenericCursor = node;
			}
			
		}
		
		private function moveCursorToParent():void
		{
			if (_isForeground)
			{
				_localTreeForegroundCursor = _localTreeForegroundCursor.parent;
			}
			else if (_isText)
			{
				_localTreeTextCursor = _localTreeTextCursor.parent;
			}
			else if (_isDynamic)
			{
				_localTreeDynamicCursor = _localTreeDynamicCursor.parent;
			}
			else
			{
				_localTreeGenericCursor = _localTreeGenericCursor.parent;
			}
		}
		
		private function traceTrees():void
		{
//			trace(ObjectUtils.traceTree(localRenderTree));
//			trace('-----------------');
			trace(ObjectUtils.traceTree(_localTreeGeneric));
			trace('----')
			trace(ObjectUtils.traceTree(_localTreeDynamic));
			trace('----')
			trace(ObjectUtils.traceTree(_localTreeText));
			trace('----')
			trace(ObjectUtils.traceTree(_localTreeForeground));
			trace('================================');
		}
	}
}