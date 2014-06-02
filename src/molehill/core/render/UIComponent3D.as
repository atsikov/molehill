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
			
			_containerBacks = new Sprite3DContainer();
			_containerTexts = new Sprite3DContainer();
			_containerMiscs = new Sprite3DContainer();
		}
		
		molehill_internal var flattenedRenderTree:TreeNode;
		
		private var _localTreeBack:TreeNode;
		private var _localTreeMisc:TreeNode;
		private var _localTreeText:TreeNode;
		
		private var _localTreeBackCursor:TreeNode;
		private var _localTreeMiscCursor:TreeNode;
		private var _localTreeTextCursor:TreeNode;
		
		private var _containerBacks:Sprite3DContainer;
		private var _containerTexts:Sprite3DContainer;
		private var _containerMiscs:Sprite3DContainer;
		
		molehill_internal function updateFlattnedTree():void
		{
			if (flattenedRenderTree == null || !precheckLocalRenderTree(localRenderTree))
			{
				if (flattenedRenderTree == null)
				{
					flattenedRenderTree = _cacheTreeNodes.newInstance();
					flattenedRenderTree.value = this;
					
					_localTreeBack = _cacheTreeNodes.newInstance();
					_localTreeBack.value = _containerBacks;
					
					_localTreeMisc = _cacheTreeNodes.newInstance()
					_localTreeMisc.value = _containerMiscs;
					
					_localTreeText = _cacheTreeNodes.newInstance();
					_localTreeText.value = _containerTexts;
				}
				else
				{
					flattenedRenderTree.removeNode(_localTreeText);
					flattenedRenderTree.removeNode(_localTreeMisc);
					flattenedRenderTree.removeNode(_localTreeBack);
				}
				
				syncTrees(localRenderTree, _localTreeMisc);
				
				flattenedRenderTree.addNode(_localTreeBack);
				flattenedRenderTree.addNode(_localTreeMisc);
				flattenedRenderTree.addNode(_localTreeText);
				
				_containerBacks.textureAtlasChanged = textureAtlasChanged;
				_containerBacks.treeStructureChanged = treeStructureChanged;
				
				_containerMiscs.textureAtlasChanged = textureAtlasChanged;
				_containerMiscs.treeStructureChanged = treeStructureChanged;
				
				_containerTexts.textureAtlasChanged = textureAtlasChanged;
				_containerTexts.treeStructureChanged = treeStructureChanged;
				
				traceTrees();
				
				/*
				if (parent is EasyTileList3DAnimated)
				{
					traceTrees();
				}
				*/
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
			_localTreeBackCursor = null;
			_localTreeMiscCursor = null;
			_localTreeTextCursor = null;
			
			dst.value = this;
			
			//trace("==============================================================================================================================");
			
			doSyncTrees(src, dst);
			
			dst.value = _containerMiscs;
			
			cleanupTail(_localTreeBackCursor);
			cleanupTail(_localTreeTextCursor);
		}
		
		private function cleanupTail(tree:TreeNode):void
		{
			if (tree != null)
			{
				tree = tree.nextSibling;
			}
			while (tree != null)
			{
				var next:TreeNode = tree.nextSibling;
				if (next != null)
				{
					tree.parent.removeNode(tree);
					cacheAllNodes(tree);
				}
				tree = next;
			}
		}
		
		private var _insideUIComponent:Boolean = false;
		private function doSyncTrees(src:TreeNode, dst:TreeNode, inSpecTree:Boolean = false):void
		{
			//trace('syncing subtree');
			while (src != null)
			{
				var treeChanged:Boolean = false;
				var origDst:TreeNode = dst;
				if (!inSpecTree || (src.value is TextField3D || src.value.parent is TextField3D))
				{
					var targetTree:TreeNode = getTreeNodeByValue(src.value as Sprite3DContainer, dst);
					if (targetTree !== dst)
					{
						treeChanged = true;
						dst = targetTree;
						//trace('tree changed');
					}
				}
				
				//trace(src.value + "  <==>  " + dst.value + '; inSpecTree == ' + inSpecTree + '; _insideUIComponent == ' + _insideUIComponent);
				
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
					
					doSyncTrees(src.firstChild, dst.firstChild, inSpecTree || origDst !== dst);
					
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
				
				if (treeChanged)
				{
					dst = origDst;
				}
				
				var nextValue:Sprite3DContainer = src.nextSibling == null ? null : src.nextSibling.value as Sprite3DContainer;
				var needMoveDstCursor:Boolean = _insideUIComponent || inSpecTree || nextValue == null || !inSpecTree && !nextValue.isBackground && !(nextValue is TextField3D);
				//trace('need to move cursor: ' + needMoveDstCursor.toString());
				if (src !== localRenderTree && needMoveDstCursor && src.nextSibling != null && dst.nextSibling == null)
				{
					node = _cacheTreeNodes.newInstance();
					node.value = src.nextSibling.value;
					dst.parent.insertNodeAfter(
						dst,
						node
					);
				}
				
				src.value.syncedInUIComponent = true;
				
				if (needMoveDstCursor)
				{
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
		
		private function getTreeNodeByValue(value:Sprite3DContainer, dst:TreeNode):TreeNode
		{
			if (value == null || _insideUIComponent)
			{
				_localTreeMiscCursor = dst;
				return dst;
			}
			
			var targetNode:TreeNode;
			var targetRoot:TreeNode;
			if (value.isBackground)
			{
				targetNode = _localTreeBackCursor;
				targetRoot = _localTreeBack;
			}
			else if (value is TextField3D)
			{
				targetNode = _localTreeTextCursor;
				targetRoot = _localTreeText;
			}
			else
			{
				_localTreeMiscCursor = dst;
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
			
			if (value.isBackground)
			{
				_localTreeBackCursor = targetNode;
			}
			else if (value is TextField3D)
			{
				_localTreeTextCursor = targetNode;
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