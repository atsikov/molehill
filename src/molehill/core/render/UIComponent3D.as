package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import molehill.core.molehill_internal;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	
	import utils.DebugLogger;
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
				if (_debug)
				{
					log(' - removing ' + currentNode.value + ' from parent ' + StringUtils.getObjectAddress(currentNode.parent));
				}
				currentNode.parent.removeNode(currentNode);
			}
			currentNode.reset();
			if (_debug)
			{
				log(' * storing node ' + StringUtils.getObjectAddress(currentNode) + '; value: ' + currentNode.value);
			}
			_cacheTreeNodes.storeInstance(currentNode);
			
			cacheAllNodes(nextNode);
		}
		
		private var _debug:Boolean = false;
		private function syncTrees(src:TreeNode):void
		{
			_localTreeDynamicCursor = _localTreeDynamic;
			_localTreeGenericCursor = _localTreeGeneric;
			_localTreeTextCursor = _localTreeText;
			_localTreeForegroundCursor = _localTreeForeground;
			
			//trace("==============================================================================================================================");
			/*
			cacheAllNodes(_localTreeGeneric.firstChild);
			cacheAllNodes(_localTreeDynamic.firstChild);
			cacheAllNodes(_localTreeText.firstChild);
			cacheAllNodes(_localTreeForeground.firstChild);
			*/
			
			_log = null;
			
			var hasError:Boolean = false;
//			if (parent is ShopItemRenderer)
//			{
//				if (_debug)
//				{
//					log(ObjectUtils.traceTree(localRenderTree));
//					log('----');
//					log(ObjectUtils.traceTree(_localTreeGeneric));
//					log('----');
//					log(ObjectUtils.traceTree(_localTreeDynamic));
//					log('----');
//					log(ObjectUtils.traceTree(_localTreeText));
//					log('----');
//					log(ObjectUtils.traceTree(_localTreeForeground));
//					log('================================');
//				}
//			}
			
//			try
//			{
				if (_debug)
				{
					log('roots: gen ' + StringUtils.getObjectAddress(_localTreeGeneric) + '; dyn ' +
						StringUtils.getObjectAddress(_localTreeDynamic) + '; text ' +
						StringUtils.getObjectAddress(_localTreeText) + '; fore ' +
						StringUtils.getObjectAddress(_localTreeForeground));
				}
				doSyncTrees(src);
				if (_debug)
				{
					log(' -- finished parsing\n');
				}
//			}
//			catch (e:Error)
//			{
//				hasError = true;
//				if (_debug)
//				{
//					log('!!!!!!!!!\n' + e + '!!!!!!!!!\n');
//				}
//			}
			
			if (!hasError/* || parent is ShopItemRenderer*/)
			{
				if (_debug)
				{
					log(' ========= ' + this + ' ========== ');
					log(ObjectUtils.traceTree(localRenderTree));
					log('----');
					log(ObjectUtils.traceTree(_localTreeGeneric));
					log('----');
					log(ObjectUtils.traceTree(_localTreeDynamic));
					log('----');
					log(ObjectUtils.traceTree(_localTreeText));
					log('----');
					log(ObjectUtils.traceTree(_localTreeForeground));
					log('================================');
				}
			}
			
			if (_debug)
			{
				saveLog();
			}
			
			if (_localTreeGenericCursor === _localTreeGeneric)
			{
				_localTreeGenericCursor = _localTreeGeneric.firstChild;
			}
			else if (_localTreeGenericCursor != null)
			{
				_localTreeGenericCursor = _localTreeGenericCursor.nextSibling;
			}
			cleanupTail(_localTreeGenericCursor);
			
			if (_localTreeDynamicCursor === _localTreeDynamic)
			{
				_localTreeDynamicCursor = _localTreeDynamic.firstChild;
			}
			else if (_localTreeDynamicCursor != null)
			{
				_localTreeDynamicCursor = _localTreeDynamicCursor.nextSibling;
			}
			cleanupTail(_localTreeDynamicCursor);
			
			if (_localTreeTextCursor === _localTreeText)
			{
				_localTreeTextCursor = _localTreeText.firstChild;
			}
			else if (_localTreeTextCursor != null)
			{
				_localTreeTextCursor = _localTreeTextCursor.nextSibling;
			}
			cleanupTail(_localTreeTextCursor);
			
			if (_localTreeForegroundCursor === _localTreeForeground)
			{
				_localTreeForegroundCursor = _localTreeForeground.firstChild;
			}
			else if (_localTreeForegroundCursor != null)
			{
				_localTreeForegroundCursor = _localTreeForegroundCursor.nextSibling;
			}
			cleanupTail(_localTreeForegroundCursor);
			
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
		
		private function doSyncTrees(src:TreeNode, asChild:Boolean = false):void
		{
			//trace('syncing subtree');
			
			var parentMask:int = 4 * (_isDynamic ? 1 : 0) + 2 * (_isText ? 1 : 0) + (_isForeground ? 1 : 0);
			if (_debug)
			{
				log('syncing subtree');
			}
			
			var needMoveUp:Boolean = false;
			while (src != null)
			{
				if (_debug)
				{
					log('sprite: ' + src.value + '; is synced: ' + (src.value as Sprite3D).syncedInUIComponent.toString());
				}
				
				var dyn:Boolean = _isDynamic;
				var text:Boolean = _isText;
				var fore:Boolean = _isForeground;
				updateTreeFlags(src.value as Sprite3DContainer);
				
				if (_debug)
				{
					log('flags: ' + (_isDynamic ? 'dyn' : '') + ' ' + (_isText ? 'text' : '') + ' ' + (_isForeground ? 'fore' : ''));
				}
				
				//var flagsChanged:Boolean = dyn != _isDynamic || text != _isText || fore != _isForeground;
				//asChild &&= !flagsChanged;
				
				var currentMask:int = 4 * (_isDynamic ? 1 : 0) + 2 * (_isText ? 1 : 0) + (_isForeground ? 1 : 0);
				if (currentMask == parentMask)
				{
					asChild = true;
					needMoveUp = true;
					parentMask = -1;
				}
				else
				{
					asChild = false;
				}
				
				addChildToTree(src.value, asChild);
				
				if (!(src.value is UIComponent3D))
				{
					if (src.hasChildren)
					{
						doSyncTrees(src.firstChild, true);
					}
					else
					{
						cleanUpChildren();
					}
				}
				/*
				if (!flagsChanged)
				{
					asChild = false;
				}
				*/
				restoreFlags(src.value as Sprite3DContainer);
				
				// cleaning children when all siblings belong to other trees
				if (parentMask != -1 && src.nextSibling == null)
				{
					cleanUpChildren();
				}
				
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
				
				if (src.parent == localRenderTree)
				{
					needMoveUp = false;
				}
				src = src.nextSibling;
			}
			
			if (needMoveUp)
			{
				moveCursorToParent();
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
				if (_debug)
				{
					log('\'fore\' flag dropped');
				}
			}
			
			if (value === _lastDynamicContainer)
			{
				_isDynamic = false;
				_lastDynamicContainer = null;
				if (_debug)
				{
					log('\'dyn\' flag dropped');
				}
			}
			
			if (value === _lastTextContainer)
			{
				_isText = false;
				_lastTextContainer = null;
				if (_debug)
				{
					log('\'text\' flag dropped');
				}
			}
		}
		
		private function addChildToTree(child:Sprite3D, asChild:Boolean):void
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
			
			asChild ||= targetRoot === targetNode;
			
			var nextSibling:TreeNode;
			var firstChild:TreeNode;
			if (targetNode != null)
			{
				if (asChild)
				{
					firstChild = targetNode.firstChild;
				}
				else if (!asChild)
				{
					nextSibling = targetNode.nextSibling;
				}
			}

			if (_debug)
			{
				log('asChild: ' + asChild + '; firstChild: ' + StringUtils.getObjectAddress(firstChild) + '; nextSibling: ' + StringUtils.getObjectAddress(nextSibling));
			}
			
			var childIsEqual:Boolean = asChild && firstChild != null && firstChild.value === child ||
									   !asChild && nextSibling != null && nextSibling.value === child;
			
			if (!childIsEqual)
			{
				if (asChild && firstChild == null)
				{
					var node:TreeNode = _cacheTreeNodes.newInstance();
					node.value = child;
					
					if (_debug)
					{
						log(' +1 adding as first child to root ' + StringUtils.getObjectAddress(targetRoot) + ', parent ' + StringUtils.getObjectAddress(targetNode) + ' as node ' + StringUtils.getObjectAddress(node));
					}
					targetNode.addNode(node);
					targetNode = node;
				}
				else if (!asChild && nextSibling == null)
				{
					node = _cacheTreeNodes.newInstance();
					node.value = child;
					
					if (_debug)
					{
						log(' + adding as last child to root ' + StringUtils.getObjectAddress(targetRoot) + ', parent ' + StringUtils.getObjectAddress(targetNode.parent) + ' as node ' + StringUtils.getObjectAddress(node));
					}
					targetNode.parent.addNode(node);
					targetNode = node;
				}
				else if (!child.syncedInUIComponent)
				{
					node = _cacheTreeNodes.newInstance();
					node.value = child;
				
					if (asChild)
					{
						if (_debug)
						{
							log(' +1 adding as first child to root ' + StringUtils.getObjectAddress(targetRoot) + ', parent ' + StringUtils.getObjectAddress(targetNode) + ' as node ' + StringUtils.getObjectAddress(node));
						}
						if (!(targetNode.value is Sprite3DContainer))
						{
							throw new Error('tree integrity failed');
						}
						
						targetNode.addAsFirstNode(node);
					}
					else
					{
						if (nextSibling != null)
						{
							var prevNode:TreeNode = targetNode;
							targetNode = nextSibling;
							if (_debug)
							{
								log(' -> getting node next sibling');
							}
							targetNode = nextSibling;
							if (_debug)
							{
								log(' +' + (prevNode == null ? '1' : '') + ' adding to root ' + StringUtils.getObjectAddress(targetRoot) + ' as ' + (prevNode == null ? 'first' : '') + ' node ' + StringUtils.getObjectAddress(node) + (prevNode != null ? ' before ' + StringUtils.getObjectAddress(targetNode) : ''));
							}
							if (prevNode != null)
							{
								targetNode.parent.insertNodeAfter(
									prevNode,
									node
								);
							}
							else
							{
								if (!(targetNode.value is Sprite3DContainer))
								{
									throw new Error('tree integrity failed');
								}
								
								targetNode.parent.addAsFirstNode(node);
							}
						}
						else
						{
							log(' + adding to root ' + StringUtils.getObjectAddress(targetRoot) + ' as node ' + StringUtils.getObjectAddress(node) + ' after ' + StringUtils.getObjectAddress(targetNode));
							targetNode.parent.addNode(node);
						}
					}
					
					targetNode = node;
				}
				else if (child.syncedInUIComponent)
				{
					if (firstChild != null)
					{
						targetNode = firstChild;
					}
					else if (nextSibling != null)
					{
						targetNode = nextSibling;
					}
					
					var targetNodeParent:TreeNode = targetNode.parent;
					while (targetNode != null && targetNode.value !== child)
					{
						if (_debug)
						{
							log(' - removing child ' + targetNode.value + ' from ' + StringUtils.getObjectAddress(targetNodeParent) + ' (' + StringUtils.getObjectAddress(targetNode) + ').parent');
						}
						var nextNode:TreeNode = targetNode.nextSibling;
						targetNodeParent.removeNode(targetNode);
						
						cacheAllNodes(targetNode);
						
						targetNode = nextNode;
					}
					
					if (targetNode == null)
					{
						if (_debug)
						{
							log(' -- all children removed, adding as next node');
						}
						node = _cacheTreeNodes.newInstance();
						node.value = child;
						
						targetNodeParent.addNode(node);
						targetNode = node;
					}
					else
					{
						if (_debug)
						{
							log(' == child found');
						}
					}
				}
			}
			else
			{
				if (_debug)
				{
					log(' == children are equal');
				}
				if (asChild && firstChild != null)
				{
					targetNode = firstChild;
				}
				else if (!asChild && nextSibling != null)
				{
					targetNode = nextSibling;
				}
			}
			
			if (targetRoot === _localTreeForeground)
			{
				if (_debug)
				{
					log('_localTreeForegroundCursor now ' + StringUtils.getObjectAddress(targetNode));
				}
				_localTreeForegroundCursor = targetNode;
			}
			else if (targetRoot === _localTreeText)
			{
				if (_debug)
				{
					log('_localTreeTextCursor now ' + StringUtils.getObjectAddress(targetNode));
				}
				_localTreeTextCursor = targetNode;
			}
			else if (targetRoot === _localTreeDynamic)
			{
				if (_debug)
				{
					log('_localTreeDynamicCursor now ' + StringUtils.getObjectAddress(targetNode));
				}
				_localTreeDynamicCursor = targetNode;
			}
			else
			{
				if (_debug)
				{
					log('_localTreeGenericCursor now ' + StringUtils.getObjectAddress(targetNode));
				}
				_localTreeGenericCursor = targetNode;
			}
			
			child.syncedInUIComponent = true;
		}
		
		private function moveCursorToParent():void
		{
			if (_isForeground)
			{
				if (_debug)
				{
					log(' ^ moving _localTreeGenericCursor up to ' + StringUtils.getObjectAddress(_localTreeForegroundCursor.parent));
				}
				cacheAllNodes(_localTreeForegroundCursor.nextSibling);
				_localTreeForegroundCursor = _localTreeForegroundCursor.parent;
			}
			else if (_isText)
			{
				if (_debug)
				{
					log(' ^ moving _localTreeTextCursor up to ' + StringUtils.getObjectAddress(_localTreeTextCursor.parent));
				}
				cacheAllNodes(_localTreeTextCursor.nextSibling);
				_localTreeTextCursor = _localTreeTextCursor.parent;
			}
			else if (_isDynamic)
			{
				if (_debug)
				{
					log(' ^ moving _localTreeDynamicCursor up to ' + StringUtils.getObjectAddress(_localTreeDynamicCursor.parent));
				}
				cacheAllNodes(_localTreeDynamicCursor.nextSibling);
				_localTreeDynamicCursor = _localTreeDynamicCursor.parent;
			}
			else
			{
				if (_debug)
				{
					log(' ^ moving _localTreeGenericCursor up to ' + StringUtils.getObjectAddress(_localTreeGenericCursor.parent));
				}
				cacheAllNodes(_localTreeGenericCursor.nextSibling);
				_localTreeGenericCursor = _localTreeGenericCursor.parent;
			}
		}
		
		private function cleanUpChildren():void
		{
			if (_isForeground)
			{
				cacheAllNodes(_localTreeForegroundCursor.firstChild);
			}
			else if (_isText)
			{
				cacheAllNodes(_localTreeTextCursor.firstChild);
			}
			else if (_isDynamic)
			{
				cacheAllNodes(_localTreeDynamicCursor.firstChild);
			}
			else
			{
				cacheAllNodes(_localTreeGenericCursor.firstChild);
			}
		}
		
		private function storeNode(node:TreeNode):void
		{
			while (node != null)
			{
				if (node.hasChildren)
				{
					storeNode(node.firstChild);
				}
				else
				{
					var nextNode:TreeNode = node.nextSibling;
					if (node.parent != null)
					{
						node.parent.removeNode(node);
						node.reset();
						_cacheTreeNodes.storeInstance(node);
					}
				}
				
				node = nextNode;
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
		
		private var _log:String;
		private function log(entry:String):void
		{
			if (_log == null)
			{
				_log = entry;
			}
			else
			{
				_log += '\n' + entry;
			}
		}
		
		private function saveLog():void
		{
			DebugLogger.writeExternalLog(_log + '\n\n');
		}
	}
}