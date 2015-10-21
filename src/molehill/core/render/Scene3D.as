package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import molehill.core.errors.Scene3DError;
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.focus.IFocusable;
	import molehill.core.molehill_internal;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
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
			
			notifyBatchersOnContextRestored(_bacthingTree);
			
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
			return ObjectUtils.traceTree(localRenderTree) == ObjectUtils.traceTree(_bacthingTree);
		}
		
		public var globalTraceString:String = "";
		public function traceTrees():void
		{
			globalTraceString = "";
			globalTraceString += getTimer()/ 1000 + "\n\n";
			globalTraceString += ObjectUtils.traceTree(localRenderTree);
			globalTraceString += '\n-----------------\n';
			globalTraceString += ObjectUtils.traceTree(_bacthingTree);
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
		
		private var _currentBatcher:IVertexBatcher;
		private var _lastBatchedChild:Sprite3D;
		private var _lastBatchedChildBatcher:IVertexBatcher;
		private var _batcherInsertPosition:uint;
		
		private var _hashBatchersOldToNew:Dictionary;
		private var _hashChangeBatchersLater:Dictionary;
		private var _hashWaitForSprite:Dictionary;
		
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
		private var _spritesUpdated:uint = 0;
		private function checkBatchingTree(renderTree:TreeNode, batchingTree:TreeNode, cameraOwner:Sprite3D = null):void
		{
			var batchNode:TreeNode
			if (renderTree == null)
			{
				return;
			}
			
			while (renderTree != null)
			{
				var sprite:Sprite3D = renderTree.value as Sprite3D;
				
				if (_debug)
				{
					log('checking sprite ' + sprite + ';\n_lastBatched: ' + _lastBatchedChild);
				}
				
				var currentTreeNodeBatcher:IVertexBatcher = (batchingTree.value as BatchingInfo).batcher;
				var currentSpriteAtlasData:TextureAtlasData = sprite.currentAtlasData;
				if (currentTreeNodeBatcher != null &&
					((currentSpriteAtlasData != null &&
					 currentSpriteAtlasData.atlasID !== currentTreeNodeBatcher.textureAtlasID) ||
					(currentSpriteAtlasData == null &&
					 currentTreeNodeBatcher.textureAtlasID != null))
				)
				{
					prevNode = batchingTree.prevSibling;
					nextNode = batchingTree.nextSibling;
					
					treeParent = batchingTree.parent;
					treeParent.removeNode(batchingTree);
					removeNodeReferences(batchingTree);
					
					if (nextNode != null)
					{
						batchingTree = nextNode;
					}
					else
					{
						// adding new empty container to batching
						batchNode = getNewBatchingNode(sprite);
						var renderTreePrevNode:TreeNode = renderTree.prevSibling
						var renderTreeParent:TreeNode = renderTree.parent;
						renderTreeParent.removeNode(renderTree);
						prepareBatchers(renderTree, batchNode, cameraOwner);
						if (renderTreePrevNode == null)
						{
							renderTreeParent.addAsFirstNode(renderTree);
						}
						else
						{
							renderTreeParent.insertNodeAfter(renderTreePrevNode, renderTree);
						}
						if (prevNode == null)
						{
							treeParent.addAsFirstNode(batchNode);
						}
						else
						{
							treeParent.insertNodeAfter(prevNode, batchNode);
						}
						
						batchingTree = batchNode;
					}
				}
				
				// sprites in render and batching tree aren't the same in this node
				// need to sync trees
				if (sprite !== (batchingTree.value as BatchingInfo).child)
				{
					if (!sprite.addedToScene)
					{
						// new child was added to render tree
						batchNode = getNewBatchingNode(sprite);
						
						var treeParent:TreeNode = renderTree.parent;
						var prevSibling:TreeNode = renderTree.prevSibling;
						treeParent.removeNode(renderTree);
						prepareBatchers(renderTree, batchNode, cameraOwner);
						
						// addind new node to batching tree
						//trace('addind new node to batching tree');
						if (prevSibling != null)
						{
							treeParent.insertNodeAfter(prevSibling, renderTree);
							if (_debug)
							{
								log(sprite + ' wasn\' added to scene');
							}
						}
						else
						{
							treeParent.addAsFirstNode(renderTree);
						}
						
						if (batchingTree.prevSibling == null)
						{
							batchingTree.parent.addAsFirstNode(batchNode);
						}
						else
						{
							batchingTree.parent.insertNodeAfter(batchingTree.prevSibling, batchNode);
						}
						batchingTree = batchNode;
					}
					else
					{
						// child exists in batching tree but not in render tree
						// removing node from batching tree
						//trace('removing node from batching tree');
						var prevNode:TreeNode = renderTree.prevSibling;
						var batchingParent:TreeNode = batchingTree.parent
						var nextNode:TreeNode = batchingTree.nextSibling;
						batchingTree.parent.removeNode(batchingTree);
						removeNodeReferences(batchingTree);
						if (nextNode != null)
						{
							batchingTree = nextNode;
							continue;
						}
						else
						{
							treeParent = renderTree.parent;
							
							batchNode = getNewBatchingNode(sprite);
							treeParent.removeNode(renderTree);
							prepareBatchers(renderTree, batchNode, cameraOwner);
							if (prevNode != null)
							{
								treeParent.insertNodeAfter(prevNode, renderTree);
							}
							else
							{
								treeParent.addAsFirstNode(renderTree);
							}
							
							batchingParent.addNode(batchNode);
							
							batchingTree = batchNode;
						}
					}
				}
				
				// saving current batcher to use for insertion if got new suitable unbatched sprite
				if ((batchingTree.value as BatchingInfo).batcher != null)
				{
					var oldBatcher:IVertexBatcher = (batchingTree.value as BatchingInfo).batcher;
					
					if (_hashWaitForSprite[sprite] != null)
					{
						delete _hashChangeBatchersLater[_hashWaitForSprite[sprite]];
						delete _hashWaitForSprite[sprite];
					}
					
					while (_hashBatchersOldToNew[oldBatcher] != null &&
						_hashChangeBatchersLater[oldBatcher] == null)
					{
						(batchingTree.value as BatchingInfo).batcher = _hashBatchersOldToNew[oldBatcher];
						oldBatcher = (batchingTree.value as BatchingInfo).batcher;
					}
					
					if (_currentBatcher !== (batchingTree.value as BatchingInfo).batcher)
					{
						_currentBatcher = (batchingTree.value as BatchingInfo).batcher;
						_batcherInsertPosition = _currentBatcher == null ? 0 : _listSpriteBatchers.indexOf(_currentBatcher) + 1;
					}
					_lastBatchedChild = (batchingTree.value as BatchingInfo).child;
					_lastBatchedChildBatcher = (batchingTree.value as BatchingInfo).batcher;
				}
				
				// UIComnponent3D inside another UIComponent3D won't have children in parent's flattened tree
				// need to check all UIComponent3D's no matter if they have children in current render tree
				if (renderTree.hasChildren || (sprite is UIComponent3D))
				{
					var container:Sprite3DContainer = sprite as Sprite3DContainer;
					
					if (container.textureAtlasChanged || container.treeStructureChanged || container.cameraChanged)
					{
						// found new non-empty container in render tree
						// adding children to bacthing
						
						var containerRenderTree:TreeNode = renderTree;
						
						if (sprite is UIComponent3D)
						{
							(sprite as UIComponent3D).updateFlattnedTree();
							containerRenderTree = (sprite as UIComponent3D).flattenedRenderTree;
						}
						
						if (!batchingTree.hasChildren)
						{
							// adding new empty container to batching
							batchNode = getNewBatchingNode(containerRenderTree.firstChild.value);
							var firstChild:TreeNode = containerRenderTree.firstChild;
							containerRenderTree.removeNode(firstChild);
							prepareBatchers(firstChild, batchNode, cameraOwner);
							containerRenderTree.addAsFirstNode(firstChild);
							batchingTree.addAsFirstNode(batchNode);
						}
						
						checkBatchingTree(
							containerRenderTree.firstChild,
							batchingTree.firstChild,
							sprite.camera != null ? sprite : cameraOwner
						);
					}
					else
					{
						updateLastBatcherValue(batchingTree.firstChild);
					}
					
					// scroll rect changed
					if (container.cameraChanged)
					{
						container.cameraChanged = false;
						
						_cameraOwner = container;
						setCameraOwner(batchingTree.firstChild, _cameraOwner);
						
						_cameraOwner = null;
					}
					
				}
				else if (batchingTree.hasChildren)
				{
					// last child was removed from container
					// cleaning up suitable batchers tree branch
					removeNodeReferences(batchingTree.firstChild);
					
					while (batchingTree.hasChildren)
					{
						batchingTree.removeNode(
							batchingTree.firstChild
						);
					}
				}
				
				if (renderTree.nextSibling != null && batchingTree.nextSibling == null)
				{
					// need to add new branch at the end of the current
					batchNode = getNewBatchingNode(renderTree.nextSibling.value);
					
					var nextSibling:TreeNode = renderTree.nextSibling;
					renderTree.parent.removeNode(nextSibling);
					prepareBatchers(nextSibling, batchNode, cameraOwner);
					renderTree.parent.insertNodeAfter(renderTree, nextSibling);
					
					batchingTree.parent.addNode(batchNode);
				}
				
				renderTree = renderTree.nextSibling;
				batchingTree = batchingTree.nextSibling;
			}
			
			while (batchingTree != null)
			{
				nextNode = batchingTree.nextSibling;
				batchingTree.parent.removeNode(batchingTree);
				removeNodeReferences(batchingTree);
				batchingTree = nextNode;
			}
		}
		
		private function updateLastBatcherValue(batchingTreeNode:TreeNode):void
		{
			var lastBatcher:IVertexBatcher;
			while (batchingTreeNode != null)
			{
				if (batchingTreeNode.hasChildren)
				{
					updateLastBatcherValue(batchingTreeNode.firstChild);
				}
				else
				{
					var batchingInfo:BatchingInfo = batchingTreeNode.value as BatchingInfo;
					var spriteBatcher:SpriteBatcher = batchingInfo.batcher as SpriteBatcher;
					
					if (_hashWaitForSprite[batchingInfo.child] != null)
					{
						delete _hashChangeBatchersLater[_hashWaitForSprite[batchingInfo.child]];
						delete _hashWaitForSprite[batchingInfo.child];
					}
					
					if (spriteBatcher != null)
					{
						while (_hashBatchersOldToNew[spriteBatcher] != null &&
							_hashChangeBatchersLater[spriteBatcher] == null)
						{
							batchingInfo.batcher = _hashBatchersOldToNew[spriteBatcher];
							spriteBatcher = _hashBatchersOldToNew[spriteBatcher];
						}
						
						if (spriteBatcher != null)
						{
							lastBatcher = spriteBatcher;
							_lastBatchedChild = batchingInfo.child;
							_lastBatchedChildBatcher = lastBatcher;
						}
					}
					else if (batchingInfo.batcher != null)
					{
						lastBatcher = batchingInfo.batcher;
						_lastBatchedChild = batchingInfo.child;
						_lastBatchedChildBatcher = lastBatcher;
					}
				}
				
				batchingTreeNode = batchingTreeNode.nextSibling;
			}
			
			_batcherInsertPosition = _listSpriteBatchers.indexOf(_lastBatchedChildBatcher) + 1;
			_currentBatcher = _lastBatchedChildBatcher;
			/*
			if (lastBatcher != null)
			{
				_batcherInsertPosition = _listSpriteBatchers.indexOf(lastBatcher) + 1;
				_currentBatcher = lastBatcher;
			}
			*/
		}
		
		private function removeNodeReferences(node:TreeNode):void
		{
			while (node != null)
			{
				var batchingInfo:BatchingInfo = node.value as BatchingInfo;
				if (node.hasChildren)
				{
					removeNodeReferences(node.firstChild);
				}
				else
				{
					var sprite:Sprite3D = batchingInfo.child;
					if (_debug)
					{
						log('removing ' + batchingInfo.child + ' from batching, batcher ' + StringUtils.getObjectAddress(batchingInfo.batcher));
					}
					var spriteBatcher:SpriteBatcher = batchingInfo.batcher as SpriteBatcher;
					
					if (_hashWaitForSprite[sprite] != null)
					{
						delete _hashChangeBatchersLater[_hashWaitForSprite[sprite]];
						delete _hashWaitForSprite[sprite];
					}
					
					while (_hashBatchersOldToNew[spriteBatcher] != null &&
						_hashChangeBatchersLater[spriteBatcher] == null)
					{
						spriteBatcher = _hashBatchersOldToNew[spriteBatcher];
						if (_debug)
						{
							log('>> children moved to batcher ' + StringUtils.getObjectAddress(spriteBatcher));
						}
					}
					
					sprite.addedToScene = false;
					if (spriteBatcher != null)
					{
						var removeAfter:Sprite3D = _lastBatchedChildBatcher === spriteBatcher ? _lastBatchedChild : null;
						var result:Boolean = spriteBatcher.removeChild(sprite, removeAfter);
						if (!result)
						{
							//trace('! child wasn\'t found in bacther');
							if (_debug)
							{
								log('! child was NOT removed in bacther');
							}
						}
						if (spriteBatcher.numSprites <= 0)
						{
							var index:int = _listSpriteBatchers.indexOf(spriteBatcher);
							_listSpriteBatchers.splice(index, 1);
							spriteBatcher.clearBatcher();
							if (_debug)
							{
								log('removing batcher from ' + index + ' position\n' + spriteBatcher);
							}
						}
					}
					else if (batchingInfo.batcher === sprite)
					{
						index = _listSpriteBatchers.indexOf(batchingInfo.batcher)
						_listSpriteBatchers.splice(index, 1);
						batchingInfo.batcher.clearBatcher();
						if (_debug)
						{
							log('removing batcher from ' + index + ' position\n' + batchingInfo.batcher);
						}
					}
				}
				
				var nextSibling:TreeNode = node.nextSibling;
				if (node.parent != null)
				{
					node.parent.removeNode(node);
					node.reset();
					_cacheBatchingTreeNodes.storeInstance(node);
				}
				
				batchingInfo.child = null;
				batchingInfo.batcher = null;
				
				_cacheBatchingInfo.storeInstance(batchingInfo);
				
				node = nextSibling;
			}
		}
		
		private var _doBatching:Boolean = false;
		private var _batchingTrigger:Sprite3D;
		
		private var _bacthingTree:TreeNode;
		
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
		 * Method to build branch of batchers based on branch from render tree
		 **/
		private function prepareBatchers(renderTree:TreeNode, batcherTree:TreeNode, cameraOwner:Sprite3D):void
		{
			if (_debug)
			{
				log('preparing batchers for\n' + ObjectUtils.traceTree(renderTree));
			}
			
			var node:TreeNode = renderTree;
			if (node == null)
			{
				return;
			}
			
			while (node != null)
			{
				var sprite:Sprite3D = node.value as Sprite3D;
				if (_debug)
				{
					log('processing ' + sprite);
				}
				
				var uiNode:TreeNode = null;
				if (sprite is UIComponent3D)
				{
					(sprite as UIComponent3D).updateFlattnedTree();
					uiNode = (sprite as UIComponent3D).flattenedRenderTree;
				}
				
				if (node.hasChildren || uiNode != null && uiNode.hasChildren)
				{
					var renderTreeFirstChild:TreeNode = sprite is UIComponent3D ? (sprite as UIComponent3D).flattenedRenderTree.firstChild : node.firstChild;
					if (batcherTree.firstChild == null)
					{
						// new branch found
						var batchNode:TreeNode = getNewBatchingNode(renderTreeFirstChild.value);
						batcherTree.addNode(batchNode);
					}
					
					if (_debug)
					{
						log('preparing batchers for ' + renderTreeFirstChild.value);
					}
					
					prepareBatchers(
						renderTreeFirstChild,
						batcherTree.firstChild,
						sprite.camera != null ? sprite : cameraOwner
					);
					// restoring actual batcher to make insertions into 
					// currentBatcher = _currentBatcher != null ? _currentBatcher : (_listSpriteBatchers.length == 0 ? null : _listSpriteBatchers[_listSpriteBatchers.length - 1]);
					sprite.addedToScene = true;
				}
				else
				{
					if (sprite is IVertexBatcher)
					{
						_listSpriteBatchers.splice(_batcherInsertPosition, 0, sprite);
						_batcherInsertPosition++;
						(sprite as IVertexBatcher).cameraOwner = cameraOwner;
						(batcherTree.value as BatchingInfo).batcher = sprite as IVertexBatcher;
						_lastBatchedChild = sprite;
						_lastBatchedChildBatcher = (batcherTree.value as BatchingInfo).batcher;
						_currentBatcher = null;
					}
					else if (!(sprite is Sprite3DContainer))
					{
						var textureAtlasID:String;
						if (sprite.textureID == null)
						{
							textureAtlasID = null;
						}
						else
						{
							var atlasData:TextureAtlasData = _textureManager.getAtlasDataByTextureID(sprite.textureID);
							if (atlasData == null)
							{
								if (_enableTextureCreatedCheck)
								{
									throw new Scene3DError("Scene3D/prepareBatchers(): Texture with id \"" + sprite.textureID + "\" is referenced but was never created!");
								}
								else
								{
									textureAtlasID = null;
								}
							}
							else
							{
								textureAtlasID = atlasData.atlasID;
							}
						}
						var container:Sprite3DContainer = sprite.parent as Sprite3DContainer;
						var maxSpritesPerBacther:Boolean = _currentBatcher is SpriteBatcher && _currentBatcher != null && (_currentBatcher as SpriteBatcher).numSprites >= MAX_SPRITES_PER_BATCHER;
						var candidateBatcher:SpriteBatcher = _currentBatcher as SpriteBatcher;
						if (maxSpritesPerBacther)
						{
							if (_debug)
							{
								log('maxSpritesPerBacther reached');
							}
							
							candidateBatcher = null;
						}
						
						var newBatcher:IVertexBatcher = pushToSuitableSpriteBacther(candidateBatcher, sprite, textureAtlasID, cameraOwner);
						if (newBatcher !== candidateBatcher)
						{
							if (_debug)
							{
								log('adding new bacther');
							}
							
							if (_lastBatchedChild != null &&
								_currentBatcher != null &&
								_currentBatcher is SpriteBatcher &&
								_lastBatchedChild !== (_currentBatcher as SpriteBatcher).getLastChild()
							)
							{
								var tailBatcher:SpriteBatcher;
								tailBatcher = (_currentBatcher as SpriteBatcher).splitAfterChild(_lastBatchedChild);
								if (tailBatcher != null)
								{
									_listSpriteBatchers.splice(_batcherInsertPosition, 0, tailBatcher);
									
									if (_debug)
									{
										log('last batcher splitted and inserted to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length + ' position. tail batcher:\n' + tailBatcher);
									}
									
									_hashBatchersOldToNew[_currentBatcher] = tailBatcher;
									_hashChangeBatchersLater[_currentBatcher] = true;
									_hashWaitForSprite[sprite] = _currentBatcher;
								}
							}
							_listSpriteBatchers.splice(_batcherInsertPosition, 0, newBatcher);
							if (_debug)
							{
								log('new batcher inserted to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length + ' position\n' + newBatcher);
							}
							_batcherInsertPosition++;
							_currentBatcher = newBatcher;
							//_currentBatcher = currentBatcher;
						}
						else
						{
							if (_debug)
							{
								log('sprite added to current bacther\n' + _currentBatcher);
							}
							
						}
						_lastBatchedChild = sprite;
						_lastBatchedChildBatcher = _currentBatcher;
						(batcherTree.value as BatchingInfo).batcher = _currentBatcher;
					}
				}
				
				node = node.nextSibling;
				
				if (node != null && batcherTree.nextSibling == null)
				{
					batchNode = getNewBatchingNode(node.value);
					batcherTree.parent.insertNodeAfter(batcherTree, batchNode);
				}
				batcherTree = batcherTree.nextSibling;
			}
		}
		
		/**
		 * Adding sprite to proper batcher either passed or new one
		 **/
		private function pushToSuitableSpriteBacther(candidateBatcher:SpriteBatcher, child:Sprite3D, textureAtlasID:String, cameraOwner:Sprite3D, createNewBatcher:Boolean = true):SpriteBatcher
		{
			var batcherCreated:Boolean = false;
			if (candidateBatcher != null &&
				(
					candidateBatcher.textureAtlasID != textureAtlasID ||
					candidateBatcher.shader !== child.shader ||
					candidateBatcher.blendMode !== child._blendMode ||
					candidateBatcher.cameraOwner !== cameraOwner
				))
			{
				if (!createNewBatcher)
				{
					return null;
				}
				
				candidateBatcher = null;
			}
			
			if (candidateBatcher == null)
			{
				candidateBatcher = new SpriteBatcher(this);
				candidateBatcher.shader = child.shader;
				candidateBatcher.blendMode = child._blendMode;
				candidateBatcher.textureAtlasID = textureAtlasID;
				candidateBatcher.cameraOwner = cameraOwner;
				batcherCreated = true;
			}
			
			if (!batcherCreated && _lastBatchedChild != null)
			{
				if (_debug)
				{
					log(child + ' added to batcher ' + StringUtils.getObjectAddress(candidateBatcher) + ' after ' + _lastBatchedChild); 
				}
				candidateBatcher.addChildAfter(_lastBatchedChild, child);
			}
			else
			{
				if (_debug)
				{
					log(child + ' added to batcher ' + StringUtils.getObjectAddress(candidateBatcher)); 
				}
				candidateBatcher.addChild(child);
			}
			child.addedToScene = true;
			
			return candidateBatcher;
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
				_lastBatchedChildBatcher = null;
				_currentBatcher = null;
				_batcherInsertPosition = 0;
				
				_log = null;
				
				if (_listSpriteBatchers != null && _listSpriteBatchers.length > 0)
				{
					_hashBatchersOldToNew = new Dictionary();
					_hashChangeBatchersLater = new Dictionary();
					_hashWaitForSprite = new Dictionary();
					
					//traceTrees();
					
					//trace('==============================');
					checkBatchingTree(localRenderTree, _bacthingTree);
					
					//traceTrees();
				}
				else
				{
					resetChangeFlags(localRenderTree);
					
					_doBatching = true;
					
					_listSpriteBatchers = new Vector.<IVertexBatcher>();
					_bacthingTree = getNewBatchingNode(this);
					prepareBatchers(localRenderTree, _bacthingTree, null);
				}
				
				if (_debug)
				{
					saveLog();
					
					traceTrees();
				}
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
		
		private var _debug:Boolean = false;
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
