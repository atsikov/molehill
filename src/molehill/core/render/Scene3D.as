package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.display3D.textures.Texture;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.focus.IFocusable;
	import molehill.core.molehill_internal;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	
	import utils.CachingFactory;
	import utils.DebugLogger;
	import utils.ObjectUtils;
	import utils.StringUtils;
	
	use namespace molehill_internal;

	public class Scene3D extends Sprite3DContainer
	{
		public static const MAX_SPRITES_PER_BATCHER:uint = 128;
		
		private var _textureManager:TextureManager;
		public function Scene3D()
		{
			_textureManager = TextureManager.getInstance();
			
			_listSpriteBatchers = new Vector.<IVertexBatcher>();
			
			_scene = this;
			
			addEventListener(Input3DMouseEvent.CLICK, onSceneMouseClick);
		}
		
		public function set focus(value:Sprite3D):void
		{
			 updateFocus(value);
		}
		
		private function updateFocus(target:Sprite3D):void
		{
			var newFocusInitiator:Sprite3D = target;
			while (target != null)
			{
				if (target is IFocusable)
				{
					(target as IFocusable).onFocusReceived();
				}
				
				target = target.parent;
			}
			
			while (_focusInitiator != null)
			{
				if (_focusInitiator === newFocusInitiator)
				{
					break;
				}
				
				if (_focusInitiator is IFocusable)
				{
					(_focusInitiator as IFocusable).onFocusLost();
				}
				
				_focusInitiator = _focusInitiator.parent;
			}
			
			_focusInitiator = newFocusInitiator;
		}
		
		private var _focusInitiator:Sprite3D;
		private function onSceneMouseClick(event:Input3DMouseEvent):void
		{
			var target:Sprite3D = event.eventInitiator;
			updateFocus(target);
		}
		
		private var _renderEngine:RenderEngine;
		public function get isActive():Boolean
		{
			return _renderEngine != null && _renderEngine.isReady;
		}
		
		molehill_internal function setRenderEngine(value:RenderEngine):void
		{
			_renderEngine = value;
		}
		
		public function onContextRestored():void
		{
			_listRestoredBatchers = new Array();
			
			notifyBatchersOnContextRestored(_batchingTree);
			
			_listRestoredBatchers = null;
		}
		
		private var _listRestoredBatchers:Array;
		private function notifyBatchersOnContextRestored(node:TreeNode):void
		{
			if (node == null)
			{
				return;
			}
			
			if (node.hasChildren)
			{
				notifyBatchersOnContextRestored(node.firstChild);
			}
			
			var batcher:IVertexBatcher = (node.value as BatchingInfo).batcher;
			if (batcher != null && _listRestoredBatchers.indexOf(batcher) == -1)
			{
				batcher.onContextRestored();
				_listRestoredBatchers.push(batcher);
			}
			
			notifyBatchersOnContextRestored(node.nextSibling);
		}
		
		/**
		 * private
		 **/
		private function compareTrees():Boolean
		{
			return ObjectUtils.traceTree(localRenderTree) == ObjectUtils.traceTree(_batchingTree);
		}
		
		public var globalTraceString:String = "";
		public function traceTrees():void
		{
			globalTraceString = "";
			globalTraceString += getTimer()/ 1000 + "\n\n";
			globalTraceString += ObjectUtils.traceTree(localRenderTree);
			globalTraceString += '\n-----------------\n';
			globalTraceString += ObjectUtils.traceTree(_batchingTree);
			globalTraceString += '\n-----------------\n';
			
			for (var i:int = 0; i < _listSpriteBatchers.length; i++)
			{
				globalTraceString += "[" + i + "]  " + _listSpriteBatchers[i] + "\n";
				
				if (_listSpriteBatchers[i] is SpriteBatcher)
				{
					globalTraceString += (_listSpriteBatchers[i] as SpriteBatcher).traceChildren() + "\n\n";
				}
			}
			
			globalTraceString += '\n================================\n\n';
			
			DebugLogger.writeExternalLog(globalTraceString);
		}
		
		molehill_internal var _needUpdateBatchers:Boolean = false;
		private var _listSpriteBatchers:Vector.<IVertexBatcher>;
		
		private static var _cacheBatchingTreeNodes:CachingFactory = new CachingFactory(TreeNode);
		private static var _cacheBatchingInfo:CachingFactory = new CachingFactory(BatchingInfo);
		
		private function getNewBatchingNode(child:Sprite3D):TreeNode
		{
			var batchingInfo:BatchingInfo = _cacheBatchingInfo.newInstance();
			batchingInfo.child = child;
			
			var treeNode:TreeNode = _cacheBatchingTreeNodes.newInstance();
			treeNode.value = batchingInfo;
			
			return treeNode;
		}
		
		/**
		 * Main method to build batchers on current render tree
		 **/
		private var _lastBatcher:IVertexBatcher;
		private var _lastBatchedChild:Sprite3D;
		private var _batcherInsertPosition:uint;
		private function checkBatchingTree(renderTree:TreeNode, batchingTree:TreeNode, cameraOwner:Sprite3D = null):void
		{
			var nextNode:TreeNode;
			
			while (renderTree != null)
			{
				var renderSprite:Sprite3D = renderTree.value;
				var batchingInfo:BatchingInfo = batchingTree.value;
				var batchingSprite:Sprite3D = batchingInfo.child;
				var isRenderableSprite:Boolean = !(renderSprite is Sprite3DContainer);
				var currentBatcher:IVertexBatcher = batchingInfo.batcher;
				if (currentBatcher != null)
				{
					if (_lastBatcher !== currentBatcher)
					{
						_lastBatcher = currentBatcher;
						_batcherInsertPosition++;
						if (_debug)
						{
							log('Last batcher is ' + _lastBatcher + ' (' + _listSpriteBatchers.indexOf(_lastBatcher) + ' / ' + _listSpriteBatchers.length);
							log('Next new batcher will be inserted to index ' + _batcherInsertPosition);
						}
					}
				}
				
				var currentSpriteBatcher:SpriteBatcher = currentBatcher as SpriteBatcher;
				
				if (renderSprite.camera != null)
				{
					cameraOwner = renderSprite;
				}
				
				if (_debug)
				{
					log('Compairing ' + renderSprite  + ' against ' + batchingSprite); 
				}
				
				// sprites are equal
				if (renderSprite === batchingSprite)
				{
					// sprite's properties changed
					if (currentSpriteBatcher != null && !currentSpriteBatcher.isSpriteCompatible(renderSprite, cameraOwner))
					{
						if (_debug)
						{
							log('Properties changed'); 
						}
						
						if (renderSprite === currentSpriteBatcher.getFirstChild() &&
							renderSprite !== currentSpriteBatcher.getLastChild())
						{
							_batcherInsertPosition--;
						}
						removeSpriteFromBatcher(currentSpriteBatcher, renderSprite);
						
						if (currentSpriteBatcher.numSprites == 0)
						{
							batchingInfo.batcher = null;
						}
						
						pushToSuitableSpriteBacther(
							batchingTree, 
							renderSprite,
							cameraOwner
						);
					}
				}
				// some sprites were removed from render but persists in batching
				else if (renderSprite.addedToScene)
				{
					if (batchingTree.nextSibling == null)
					{
						// seems that child was moved, copy will be deleted later 
						batchingTree.parent.addNode(
							getNewBatchingNode(renderSprite)
						);
					}
					
					batchingTree = removeBatchingNode(batchingTree);
					
					continue;
				}
				// sprite was added to render and doesn't exists in batching
				else
				{
					var newNode:TreeNode = getNewBatchingNode(
						renderSprite
					);
					
					if (batchingTree.prevSibling != null)
					{
						batchingTree.parent.insertNodeAfter(
							batchingTree.prevSibling,
							newNode
						);
					}
					else
					{
						batchingTree.parent.addAsFirstNode(
							newNode
						);
					}
					
					batchingTree = newNode;
					
					if (_debug)
					{
						log('Node for sprite ' + renderSprite + ' added'); 
					}
					
					continue;
				}
				
				var lastSpriteBatcher:SpriteBatcher = _lastBatcher as SpriteBatcher;
				if (isRenderableSprite && batchingInfo.batcher == null)
				{
					if (renderSprite is IVertexBatcher)
					{
						batchingInfo.batcher = renderSprite as IVertexBatcher;
						_listSpriteBatchers.splice(
							_batcherInsertPosition,
							0,
							renderSprite as IVertexBatcher
						);
						if (_debug)
						{
							log('Batcher ' + renderSprite + ' added to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length);
						}
						_batcherInsertPosition++;
						if (_debug)
						{
							log('Next new batcher will be inserted to index ' + _batcherInsertPosition);
						}
					}
					else
					{
						pushToSuitableSpriteBacther(
							batchingTree,
							renderSprite,
							cameraOwner
						);
					}
				}
				
				if (renderSprite is UIComponent3D)
				{
					(renderSprite as UIComponent3D).updateFlattnedTree();
				}
				
				var containerRenderTree:TreeNode = renderSprite is UIComponent3D ?
					(renderSprite as UIComponent3D).flattenedRenderTree :
					renderTree;
				
				if (containerRenderTree.hasChildren)
				{
					if (renderSprite.needUpdateBatcher)
					{
						if (!batchingTree.hasChildren)
						{
							batchingTree.addNode(
								getNewBatchingNode(containerRenderTree.firstChild.value)
							);
							
							if (_debug)
							{
								log('Node for sprite ' + containerRenderTree.firstChild.value + ' added'); 
							}
						}
						
						checkBatchingTree(containerRenderTree.firstChild, batchingTree.firstChild, cameraOwner);
						
						renderSprite.treeStructureChanged = false;
						renderSprite.textureAtlasChanged = false;
					}
					else
					{
						if (_debug)
						{
							log('Skipping unchanged container ' + renderSprite);
						}
						skipUnchangedContainer(batchingTree.firstChild);
					}
				}
				
				if (cameraOwner === renderSprite)
				{
					cameraOwner = null;
				}
				
				if (renderTree.nextSibling != null && batchingTree.nextSibling == null)
				{
					batchingTree.parent.addNode(
						getNewBatchingNode(renderTree.nextSibling.value)
					);
					
					if (_debug)
					{
						log('Node for sprite ' + renderTree.nextSibling.value + ' added'); 
					}
				}
				
				if (batchingTree.value.batcher != null)
				{
					_lastBatchedChild = renderSprite;
				}
				
				renderSprite.addedToScene = true;
				
				renderTree = renderTree.nextSibling;
				batchingTree = batchingTree.nextSibling;
			}
			
			if (batchingTree != null && _debug)
			{
				log('Removing unused sprites from batching');
			}
			
			while (batchingTree != null)
			{
				nextNode = batchingTree.nextSibling;
				batchingTree.parent.removeNode(batchingTree);
				removeNodeReferences(batchingTree);
				batchingTree = nextNode;
			}
		}
		
		private function removeBatchingNode(node:TreeNode):TreeNode
		{
			var batchingInfo:BatchingInfo = node.value;
			var batcher:IVertexBatcher = batchingInfo.batcher;
			var sprite:Sprite3D = batchingInfo.child;
			var spriteBatcher:SpriteBatcher = batcher as SpriteBatcher;
			if (spriteBatcher != null) 
			{
				removeSpriteFromBatcher(spriteBatcher, sprite);
			}
			
			var nextNode:TreeNode = node.nextSibling;
			node.parent.removeNode(node);
			
			node.value.reset();
			_cacheBatchingInfo.storeInstance(node.value);
			node.reset();
			_cacheBatchingTreeNodes.storeInstance(node);
			
			return nextNode;
		}
		
		private function removeSpriteFromBatcher(batcher:SpriteBatcher, sprite:Sprite3D):void
		{
			batcher.removeChild(sprite, _lastBatchedChild);
			if (_debug)
			{
				log('Removing sprite ' + sprite + ' from batcher ' + batcher); 
			}
			if (batcher.numSprites == 0)
			{
				var batcherIndex:int = _listSpriteBatchers.indexOf(batcher);
				if (_debug)
				{
					log('Removing empty batcher from list ' + batcherIndex + ' / ' + _listSpriteBatchers.length);
				}
				
				var prevBatcherIndex:int = batcherIndex - 1;
				_listSpriteBatchers.splice(batcherIndex, 1);
				batcher.clearBatcher();
				
				if (_lastBatcher == batcher)
				{
					_lastBatcher = prevBatcherIndex == -1 ? null : _listSpriteBatchers[prevBatcherIndex];
					_batcherInsertPosition--;
					if (_debug)
					{
						log('Last batcher is ' + _lastBatcher + ' (' + _listSpriteBatchers.indexOf(_lastBatcher) + ' / ' + _listSpriteBatchers.length);
						log('Next new batcher will be inserted to index ' + _batcherInsertPosition);
					}
					var lastSpriteBatcher:SpriteBatcher = _lastBatcher as SpriteBatcher;
					if (lastSpriteBatcher != null)
					{
						_lastBatchedChild = lastSpriteBatcher.getLastChild();
					}
				}
			}
		}
		
		private function updateSlicedBatcher(batchingTree:TreeNode, oldBatcher:IVertexBatcher, newBatcher:IVertexBatcher):void
		{
			while (batchingTree != null)
			{
				if (batchingTree.value.batcher != null)
				{
					if (batchingTree.value.batcher !== oldBatcher)
					{
						return;
					}
					else
					{
						if (_debug)
						{
							log('Sprite ' + batchingTree.value.child + ' moved ' + oldBatcher + ' --> ' + newBatcher);
						}
						
						batchingTree.value.batcher = newBatcher;
					}
				}
				
				if (batchingTree.hasChildren)
				{
					batchingTree = batchingTree.firstChild;
				}
				else if (batchingTree.nextSibling == null)
				{
					while (batchingTree != null && batchingTree.nextSibling == null)
					{
						batchingTree = batchingTree.parent;
					}
					
					if (batchingTree != null)
					{
						batchingTree = batchingTree.nextSibling;
					}
				}
				else
				{
					batchingTree = batchingTree.nextSibling;
				}
			}
		}
		
		private function skipUnchangedContainer(batchingTreeNode:TreeNode):void
		{
			while (batchingTreeNode != null)
			{
				var batchingInfo:BatchingInfo = batchingTreeNode.value;
				if (batchingInfo.batcher != null && _lastBatcher !== batchingInfo.batcher)
				{
					_lastBatchedChild = batchingInfo.child;
					_lastBatcher = batchingInfo.batcher;
					_batcherInsertPosition++;
					if (_debug)
					{
						log('Last batcher is ' + _lastBatcher + ' (' + _listSpriteBatchers.indexOf(_lastBatcher) + ' / ' + _listSpriteBatchers.length);
						log('Next new batcher will be inserted to index ' + _batcherInsertPosition);
					}
				}
				
				if (batchingTreeNode.hasChildren)
				{
					skipUnchangedContainer(batchingTreeNode.firstChild);
				}
				
				batchingTreeNode = batchingTreeNode.nextSibling;
			}
		}
		
		private function removeNodeReferences(node:TreeNode):void
		{
			while (node != null)
			{
				var batchingInfo:BatchingInfo = node.value;
				if (batchingInfo.batcher != null)
				{
					removeSpriteFromBatcher(batchingInfo.batcher as SpriteBatcher, batchingInfo.child);
				}
				batchingInfo.child.addedToScene = false;
				
				if (node.hasChildren)
				{
					removeNodeReferences(node.firstChild);
				}
				
				node = node.nextSibling;
			}
		}
		
		private var _doBatching:Boolean = false;
		private var _batchingTrigger:Sprite3D;
		
		private var _batchingTree:TreeNode;
		
		private var _enableTextureCreatedCheck:Boolean = true;
		public function get enableTextureCreatedCheck():Boolean
		{
			return _enableTextureCreatedCheck;
		}
		
		public function set enableTextureCreatedCheck(value:Boolean):void
		{
			_enableTextureCreatedCheck = value;
		}
		
		/**
		 * Adding sprite to proper batcher either passed or new one
		 **/
		private function pushToSuitableSpriteBacther(batchingTree:TreeNode, child:Sprite3D, cameraOwner:Sprite3D):SpriteBatcher
		{
			var batcherCreated:Boolean = false;
			var suitableBatcher:SpriteBatcher = _lastBatcher as SpriteBatcher;
			if (suitableBatcher != null &&
				!suitableBatcher.isSpriteCompatible(child, cameraOwner))
			{
				suitableBatcher = null;
			}
			
			if (suitableBatcher == null)
			{
				suitableBatcher = new SpriteBatcher(this);
				suitableBatcher.shader = child.shader;
				suitableBatcher.blendMode = child._blendMode;
				suitableBatcher.textureAtlasID = child.textureAtlasData == null ? null : child.textureAtlasData.atlasID;
				suitableBatcher.cameraOwner = cameraOwner;
				batcherCreated = true;
			}
			
			if (!batcherCreated && _lastBatchedChild != null)
			{
				if (_debug)
				{
					log('Sprite ' + child + ' added to batcher ' + StringUtils.getObjectAddress(suitableBatcher) + ' after ' + _lastBatchedChild); 
				}
				suitableBatcher.addChildAfter(_lastBatchedChild, child);
			}
			else
			{
				if (_debug)
				{
					log('Sprite ' + child + ' added to batcher ' + StringUtils.getObjectAddress(suitableBatcher)); 
				}
				suitableBatcher.addChild(child);
			}
			
			if (batcherCreated)
			{
				var lastSpriteBatcher:SpriteBatcher = _lastBatcher as SpriteBatcher;
				if (lastSpriteBatcher != null &&
					_lastBatchedChild != null &&
					_lastBatchedChild != lastSpriteBatcher.getLastChild())
				{
					var splittedBatcher:SpriteBatcher = lastSpriteBatcher.splitAfterChild(_lastBatchedChild);
					if (splittedBatcher == null)
					{
						if (_debug)
						{
							log('!!! new batcher is null !!!');
							log('!!! Sprite ' + _lastBatchedChild + ' not found in batcher ' + lastSpriteBatcher);
						}
					}
					
					updateSlicedBatcher(batchingTree, lastSpriteBatcher, splittedBatcher);
					_listSpriteBatchers.splice(
						_batcherInsertPosition,
						0,
						splittedBatcher
					);
					
					if (_debug)
					{
						log('Splitting batchers; inserting new on index ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length); 
					}
				}
				
				_listSpriteBatchers.splice(
					_batcherInsertPosition,
					0,
					suitableBatcher
				);
				
				if (_debug)
				{
					log('Batcher ' + suitableBatcher + ' added to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length);
				}
				
				_lastBatcher = suitableBatcher;
				_batcherInsertPosition++;
				if (_debug)
				{
					log('Last batcher is ' + _lastBatcher + ' (' + _listSpriteBatchers.indexOf(_lastBatcher) + ' / ' + _listSpriteBatchers.length);
					log('Next new batcher will be inserted to index ' + _batcherInsertPosition);
				}
			}
			
			batchingTree.value.batcher = suitableBatcher;
			
			return suitableBatcher;
		}
		
		private var _cameraOwner:Sprite3DContainer;
		private function setCameraOwner(node:TreeNode, cameraOwner:Sprite3D):void
		{
			while (node != null)
			{
				var batchingInfo:BatchingInfo = node.value as BatchingInfo;
				if (node.hasChildren && batchingInfo.child.camera == null)
				{
					setCameraOwner(node.firstChild, cameraOwner);
				}
				else if (!node.hasChildren && batchingInfo.batcher != null)
				{
					batchingInfo.batcher.cameraOwner = cameraOwner;
				}
				
				node = node.nextSibling;
			}
		}
		
		private function resetChangeFlags(treeNode:TreeNode):void
		{
			treeNode = treeNode.firstChild;
			
			while (treeNode != null)
			{
				if (treeNode.value is IVertexBatcher)
				{
					treeNode = treeNode.nextSibling;
					continue;
				}
				
				if (treeNode.hasChildren)
				{
					var container:Sprite3DContainer = treeNode.value as Sprite3DContainer;
					container.treeStructureChanged = false;
					container.textureAtlasChanged = false;
					resetChangeFlags(treeNode);
				}
				
				treeNode = treeNode.nextSibling;
			}
		}
		
		molehill_internal function set needUpdateBatchers(value:Boolean):void
		{
			_needUpdateBatchers = value;
		}
		
		molehill_internal function renderScene():void
		{
			var i:int = 0;
			var spriteBatcher:SpriteBatcher;
			if (_needUpdateBatchers)
			{
				_lastBatchedChild = null;
				_lastBatcher = null;
				_batcherInsertPosition = 0;
				
				_log = null;
				
				if (_batchingTree == null)
				{
					_batchingTree = getNewBatchingNode(this);
				}
				
				if (_listSpriteBatchers == null)
				{
					_listSpriteBatchers = new Vector.<IVertexBatcher>();
				}
				
				//traceTrees();
				
				//trace('==============================');
				checkBatchingTree(localRenderTree, _batchingTree);
					
				if (_debug)
				{
					saveLog();
					
					//traceTrees();
				}
				
				//traceTrees();
			}
			_needUpdateBatchers = false;
			
			var tm:TextureManager = TextureManager.getInstance();
			var passedVertices:uint = 0;
			
			for (i = 0; i < _listSpriteBatchers.length; i++)
			{
				var batcher:IVertexBatcher = _listSpriteBatchers[i];
				var verticesData:ByteArray = batcher.getVerticesData();
				if (batcher.numTriangles == 0)
				{
					continue;
				}
				
				// can be sprite with flat fill
				if (batcher.textureAtlasID != null && !tm.isAtlasCreated(batcher.textureAtlasID))
				{
					continue;
				}
				
				spriteBatcher = batcher as SpriteBatcher;
				
				var left:int = 0;
				var top:int = 0;
				
				if (batcher.batcherCamera != null)
				{
					left = batcher.batcherCamera.scrollX / batcher.batcherCamera.scale;
					top = batcher.batcherCamera.scrollY / batcher.batcherCamera.scale;
				}
				
				var right:int;
				var bottom:int;
				if (batcher.batcherCamera != null)
				{
					right = left + _renderEngine.getViewportWidth() / batcher.batcherCamera.scale;
					bottom = top + _renderEngine.getViewportHeight() / batcher.batcherCamera.scale;
				}
				else
				{
					right = left + _renderEngine.getViewportWidth();
					bottom = top + _renderEngine.getViewportHeight();
				}
				
				if (batcher.right < left ||
					batcher.left > right ||
					batcher.bottom < top ||
					batcher.top > bottom)
				{
					continue;
				}
				
				_renderEngine.drawBatcher(batcher);
			}
		}
		
		private var _lastTexture:Texture;
		
		private var _debug:Boolean = true;
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
