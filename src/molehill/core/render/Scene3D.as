package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.desktop.Clipboard;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	
	import utils.ObjectUtils;
	
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
		
		/**
		 * private
		 **/
		private function compareTrees():Boolean
		{
			return ObjectUtils.traceTree(localRenderTree) == ObjectUtils.traceTree(_bacthingTree);
		}
		
		public var globalTraceString:String = "";
		private function traceTrees():void
		{
			globalTraceString += getTimer()/ 1000 + "\n\n";
			globalTraceString += ObjectUtils.traceTree(localRenderTree);
			globalTraceString += '\n-----------------\n';
			globalTraceString += ObjectUtils.traceTree(_bacthingTree);
			globalTraceString += '\n================================\n\n';
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
		private function checkBatchingTree(renderTree:TreeNode, batchingTree:TreeNode, cameraOwner:Sprite3D = null):void
		{
			var batchNode:TreeNode
			if (renderTree == null)
			{
				return;
			}
			
			while (renderTree != null)
			{
				if (renderTree.value is UIComponent3D)
				{
					(renderTree.value as UIComponent3D).updateFlattnedTree();
				}
				
				//trace(treeNode.value, batchingTree.value);
				
				// sprites in render and batching tree aren't the same in this node
				// need to sync trees
				if (renderTree.value !== (batchingTree.value as BatchingInfo).child)
				{
					if (!(renderTree.value as Sprite3D).addedToScene)
					{
						// new child was added to render tree
						batchNode = new TreeNode(
							new BatchingInfo(renderTree.value)
						);
						
						var treeParent:TreeNode = renderTree.parent;
						var prevSibling:TreeNode = renderTree.prevSibling;
						treeParent.removeNode(renderTree);
						prepareBatchers(renderTree, batchNode, cameraOwner);
						
						// addind new node to batching tree
						if (prevSibling != null)
						{
							treeParent.insertNodeAfter(prevSibling, renderTree);
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
								new BatchingInfo(renderTree.value)
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
				
				if (renderTree.hasChildren)
				{
					var container:Sprite3DContainer = renderTree.value as Sprite3DContainer;
					
					// found new non-empty container in render tree
					// adding children tom bacthing
					if (!batchingTree.hasChildren)
					{
						// adding new empty container to batching
						batchNode = new TreeNode(
							new BatchingInfo(renderTree.firstChild.value)
						);
						var firstChild:TreeNode = renderTree.firstChild;
						renderTree.removeNode(firstChild);
						prepareBatchers(firstChild, batchNode, cameraOwner);
						renderTree.addAsFirstNode(firstChild);
						batchingTree.addAsFirstNode(batchNode);
					}
					
					checkBatchingTree(
						container is UIComponent3D ? (container as UIComponent3D).flattenedRenderTree.firstChild : renderTree.firstChild,
						batchingTree.firstChild,
						(renderTree.value as Sprite3D).camera != null ? renderTree.value as Sprite3D : cameraOwner
					);
					
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
					removeNodeReferences(batchingTree);
					
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
					var batcher:SpriteBatcher = batchingInfo.batcher as SpriteBatcher;
					if (batcher != null)
					{
						batcher.removeChild(batchingInfo.child);
						batchingInfo.child.addedToScene = false;
						if (batcher.numSprites <= 0)
						{
							_listSpriteBatchers.splice(
								_listSpriteBatchers.indexOf(batchingInfo.batcher), 1
							);
						}
					}
					else if (batchingInfo.batcher === batchingInfo.child)
					{
						_listSpriteBatchers.splice(
							_listSpriteBatchers.indexOf(batchingInfo.batcher), 1
						);
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
			var currentBatcher:IVertexBatcher = _currentBatcher != null ? _currentBatcher : (_listSpriteBatchers.length == 0 ? null : _listSpriteBatchers[_listSpriteBatchers.length - 1]);
			var node:TreeNode = renderTree;
			if (node == null)
			{
				return;
			}
			
			while (node != null)
			{
				var sprite:Sprite3D = node.value as Sprite3D;
				if (node.hasChildren)
				{
					if (sprite is UIComponent3D)
					{
						(sprite as UIComponent3D).updateFlattnedTree();
					}
					
					var renderTreeFirstChild:TreeNode = sprite is UIComponent3D ? (sprite as UIComponent3D).flattenedRenderTree.firstChild : node.firstChild;
					if (batcherTree.firstChild == null)
					{
						// new branch found
						var batchNode:TreeNode = new TreeNode(
							new BatchingInfo(renderTreeFirstChild.value)
						);
						batcherTree.addNode(batchNode);
					}
					
					prepareBatchers(
						renderTreeFirstChild,
						batcherTree.firstChild,
						sprite.camera != null ? sprite : cameraOwner
					);
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
						currentBatcher = null;
					}
					else if (!(sprite is Sprite3DContainer))
					{
						var textureAtlasID:String = sprite.textureID == null ? null : _textureManager.getAtlasDataByTextureID(sprite.textureID).atlasID;
						var container:Sprite3DContainer = sprite.parent as Sprite3DContainer;
						if (!(currentBatcher is SpriteBatcher) || 
							(currentBatcher != null &&
							(currentBatcher as SpriteBatcher).numSprites >= MAX_SPRITES_PER_BATCHER)
						)
						{
							currentBatcher = null;
						}
						
						var newBatcher:IVertexBatcher = pushToSuitableSpriteBacther(currentBatcher as SpriteBatcher, sprite, textureAtlasID, cameraOwner);
						if (newBatcher !== currentBatcher)
						{
							if (_lastBatchedChild != null &&
								currentBatcher != null
								&&_lastBatchedChild !== (currentBatcher as SpriteBatcher).getLastChild()
							)
							{
								var tailBatcher:SpriteBatcher = (currentBatcher as SpriteBatcher).splitAfterChild(_lastBatchedChild);
								if (tailBatcher != null)
								{
									_listSpriteBatchers.splice(_batcherInsertPosition, 0, tailBatcher);
									
									_hashBatchersNewToOld[tailBatcher] = currentBatcher;
									while (_hashBatchersNewToOld[currentBatcher] != null)
									{
										currentBatcher = _hashBatchersNewToOld[currentBatcher];
									}
									_hashBatchersOldToNew[currentBatcher] = tailBatcher;
								}
							}
							_listSpriteBatchers.splice(_batcherInsertPosition, 0, newBatcher);
							_batcherInsertPosition++;
							currentBatcher = newBatcher;
						}
						_lastBatchedChild = sprite;
						(batcherTree.value as BatchingInfo).batcher = currentBatcher;
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
		private function pushToSuitableSpriteBacther(candidateBatcher:SpriteBatcher, child:Sprite3D, textureAtlasID:String, cameraOwner:Sprite3D):SpriteBatcher
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
				candidateBatcher.addChildAfter(_lastBatchedChild, child);
			}
			else
			{
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
		
		private function renderScene():void
		{
			var i:int = 0;
			var spriteBatcher:SpriteBatcher;
			if (_needUpdateBatchers)
			{
				_lastBatchedChild = null;
				_currentBatcher = null;
				if (_listSpriteBatchers != null && _listSpriteBatchers.length > 0)
				{
					_hashBatchersOldToNew = new Dictionary();
					_hashBatchersNewToOld = new Dictionary();
					
					//traceTrees();
					
					checkBatchingTree(localRenderTree, _bacthingTree);
					
					// traceTrees();
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
				if (_renderEngine != null)
				{
					renderInfo.mode =
						_renderEngine.renderMode;
				}
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
	}
}
