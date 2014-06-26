package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.text.TextField;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	import molehill.easy.ui3d.list.EasyTileList3DAnimated;
	
	import utils.ObjectUtils;
	import utils.StringUtils;
	
	use namespace molehill_internal;
	/**
	 * 
	 *  This class is using certain batching to move all text fields to the top layer.
	 *  This allow to draw all texts in container within one draw call. 
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
		}
		
		molehill_internal var flattenedRenderTree:TreeNode;
		
		private var _localTreeGeneric:TreeNode;
		private var _localTreeDynamic:TreeNode;
		private var _localTreeText:TreeNode;
		
		private var _localTreeGenericCursor:TreeNode;
		private var _localTreeDynamicCursor:TreeNode;
		private var _localTreeTextCursor:TreeNode;
		
		private var _containerGeneric:Sprite3DContainer;
		private var _containerDynamic:Sprite3DContainer;
		private var _containerTexts:Sprite3DContainer;
		
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
				}
				else
				{
					//traceTrees();
					
					flattenedRenderTree.removeNode(_localTreeText);
					flattenedRenderTree.removeNode(_localTreeDynamic);
					flattenedRenderTree.removeNode(_localTreeGeneric);
				}
				
				syncTrees(localRenderTree, _localTreeGeneric);
				
				flattenedRenderTree.addNode(_localTreeGeneric);
				flattenedRenderTree.addNode(_localTreeDynamic);
				flattenedRenderTree.addNode(_localTreeText);
				
				_containerDynamic.textureAtlasChanged = textureAtlasChanged;
				_containerDynamic.treeStructureChanged = treeStructureChanged;
				
				_containerGeneric.textureAtlasChanged = textureAtlasChanged;
				_containerGeneric.treeStructureChanged = treeStructureChanged;
				
				_containerTexts.textureAtlasChanged = textureAtlasChanged;
				_containerTexts.treeStructureChanged = treeStructureChanged;
				
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
		
		/*
		private function createFlattenedTree(src:TreeNode):void
		{
			var node:TreeNode;
			var sprite:Sprite3D = src.value as Sprite3D;
			if (sprite !== this && (sprite is UIComponent3D))
			{
				
				//(sprite as UIComponent3D).updateFlattnedTree();
				//flattenedRenderTree.addNode(
				//	copyTree(
				//		(sprite as UIComponent3D).flattenedRenderTree
				//	)
				//);
				
				
				(sprite as UIComponent3D).updateFlattnedTree();
				if (sprite.isBackground)
				{
					_localTreeBack.addNode(
						copyTree(
							(sprite as UIComponent3D).flattenedRenderTree
						)
					);
				}
				else
				{
					_localTreeMisc.addNode(
						copyTree(
							(sprite as UIComponent3D).flattenedRenderTree
						)
					);
				}
				
				
				//node = _cacheTreeNodes.newInstance();
				//node.value = sprite;
				//
				//if (sprite.isBackground)
				//{
				//	_localTreeBack.addNode(node);
				//}
				//else
				//{
				//	_localTreeMisc.addNode(node);
				//}
				
				return;
			}
			
			if (src.hasChildren && !(sprite is TextField3D))
			{
				createFlattenedTree(src.firstChild);
				
				var nextSibling:TreeNode = src.firstChild.nextSibling;
				while (nextSibling != null)
				{
					createFlattenedTree(nextSibling)
					nextSibling = nextSibling.nextSibling;
				}
			}
			else
			{
				if (sprite != null)
				{
					var suitableTree:TreeNode;
					if (sprite is TextField3D)
					{
						suitableTree = _localTreeText;
					}
					else if (sprite.isBackground)
					{
						suitableTree = _localTreeBack;
					}
					else
					{
						suitableTree = _localTreeMisc;
					}
					
					node = _cacheTreeNodes.newInstance();
					node.value = sprite;
					suitableTree.addNode(
						node
					);
					
					if (sprite is TextField3D)
					{
						copyTree(src, node);
					}
				}
			}
		}
		
		private function copyTree(src:TreeNode, dest:TreeNode = null):TreeNode
		{
			if (dest == null)
			{
				dest = _cacheTreeNodes.newInstance();
				dest.value = src.value;
			}
			
			var node:TreeNode;
			if (src.hasChildren)
			{
				dest.addAsFirstNode(
					copyTree(src.firstChild)
				);
				
				var nextSibling:TreeNode = src.firstChild.nextSibling;
				while (nextSibling != null)
				{
					dest.addNode(
						copyTree(nextSibling)
					);
					nextSibling = nextSibling.nextSibling;
				}
			}
			
			return dest;
		}
		*/
		
		private function syncTrees(src:TreeNode, dst:TreeNode):void
		{
			_localTreeDynamicCursor = null;
			_localTreeGenericCursor = null;
			_localTreeTextCursor = null;
			
			dst.value = this;
			
			//trace("==============================================================================================================================");
			
			if (_lastDst == null)
			{
				_lastDst = new Array();
			}
			
			while (_lastDst.length > 0)
			{
				_lastDst.pop();
			}
			
			doSyncTrees(src, dst);
			
			dst.value = _containerGeneric;
			
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
		
		private var _lastDst:Array;
		private var _insideUIComponent:Boolean = false;
		private function doSyncTrees(src:TreeNode, dst:TreeNode, inSpecTree:Boolean = false):void
		{
			//trace('syncing subtree');
			while (src != null)
			{
				var treeChanged:Boolean = false;
				var origDst:TreeNode = dst;
				
				var isDynamic:Boolean = _isDynamic;
				var isText:Boolean = _isText;
				
				var targetTree:TreeNode = getTreeNodeByValue(src.value as Sprite3DContainer, dst);
				
				if (isDynamic != _isDynamic || isText != _isText)
				{
					treeChanged = true;
					_lastDst.push(dst);
					dst = targetTree;
					//trace('tree changed: origDst ' + StringUtils.getObjectAddress(origDst) + ', dst ' + StringUtils.getObjectAddress(dst) + '; \n\t_localTreeTextCursor.value == ' + (_localTreeTextCursor != null ? _localTreeTextCursor.value : null) +
					//	'; \n\t_localTreeDynamicCursor.value == ' + (_localTreeDynamicCursor != null ? _localTreeDynamicCursor.value : null));
				}
				
				//trace(src.value + "  <==>  " + dst.value + '; inSpecTree == ' + inSpecTree + '; _insideUIComponent == ' + _insideUIComponent);
				//trace('Dynamic: ' + _isDynamic + '; text: ' + _isText);
				
				if (src.value !== dst.value)
				{
					if (!(src.value as Sprite3D).syncedInUIComponent)
					{
						//trace("adding child to flattened list"); 
						var dstParent:TreeNode = dst.parent;
						var dstPrev:TreeNode = dst.prevSibling;
						
						dst = _cacheTreeNodes.newInstance();
						dst.value = src.value;
						
						if (dstPrev == null)
						{
							dstParent.addAsFirstNode(dst);
						}
						else
						{
							dstParent.insertNodeAfter(
								dstPrev,
								dst
							);
						}
					}
					else
					{
						//trace("removing child from flattened list"); 
						dstParent = dst.parent;
						var dstNext:TreeNode = dst.nextSibling;
						
						// assigning pointer here because dst removing may affect cursors
						if (dstNext != null)
						{
							if (_dstTreeRoot === _localTreeDynamic)
							{
								_localTreeDynamicCursor = _localTreeDynamicCursor.prevSibling;
							}
							else if (_dstTreeRoot === _localTreeText)
							{
								_localTreeTextCursor = _localTreeTextCursor.prevSibling;
							}
						}
						
						dstParent.removeNode(dst);
						cacheAllNodes(dst);
						
						if (dstNext != null)
						{
							dst = dstNext;
							dstNext = null;
							continue;
						}
						else
						{
							dst = _cacheTreeNodes.newInstance();
							dst.value = src.value;
							dstParent.addNode(dst);
						}
					}
				}
				
				if (src.hasChildren)
				{
					if (!dst.hasChildren)
					{
						var node:TreeNode = _cacheTreeNodes.newInstance();
						node.value = src.firstChild.value;
						dst.addAsFirstNode(node);
					}
					
					if (src !== localRenderTree && src.value is UIComponent3D)
					{
						_insideUIComponent = true;
					}
					
					doSyncTrees(src.firstChild, dst.firstChild, inSpecTree || /*origDst !== dst*/treeChanged);
					
					if (src !== localRenderTree && src.value is UIComponent3D)
					{
						_insideUIComponent = false;
					}
				}
				else
				{
					while (dst.hasChildren)
					{
						var firstChild:TreeNode = dst.firstChild;
						dst.removeNode(firstChild);
						cacheAllNodes(firstChild);
					}
				}
				
				isDynamic = _isDynamic;
				isText = _isText;
				
				if (src.value == _lastDynamicContainer)
				{
					_localTreeDynamicCursor = dst;
					_isDynamic = false;
				}
				
				if (src.value == _lastTextContainer)
				{
					_localTreeTextCursor = dst;
					_isText = false;
				}
				
				if (isDynamic != _isDynamic || isText != _isText)
				{
					dst = _lastDst.pop();
				}
				/*
				var nextValue:Sprite3DContainer = src.nextSibling == null ? null : src.nextSibling.value as Sprite3DContainer;
				var needMoveDstCursor:Boolean =
					_insideUIComponent ||
					inSpecTree ||
					nextValue == null ||
					!inSpecTree && !nextValue.hasDynamicTexture && !(nextValue is TextField3D);
				
				trace('need to move cursor: ' + needMoveDstCursor);
				*/
				
				var nextSiblingNode:TreeNode = dst;
				if (src !== localRenderTree && src.nextSibling != null)
				{
					nextSiblingNode = getTreeNodeByValue(src.nextSibling.value as Sprite3DContainer, dst, true);
					if (nextSiblingNode.value !== src.nextSibling.value && nextSiblingNode.nextSibling == null)
					{
						node = _cacheTreeNodes.newInstance();
						node.value = src.nextSibling.value;
						nextSiblingNode.parent.insertNodeAfter(
							nextSiblingNode,
							node
						);
					}
				}
				
				src.value.syncedInUIComponent = true;
				
				if (nextSiblingNode === dst)
				{
					//trace('changing dst pointer: ' + StringUtils.getObjectAddress(dst) + ' -> ' + StringUtils.getObjectAddress(dst.nextSibling));
					dst = dst.nextSibling;
				}
				
				if (src !== localRenderTree)
				{
					src = src.nextSibling;
				}
				else
				{
					break;
				}
			}
			
			while (dst != null)
			{
				dstNext = dst.nextSibling;
				dst.parent.removeNode(dst);
				cacheAllNodes(dst);
				dst = dstNext;
			}
		}
		
		private var _dstTreeRoot:TreeNode;
		private var _isDynamic:Boolean;
		private var _lastDynamicContainer:Sprite3DContainer;
		private var _isText:Boolean;
		private var _lastTextContainer:Sprite3DContainer;
		private function getTreeNodeByValue(value:Sprite3DContainer, dst:TreeNode, keepFlags:Boolean = false):TreeNode
		{
			if (value == null || _insideUIComponent)
			{
				_localTreeGenericCursor = dst;
				return dst;
			}
			
			var targetNode:TreeNode;
			var targetRoot:TreeNode;
			if (value.hasDynamicTexture)
			{
				targetNode = _localTreeDynamicCursor;
				targetRoot = _localTreeDynamic;
				_dstTreeRoot = _localTreeDynamic;
				
				if (!keepFlags)
				{
					if (!_isDynamic)
					{
						_lastDynamicContainer = value;
					}
					_isDynamic = true;
				}
			}
			else if (value is TextField3D)
			{
				targetNode = _localTreeTextCursor;
				targetRoot = _localTreeText;
				_dstTreeRoot = _localTreeText;
				
				if (!keepFlags)
				{
					if (!_isText)
					{
						_lastTextContainer = value;
					}
					_isText = true;
				}
			}
			else
			{
				_localTreeGenericCursor = dst;
				_dstTreeRoot = _localTreeGeneric;
				return dst;
			}
			
			if (targetNode != null)
			{
				targetNode = targetNode.nextSibling;
			}
			else
			{
				targetNode = targetRoot.firstChild;
			}
			
			if (targetNode == null)
			{
				var node:TreeNode = _cacheTreeNodes.newInstance();
				node.value = value;
				targetRoot.addNode(node);
				
				targetNode = targetRoot.lastChild;
			}
			
			if (!keepFlags)
			{
				if (value.hasDynamicTexture)
				{
					_localTreeDynamicCursor = targetNode;
				}
				else if (value is TextField3D)
				{
					_localTreeTextCursor = targetNode;
				}
			}
			
			return targetNode;
		}
		
		private function traceTrees():void
		{
			trace(ObjectUtils.traceTree(localRenderTree));
			trace('-----------------');
			trace(ObjectUtils.traceTree(flattenedRenderTree));
			trace('================================');
		}
	}
}