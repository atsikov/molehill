package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
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
			
			_enterFrameListener = new Sprite();
			_enterFrameListener.addEventListener(Event.EXIT_FRAME, onRenderEnterFrame);
			
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
		
		public function setRenderEngine(value:RenderEngine):void
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
			globalTraceString += ObjectUtils.traceObject(_listSpriteBatchers);
			globalTraceString += '\n================================\n\n';
			
			DebugLogger.writeExternalLog(globalTraceString);
		}
		
		molehill_internal var _needUpdateBatchers:Boolean = false;
		private var _listSpriteBatchers:Vector.<IVertexBatcher>;
		private var _enterFrameListener:Sprite;
		
		private var _currentBatcher:IVertexBatcher;
		private var _lastBatchedChild:Sprite3D;
		private var _batcherInsertPosition:uint;
		
		private var _hashBatchersOldToNew:Dictionary;
		private var _hashBatchersNewToOld:Dictionary;
		
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
				
				if ((sprite.currentAtlasData != null &&
					sprite.currentAtlasData.atlasID !== (batchingTree.value as BatchingInfo).batcher.textureAtlasID) ||
					(sprite.currentAtlasData == null &&
					(batchingTree.value as BatchingInfo).batcher != null &&
					(batchingTree.value as BatchingInfo).batcher.textureAtlasID != null))
				{
					var currentBatcher:SpriteBatcher = (batchingTree.value as BatchingInfo).batcher as SpriteBatcher;
					while (_hashBatchersOldToNew[currentBatcher] != null)
					{
						currentBatcher = _hashBatchersOldToNew[currentBatcher];
					}
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
						batchNode = new TreeNode(
							new BatchingInfo(sprite)
						);
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
						batchNode = new TreeNode(
							new BatchingInfo(sprite)
						);
						
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
							
							batchNode = new TreeNode(
								new BatchingInfo(sprite)
							);
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
				/*else if (
					sprite.currentAtlasData == null &&
					(batchingTree.value as BatchingInfo).batcher != null &&
					(batchingTree.value as BatchingInfo).batcher.textureAtlasID !== null
					||
					sprite.currentAtlasData != null &&
					sprite.currentAtlasData.atlasID !== (batchingTree.value as BatchingInfo).batcher.textureAtlasID)
				{
					// child's texture atlas changed
					// need to remove child from current batcher and push to suitable one
					if (_debug)
					{
						log('child texture changed');
					}
					var currentBatcher:SpriteBatcher = (batchingTree.value as BatchingInfo).batcher as SpriteBatcher;
					var insertHead:Boolean = false;
					while (_hashBatchersOldToNew[currentBatcher] != null)
					{
						currentBatcher = _hashBatchersOldToNew[currentBatcher];
						insertHead = true;
					}
					if (_debug)
					{
						log('insertHead = ' + insertHead + '; currentBatcher:\n' + currentBatcher);
					}
					if (currentBatcher != null)
					{
						var newBatcher:SpriteBatcher = pushToSuitableSpriteBacther(_currentBatcher as SpriteBatcher, sprite, sprite.currentAtlasData.atlasID, cameraOwner, false);
						if (newBatcher == null)
						{
							newBatcher = pushToSuitableSpriteBacther(_currentBatcher as SpriteBatcher, sprite, sprite.currentAtlasData.atlasID, cameraOwner);
						}
						
						if (newBatcher === _currentBatcher)
						{
							if (_debug)
							{
								log('added to last _currentBatcher\n' + _currentBatcher);
							}
							currentBatcher.removeChild(sprite);
							if (currentBatcher.numSprites == 0)
							{
								_listSpriteBatchers.splice(
									_listSpriteBatchers.indexOf(currentBatcher),
									1
								);
								currentBatcher.onContextRestored();
							}
						}
						else if (newBatcher !== currentBatcher)
						{
							if (sprite !== currentBatcher.getFirstChild() && currentBatcher.numSprites > 1)
							{
								var tailBatcher:SpriteBatcher = currentBatcher.splitAfterChild(sprite);
								if (tailBatcher != null)
								{
									if (_debug)
									{
										log('splitting current batcher. tail batcher\n' + tailBatcher);
									}
									if (!insertHead)
									{
										_listSpriteBatchers.splice(
											_batcherInsertPosition,
											0,
											tailBatcher
										);
										if (_debug)
										{
											log('adding tail batcher to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length);
										}
									}
									else
									{
										_listSpriteBatchers.splice(
											_batcherInsertPosition,
											0,
											currentBatcher
										);
										if (_debug)
										{
											log('relocating current batcher to ' + _batcherInsertPosition + ' / ' + _listSpriteBatchers.length);
										}
										_batcherInsertPosition++;
									}
									
									_hashBatchersNewToOld[tailBatcher] = currentBatcher;
									while (_hashBatchersNewToOld[currentBatcher] != null)
									{
										currentBatcher = _hashBatchersNewToOld[currentBatcher];
									}
									_hashBatchersOldToNew[currentBatcher] = tailBatcher;
								}
							}
							
							currentBatcher.removeChild(sprite);
							
							if (currentBatcher !== newBatcher)
							{
								if (currentBatcher.numSprites > 0)
								{
									_listSpriteBatchers.splice(
										_batcherInsertPosition,
										0,
										newBatcher
									);
								}
								else
								{
									_listSpriteBatchers[_batcherInsertPosition] = newBatcher;
								}
							}
							else
							{
								if (currentBatcher.numSprites == 0)
								{
									_listSpriteBatchers.splice(
										_listSpriteBatchers.indexOf(currentBatcher),
										0
									);
								}
							}
						}
						(batchingTree.value as BatchingInfo).batcher = newBatcher;
					}
				}*/
				
				// saving current batcher to use for insertion if got new suitable unbatched sprite
				if ((batchingTree.value as BatchingInfo).batcher != null)
				{
					var oldBatcher:IVertexBatcher = (batchingTree.value as BatchingInfo).batcher;
					if (_hashBatchersOldToNew[oldBatcher] != null)
					{
						(batchingTree.value as BatchingInfo).batcher = _hashBatchersOldToNew[oldBatcher];
					}
					
					if (_currentBatcher !== (batchingTree.value as BatchingInfo).batcher)
					{
						_currentBatcher = (batchingTree.value as BatchingInfo).batcher;
						_batcherInsertPosition = _currentBatcher == null ? 0 : _listSpriteBatchers.indexOf(_currentBatcher) + 1;
					}
					_lastBatchedChild = (batchingTree.value as BatchingInfo).child;
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
							batchNode = new TreeNode(
								new BatchingInfo(containerRenderTree.firstChild.value)
							);
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
					batchNode = new TreeNode(
						new BatchingInfo(renderTree.nextSibling.value)
					);
					
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
					var batcher:SpriteBatcher = batchingInfo.batcher as SpriteBatcher;
					
					if (_hashBatchersOldToNew[batcher] != null)
					{
						batchingInfo.batcher = _hashBatchersOldToNew[batcher];
						batcher = _hashBatchersOldToNew[batcher];
					}
					
					if (batcher != null)
					{
						lastBatcher = batcher;
						_lastBatchedChild = batchingInfo.child;
					}
				}
				
				batchingTreeNode = batchingTreeNode.nextSibling;
			}
			
			if (lastBatcher != null)
			{
				_batcherInsertPosition = _listSpriteBatchers.indexOf(lastBatcher) + 1;
				_currentBatcher = lastBatcher;
			}
		}
		
		private function removeNodeReferences(node:TreeNode):void
		{
			while (node != null)
			{
				if (node.hasChildren)
				{
					removeNodeReferences(node.firstChild);
				}
				else
				{
					var batchingInfo:BatchingInfo = node.value as BatchingInfo;
					if (_debug)
					{
						log('removing ' + batchingInfo.child + ' from batching, batcher ' + StringUtils.getObjectAddress(batchingInfo.batcher));
					}
					var batcher:SpriteBatcher = batchingInfo.batcher as SpriteBatcher;
					while (_hashBatchersOldToNew[batcher] != null)
					{
						batcher = _hashBatchersOldToNew[batcher];
					}
					
					batchingInfo.child.addedToScene = false;
					if (batcher != null)
					{
						batcher.removeChild(batchingInfo.child);
						if (batcher.numSprites <= 0)
						{
							var index:int = _listSpriteBatchers.indexOf(batcher);
							_listSpriteBatchers.splice(index, 1);
							batcher.onContextRestored();
							if (_debug)
							{
								log('removing batcher from ' + index + ' position\n' + batcher);
							}
						}
					}
					else if (batchingInfo.batcher === batchingInfo.child)
					{
						index = _listSpriteBatchers.indexOf(batchingInfo.batcher)
						_listSpriteBatchers.splice(index, 1);
						batchingInfo.batcher.onContextRestored();
						if (_debug)
						{
							log('removing batcher from ' + index + ' position\n' + batchingInfo.batcher);
						}
					}
				}
				
				node = node.nextSibling;
			}
		}
		
		private var _doBatching:Boolean = false;
		private var _batchingTrigger:Sprite3D;
		
		private var _bacthingTree:TreeNode;
		
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
						var batchNode:TreeNode = new TreeNode(
							new BatchingInfo(renderTreeFirstChild.value)
						);
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
								throw new Scene3DError("Scene3D/prepareBatchers(): Texture with id \"" + sprite.textureID + "\" is referenced but was never created!");
							}
							
							textureAtlasID = atlasData.atlasID;
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
									
									_hashBatchersNewToOld[tailBatcher] = _currentBatcher;
									while (_hashBatchersNewToOld[_currentBatcher] != null)
									{
										_currentBatcher = _hashBatchersNewToOld[_currentBatcher];
									}
									_hashBatchersOldToNew[_currentBatcher] = tailBatcher;
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
						(batcherTree.value as BatchingInfo).batcher = _currentBatcher;
					}
				}
				
				node = node.nextSibling;
				
				if (node != null && batcherTree.nextSibling == null)
				{
					batchNode = new TreeNode(
						new BatchingInfo(node.value)
					);
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
		
		public function getScreenshot():BitmapData
		{
			if (_renderEngine == null || !_renderEngine.isReady)
			{
				return null;
			}
			
			renderScene();
			
			return (_renderEngine as RenderEngine).getScreenshot();
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
		
		private function renderScene():void
		{
			var i:int = 0;
			var spriteBatcher:SpriteBatcher;
			if (_needUpdateBatchers)
			{
				_lastBatchedChild = null;
				_currentBatcher = null;
				
				_log = null;
				
				if (_listSpriteBatchers != null && _listSpriteBatchers.length > 0)
				{
					_hashBatchersOldToNew = new Dictionary();
					_hashBatchersNewToOld = new Dictionary();
					
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
					_bacthingTree = new TreeNode(
						new BatchingInfo(this)
					);
					prepareBatchers(localRenderTree, _bacthingTree, null);
				}
				
				if (_debug)
				{
					saveLog();
					
					traceTrees();
				}
			}
			_needUpdateBatchers = false;
			
			_renderEngine.clear();
			
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
		private var _t:uint;
		private function onRenderEnterFrame(event:Event):void
		{
			if (_renderEngine == null || !_renderEngine.isReady)
			{
				return;
			}
			
			renderScene();
			
			_renderEngine.present();
			
			var numBitmapAtlases:int = TextureManager.getInstance().numBitmapAtlases;
			var numCompressedAtlases:int = TextureManager.getInstance().numCompressedAtlases;
			
			_renderInfo.mode = _renderEngine.renderMode;
			_renderInfo.drawCalls = _renderEngine.drawCalls;
			_renderInfo.totalTris = _renderEngine.totalTris;
			_renderInfo.numBitmapAtlases = numBitmapAtlases;
			_renderInfo.numCompressedAtlases = numCompressedAtlases;
		}
		
		private var _renderInfo:Object = new Object();
		public function get renderInfo():Object
		{
			return _renderInfo;
		}
		
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
