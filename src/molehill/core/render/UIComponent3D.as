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
				flattenedRenderTree = new TreeNode(this);
				
				_localTreeBack = new TreeNode(_containerBacks);
				flattenedRenderTree.addNode(_localTreeBack);
				
				_localTreeMisc = new TreeNode(_containerMiscs);
				flattenedRenderTree.addNode(_localTreeMisc);
				
				_localTreeText = new TreeNode(_containerTexts);
				flattenedRenderTree.addNode(_localTreeText);
				
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
					
					node = new TreeNode(sprite);
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
				dest = new TreeNode(src.value);
			}
			
			var node:TreeNode;
			if (src.hasChildren)
			{
				node = new TreeNode(src.firstChild.value);
				dest.addAsFirstNode(node);
				copyTree(src.firstChild, node);
				
				var nextSibling:TreeNode = src.firstChild.nextSibling;
				while (nextSibling != null)
				{
					node = new TreeNode(nextSibling.value);
					dest.addNode(node);
					copyTree(nextSibling, node)
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