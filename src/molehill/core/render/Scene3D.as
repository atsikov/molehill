package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
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
			return ObjectUtils.traceTree(localTreeRoot) == ObjectUtils.traceTree(_bacthingTree);
		}
		
		private function traceTrees():void
		{
			trace(ObjectUtils.traceTree(localTreeRoot));
			trace('-----------------');
			trace(ObjectUtils.traceTree(_bacthingTree));
			trace('================================');
		}
		
		molehill_internal var _needUpdateBatchers:Boolean = false;
		private var _listSpriteBatchers:Vector.<IVertexBatcher>;
		private var _enterFrameListener:Sprite;
		
		private var _currentBatcher:IVertexBatcher;
		private var _lastBatchedChild:Sprite3D;
		private var _batcherInsertPosition:uint;
		
		private var _hashBatchersOldToNew:Dictionary;
		private var _hashBatchersNewToOld:Dictionary;
		private function checkBatchingTree(treeNode:TreeNode, batchingTree:TreeNode, cameraOwner:Sprite3D = null):void
		{
			var batchNode:TreeNode
			if (treeNode == null)
			{
				return;
			}
			
			while (treeNode != null)
			{
				//trace(treeNode.value, batchingTree.value);
				if (treeNode.value !== (batchingTree.value as BatchingInfo).child)
				{
					if (!(treeNode.value as Sprite3D).addedToScene)
					{
						// new child added to render tree
						batchNode = new TreeNode(
							new BatchingInfo(treeNode.value)
						);
						
						var treeParent:TreeNode = treeNode.parent;
						var prevSibling:TreeNode = treeNode.prevSibling;
						treeParent.removeNode(treeNode);
						prepareBatchers(treeNode, batchNode, cameraOwner);
						
						if (prevSibling != null)
						{
							treeParent.insertNodeAfter(prevSibling, treeNode);
						}
						else
						{
							treeParent.addAsFirstNode(treeNode);
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
						// need to remove child from batching
						var prevNode:TreeNode = treeNode.prevSibling;
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
							treeParent = treeNode.parent;
							
							batchNode = new TreeNode(
								new BatchingInfo(treeNode.value)
							);
							treeParent.removeNode(treeNode);
							prepareBatchers(treeNode, batchNode, cameraOwner);
							if (prevNode != null)
							{
								treeParent.insertNodeAfter(prevNode, treeNode);
							}
							else
							{
								treeParent.addAsFirstNode(treeNode);
							}
							
							batchingParent.addNode(batchNode);
							
							batchingTree = batchNode;
						}
					}
				}
				
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
				
				if (treeNode.hasChildren)
				{
					var container:Sprite3DContainer = treeNode.value as Sprite3DContainer;
					
					if (!batchingTree.hasChildren)
					{
						// adding new empty container to batching
						batchNode = new TreeNode(
							new BatchingInfo(treeNode.firstChild.value)
						);
						var firstChild:TreeNode = treeNode.firstChild;
						treeNode.removeNode(firstChild);
						prepareBatchers(firstChild, batchNode, cameraOwner);
						treeNode.addAsFirstNode(firstChild);
						batchingTree.addAsFirstNode(batchNode);
					}
					
					checkBatchingTree(treeNode.firstChild, batchingTree.firstChild, (treeNode.value as Sprite3D).camera != null ? treeNode.value as Sprite3D : cameraOwner);
					
					// scroll rect changed
					if (container.cameraChanged)
					{
						container.cameraChanged = false;
						
						_cameraOwner = container;
						setCameraOwner(batchingTree.firstChild, _cameraOwner);
						
						_cameraOwner = null;
					}
					
				}
				
				if (treeNode.nextSibling != null && batchingTree.nextSibling == null)
				{
					// need to add new branch at the end of the current
					batchNode = new TreeNode(
						new BatchingInfo(treeNode.nextSibling.value)
					);
					
					var nextSibling:TreeNode = treeNode.nextSibling;
					treeNode.parent.removeNode(nextSibling);
					prepareBatchers(nextSibling, batchNode, cameraOwner);
					treeNode.parent.insertNodeAfter(treeNode, nextSibling);
					
					batchingTree.parent.addNode(batchNode);
				}
				
				treeNode = treeNode.nextSibling;
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
		private function prepareBatchers(root:TreeNode, batcherTreeNode:TreeNode, cameraOwner:Sprite3D):void
		{
			var currentBatcher:IVertexBatcher = _currentBatcher != null ? _currentBatcher : (_listSpriteBatchers.length == 0 ? null : _listSpriteBatchers[_listSpriteBatchers.length - 1]);
			var node:TreeNode = root;
			if (node == null)
			{
				return;
			}
			
			while (node != null)
			{
				var sprite:Sprite3D = node.value as Sprite3D;
				/*if (sprite is UIComponent3D)
				{
					prepareUIComponentBuffers();
					parseUIComponent((sprite as Sprite3DContainer).localTreeRoot);
					flushUIComponentBuffers();
					
					currentBatcher = null;
				}
				else */if (node.hasChildren)
				{
					if (batcherTreeNode.firstChild == null)
					{
						// new branch found
						var batchNode:TreeNode = new TreeNode(
							new BatchingInfo(node.firstChild.value)
						);
						batcherTreeNode.addNode(batchNode);
					}
					
					prepareBatchers(node.firstChild, batcherTreeNode.firstChild, sprite.camera != null ? sprite : cameraOwner);
					sprite.addedToScene = true;
				}
				else
				{
					if (sprite is IVertexBatcher)
					{
						_listSpriteBatchers.splice(_batcherInsertPosition, 0, sprite);
						_batcherInsertPosition++;
						(sprite as IVertexBatcher).cameraOwner = cameraOwner;
						(batcherTreeNode.value as BatchingInfo).batcher = sprite as IVertexBatcher;
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
						(batcherTreeNode.value as BatchingInfo).batcher = currentBatcher;
					}
				}
				
				node = node.nextSibling;
				
				if (node != null && batcherTreeNode.nextSibling == null)
				{
					batchNode = new TreeNode(
						new BatchingInfo(node.value)
					);
					batcherTreeNode.parent.insertNodeAfter(batcherTreeNode, batchNode);
				}
				batcherTreeNode = batcherTreeNode.nextSibling;
			}
		}
		
		private var _listUiTextBatchers:Vector.<SpriteBatcher>;
		private var _listUiBackBatchers:Vector.<SpriteBatcher>;
		private var _listUiMiscBatchers:Vector.<SpriteBatcher>;
		private function prepareUIComponentBuffers():void
		{
			if (_listUiBackBatchers == null)
			{
				_listUiBackBatchers = new Vector.<SpriteBatcher>();
			}
			if (_listUiMiscBatchers == null)
			{
				_listUiMiscBatchers = new Vector.<SpriteBatcher>();
			}
			if (_listUiTextBatchers == null)
			{
				_listUiTextBatchers = new Vector.<SpriteBatcher>();
			}
		}
		
		private function flushUIComponentBuffers():void
		{
			while (_listUiBackBatchers.length > 0)
			{
				_listSpriteBatchers.push(
					_listUiBackBatchers.shift()
				);
			}
			
			while (_listUiMiscBatchers.length > 0)
			{
				_listSpriteBatchers.push(
					_listUiMiscBatchers.shift()
				);
			}
			
			while (_listUiTextBatchers.length > 0)
			{
				_listSpriteBatchers.push(
					_listUiTextBatchers.shift()
				);
			}
		}
		
		// TODO: implement UI component parsing using new batching tree system
		private function parseUIComponent(root:TreeNode, cameraOwner:Sprite3DContainer = null):void
		{
			var currentBackBatcher:SpriteBatcher = _listUiBackBatchers.length == 0 ? null : _listUiBackBatchers[_listUiBackBatchers.length - 1];
			var currentMiscBatcher:SpriteBatcher = _listUiMiscBatchers.length == 0 ? null : _listUiMiscBatchers[_listUiMiscBatchers.length - 1];
			var currentTextBatcher:SpriteBatcher = _listUiTextBatchers.length == 0 ? null : _listUiTextBatchers[_listUiTextBatchers.length - 1];
			var tm:TextureManager = TextureManager.getInstance();
			
			var node:TreeNode = root.firstChild;
			var newBatcher:SpriteBatcher;
			
			while (node != null)
			{
				var child:Sprite3D = node.value;
				if (child is TextField3D)
				{
					if ((child as Sprite3DContainer).numChildren > 0)
					{
						var textureAtlasID:String = tm.getAtlasDataByTextureID(child.textureID).atlasID;
						var shader:Shader3D = (child as Sprite3DContainer).shader;
						var blendMode:String = (child as Sprite3DContainer).blendMode;
						
						if (currentTextBatcher != null &&
							(currentTextBatcher.shader != shader ||
							currentTextBatcher.textureAtlasID != textureAtlasID ||
							currentTextBatcher.blendMode != blendMode)							
						)
						{
							currentTextBatcher = null;
						}
						
						if (currentTextBatcher == null)
						{
							currentTextBatcher = new SpriteBatcher(this);
							currentTextBatcher.blendMode = blendMode;
							currentTextBatcher.shader = shader;
							currentTextBatcher.textureAtlasID = textureAtlasID;
							currentTextBatcher.cameraOwner = cameraOwner;
							_listUiTextBatchers.push(currentTextBatcher);
						}
						
						currentTextBatcher.pushSpriteContainerTree(child as Sprite3DContainer);
					}
					node = node.nextSibling;
					continue;
				}
				else if (node.hasChildren)
				{
					parseUIComponent(node, child.camera != null ? child as Sprite3DContainer : cameraOwner);
				}
				else
				{
					textureAtlasID = child.textureID == null ? null : tm.getAtlasDataByTextureID(child.textureID).atlasID;
					if (child.isBackground)
					{
						newBatcher = pushToSuitableSpriteBacther(currentBackBatcher, child, textureAtlasID, cameraOwner);
						if (newBatcher !== currentBackBatcher)
						{
							_listUiBackBatchers.push(newBatcher);
							currentBackBatcher = newBatcher;
						}
					}
					else
					{
						newBatcher = pushToSuitableSpriteBacther(currentMiscBatcher, child, textureAtlasID, cameraOwner);
						if (newBatcher !== currentMiscBatcher)
						{
							_listUiMiscBatchers.push(newBatcher);
							currentMiscBatcher = newBatcher;
						}
					}
				}
				
				node = node.nextSibling;
			}
		}
		
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
					
					checkBatchingTree(localTreeRoot, _bacthingTree);
					/*
					if (!compareTrees())
					{
						traceTrees();
					}
					*/
				}
				else
				{
					resetChangeFlags(localTreeRoot);
					
					_doBatching = true;
					
					_listSpriteBatchers = new Vector.<IVertexBatcher>();
					_bacthingTree = new TreeNode(
						new BatchingInfo(this)
					);
					prepareBatchers(localTreeRoot, _bacthingTree, null);
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
					left = batcher.batcherCamera.scrollX;
					right = batcher.batcherCamera.scrollY;
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
		
		public var renderInfo:String = "";
		
		private var _lastTexture:Texture;
		private var _t:uint;
		private function onRenderEnterFrame(event:Event):void
		{
			if (_renderEngine == null || !_renderEngine.isReady)
			{
				if (_renderEngine != null)
				{
					renderInfo =
						"Render mode: " + (_renderEngine as RenderEngine).renderMode;
				}
				return;
			}
			
			renderScene();
			
			_renderEngine.present();
			
			var numBitmapAtlases:int = TextureManager.getInstance().numBitmapAtlases;
			var numCompressedAtlases:int = TextureManager.getInstance().numCompressedAtlases;
			renderInfo =
				"Render mode: " + (_renderEngine as RenderEngine).renderMode +
				"\nDraw calls: " +
				(_renderEngine as RenderEngine).drawCalls +
				"\nTotal tris: " + (_renderEngine as RenderEngine).totalTris +
				"\nTexture atlases: " + (numBitmapAtlases + numCompressedAtlases).toString() + " (" + numBitmapAtlases + " bitmaps, " + numCompressedAtlases + " compressed)" +
				"\nRendering to " + _renderEngine.getViewportWidth() + " x " + _renderEngine.getViewportHeight();
		}
	}
}
