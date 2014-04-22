package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	
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
					flattenedRenderTree.addNode(_localTreeBack);
					
					_localTreeMisc = _cacheTreeNodes.newInstance()
					_localTreeMisc.value = _containerMiscs;
					flattenedRenderTree.addNode(_localTreeMisc);
					
					_localTreeText = _cacheTreeNodes.newInstance();
					_localTreeText.value = _containerTexts;
					flattenedRenderTree.addNode(_localTreeText);
				}
				else
				{
					cacheAllNodes(_localTreeBack.firstChild);
					cacheAllNodes(_localTreeMisc.firstChild);
					cacheAllNodes(_localTreeText.firstChild);
				}
				
				createFlattenedTree(localRenderTree);
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
			
			if (spriteContainer.treeStructureChanged)
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
			
			currentNode.parent.removeNode(currentNode);
			currentNode.reset();
			_cacheTreeNodes.storeInstance(currentNode);
			
			cacheAllNodes(nextNode);
		}
		
		private function createFlattenedTree(src:TreeNode):void
		{
			var node:TreeNode;
			var sprite:Sprite3D = src.value as Sprite3D;
			if (sprite !== this && (sprite is UIComponent3D))
			{
				flattenedRenderTree.addNode(
					copyTree(src)
				);
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
		
		private function traceTrees():void
		{
			trace(ObjectUtils.traceTree(localRenderTree));
			trace('-----------------');
			trace(ObjectUtils.traceTree(flattenedRenderTree));
			trace('================================');
		}
	}
}