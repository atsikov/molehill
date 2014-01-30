package molehill.core.render
{
	import easy.collections.TreeNode;
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DBlendFactor;
	import flash.display3D.Context3DRenderMode;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import molehill.core.Scene3DManager;
	import molehill.core.render.engine.IRenderEngine;
	import molehill.core.render.engine.MolehillRenderEngine;
	import molehill.core.texture.TextureManager;

	public class Scene3D
	{
		public static const MAX_SPRITES_PER_BATCHER:uint = 256;
		
		private var _textureManager:TextureManager;
		private var _renderTreeRoot:TreeNode;
		public function Scene3D()
		{
			_textureManager = TextureManager.getInstance();
			
			_listSpriteBatchers = new Vector.<IVertexBatcher>();
			
			_enterFrameListener = new Sprite();
			
			var timer:Timer = new Timer(1000 / 60);
			_enterFrameListener.addEventListener(Event.ENTER_FRAME, onRenderEnterFrame);
			
			_renderTreeRoot = new TreeNode();
			
			_hashStaticBatchers = new Dictionary();
			_hashStaticBatchersChanged = new Dictionary();
		}
		
		private var _renderEngine:IRenderEngine;
		public function get isActive():Boolean
		{
			return _renderEngine != null && _renderEngine.isReady;
		}
		
		public function setRenderEngine(value:IRenderEngine):void
		{
			_renderEngine = value;
		}
		
		/**
		 * public
		 **/
		//private var _listAllChildren:Vector.<Sprite3D>;
		//private var _listUnassignedChildren:Vector.<Sprite3D>;
		internal var _needUpdateBatchers:Boolean = false;
		public function addChild(child:Sprite3D):void
		{
			child.setScene(this);
			if (child is Sprite3DContainer)
			{
				updateLocalTree(
					(child as Sprite3DContainer).localTreeRoot
				);
				_renderTreeRoot.addNode(
					(child as Sprite3DContainer).localTreeRoot
				);
			}
			else
			{
				var childNode:TreeNode = new TreeNode(child);
				_renderTreeRoot.addNode(childNode);
			}
			
			_needUpdateBatchers = true;
		}
		
		private function updateLocalTree(root:TreeNode):void
		{
			var node:TreeNode = root.firstChild;
			while (node != null)
			{
				if (node.hasChildren)
				{
					updateLocalTree(node);
				}
				(node.value as Sprite3D).setScene(this);
				node = node.nextSibling;
			}
		}
		/*
		public function addChildAt(child:Sprite3D, index:int):void
		{
			if (index > numChildren)
			{
				// throw error
				return;
			}
			
			var texture:Texture = _textureManager.getTextureByID(child.textureID);
			if (texture == null)
			{
				var childIndex:int = _listAllChildren.indexOf(child);
				if (childIndex != -1)
				{
					
				}
				
				_listAllChildren.splice(index, 0, child);
				return;
			}
			
			var batcher:SpriteBatcher;
			var newBatcher:SpriteBatcher;
			var j:int = 0;
			var numAssignedSprites:int = 0;
			while (j < _listSpriteBatchers.length)
			{
				batcher = _listSpriteBatchers[j];
				if (numAssignedSprites + batcher.numSprites < (index + 1))
				{
					numAssignedSprites += batcher.numSprites
				}
				else
				{
					if (batcher.texture == texture)
					{
						// found batcher with the same texture
						// adding sprite inside
						batcher.addChildAt(sprite, index - numAssignedSprites);
					}
					else
					{
						// sprite isn't topmost
						// splitting batcher with another texture into two batchers and add new batcher between them
						newBatcher = new SpriteBatcher();
						newBatcher.texture = batcher.texture;
						newBatcher.context3D = _context3D;
						while (batcher.numSprites > index - numAssignedSprites)
						{
							var sprite:Sprite3D = batcher.getChildAt(index - numAssignedSprites);
							batcher.removeChild(sprite);
							newBatcher.addChild(sprite);
						}
						
						_listSpriteBatchers.splice(j + 1, 0, newBatcher);
						
						newBatcher = new SpriteBatcher();
						newBatcher.texture = texture;
						newBatcher.context3D = _context3D;
						newBatcher.addChild(child);
						_listSpriteBatchers.splice(j + 1, 0, newBatcher);
						
					}
					break;
				}
				
				j++;
			}
			
			if (j == _listSpriteBatchers.length)
			{
				addChild(sprite);
			}
		}
		*/
		public function removeChild(child:Sprite3D):void
		{
			var childNode:TreeNode = _renderTreeRoot.getNodeByValue(child);
			if (childNode != null)
			{
				childNode.parent.removeNode(childNode);
			}
			
			if (child is AnimatedSprite3D)
			{
				(child as AnimatedSprite3D).stop();
			}
			
			_needUpdateBatchers = true;
		}
		
		public function get numChildren():int
		{
			return 0; //_listAllChildren.length;
		}
		
		public function getChildIndex(child:Sprite3D):int
		{
			if (!contains(child))
			{
				//throw error?
				return -1;
			}
			
			return 0; //_listAllChildren.indexOf(child);
		}
		
		public function setChildIndex(child:Sprite3D, index:int):void
		{
			var childIndex:int = getChildIndex(child);
			if (childIndex == -1)
			{
				// throw error?
				return;
			}
			
			//_listAllChildren.splice(childIndex, 1);
			//_listAllChildren.splice(index, 0, child);
		}
		
		public function getTopmostChild():Sprite3D
		{
			return null/*_listSpriteBatchers.length == 0 ? null : _listSpriteBatchers[_listSpriteBatchers.length - 1].getTopmostChild()*/;
		}
		/*
		public function getChildAt(index:int):Sprite3D
		{
			if (index > numChildren)
			{
				// throw error?
				return null;
			}
			
			return null; //_listAllChildren[index];
		}
		*/
		private function findBatcherWithSprite(sprite:Sprite3D):SpriteBatcher
		{
			/*
			var batcher:SpriteBatcher;
			for (var i:int = 0; i < _listSpriteBatchers.length; i++)
			{
				batcher = _listSpriteBatchers[i];
				if (batcher.contains(sprite))
				{
					return batcher;
				}
			}
			*/
			return null;
		}
		
		public function contains(child:Sprite3D):Boolean
		{
			return findBatcherWithSprite(child) != null;
		}
		
		private var _needUpdateCameraMatrix:Boolean = false;
		private var _cameraPoint:Point = new Point();
		public function scrollTo(x:int, y:int):void
		{
			_cameraPoint.x = x;
			_cameraPoint.y = y;
			
			if (_renderEngine != null)
			{
				_renderEngine.setCameraPosition(
					_cameraPoint
				);
			}
		}
		
		public function get cameraX():Number
		{
			return _cameraPoint.x;
		}
		
		public function get cameraY():Number
		{
			return _cameraPoint.y;
		}
		
		/**
		 * private
		 **/
		private var _listSpriteBatchers:Vector.<IVertexBatcher>;
		private var _enterFrameListener:Sprite;
		
		private function prepareBatchers(root:TreeNode):void
		{
			var currentBatcher:IVertexBatcher = _listSpriteBatchers.length == 0 ? null : _listSpriteBatchers[_listSpriteBatchers.length - 1];
			var tm:TextureManager = TextureManager.getInstance();
			var node:TreeNode = root.firstChild;
			while (node != null)
			{
				if (node.hasChildren)
				{
					prepareBatchers(node);
				}
				var sprite:Sprite3D = node.value as Sprite3D;
				if (sprite is IVertexBatcher)
				{
					_listSpriteBatchers.push(sprite as IVertexBatcher);
					currentBatcher = null;
				}
				else if (!(sprite is Sprite3DContainer))
				{
					var textureAtlasID:String = tm.getAtlasIDByTexture(
						tm.getTextureByID(sprite.textureID)
					);
					var container:Sprite3DContainer = sprite.parent as Sprite3DContainer;
					var staticBatching:Boolean = container != null ? container.staticBatching : false;
					if (!(currentBatcher is SpriteBatcher) || 
						(currentBatcher != null &&
						(
							currentBatcher.textureAtlasID != textureAtlasID ||
							((currentBatcher as SpriteBatcher).numSprites == MAX_SPRITES_PER_BATCHER && !staticBatching)||
							currentBatcher.preRenderFunction !== sprite.preRenderFunction ||
							currentBatcher.postRenderFunction !== sprite.postRenderFunction ||
							currentBatcher.blendMode !== sprite._blendMode
						))
					)
					{
						currentBatcher = null;
					}
					if (currentBatcher == null)
					{
						currentBatcher = new SpriteBatcher(this);
						currentBatcher.preRenderFunction = sprite.preRenderFunction;
						currentBatcher.postRenderFunction = sprite.postRenderFunction;
						currentBatcher.blendMode = sprite._blendMode;
						_listSpriteBatchers.push(currentBatcher);
						currentBatcher.textureAtlasID = textureAtlasID;
					}
					(currentBatcher as SpriteBatcher).addChild(sprite);
					
					if (container != null && _hashStaticBatchers[container] == null && staticBatching)
					{
						_hashStaticBatchers[sprite.parent] = currentBatcher;
						_hashStaticBatchersChanged[sprite.parent] = false;
					}
				}
				node = node.nextSibling;
			}
			
		}
		
		public function getScreenshot():BitmapData
		{
			if (_renderEngine == null || !_renderEngine.isReady)
			{
				return null;
			}
			
			renderScene();
			
			return (_renderEngine as MolehillRenderEngine).getScreenshot();
		}
		
		internal function staticContainerChanged(container:Sprite3DContainer):void
		{
			_hashStaticBatchersChanged[container] = true;
		}
		
		private var _hashStaticBatchers:Dictionary;
		private var _hashStaticBatchersChanged:Dictionary;
		private function renderScene():void
		{
			var i:int = 0;
			var spriteBatcher:SpriteBatcher;
			if (_needUpdateBatchers)
			{
				_listSpriteBatchers = new Vector.<IVertexBatcher>();
				
				_hashStaticBatchers = new Dictionary();
				_hashStaticBatchersChanged = new Dictionary();
				
				prepareBatchers(_renderTreeRoot);
			}
			
			for (var field:Object in _hashStaticBatchersChanged)
			{
				var container:Sprite3DContainer = field as Sprite3DContainer;
				if (!_hashStaticBatchersChanged[container])
				{
					continue;
				}
				
				_hashStaticBatchersChanged[container] = false;
				spriteBatcher = _hashStaticBatchers[container] as SpriteBatcher;
				if (spriteBatcher == null)
				{
					continue;
				}
				
				while (spriteBatcher.numSprites > 0)
				{
					spriteBatcher.removeChild(
						spriteBatcher.getLastChild()
					);
				}
				
				for (i = 0; i < container.numChildren; i++)
				{
					var child:Sprite3D = container.getChildAt(i);
					spriteBatcher.addChild(child);
				}
			}
			
			_needUpdateBatchers = false;
			
			//_lastTexture = null;
			
			_renderEngine.clear();
			
			//(_renderEngine as MolehillRenderEngine).renderToMainCamera();
			var tm:TextureManager = TextureManager.getInstance();
			var passedVertices:uint = 0;
			
			var renderEngine:IRenderEngine = Scene3DManager.getInstance().renderEngine;
			
			var left:int = -cameraX;
			var top:int = -cameraY;
			var right:int = left + renderEngine.getViewportWidth();
			var bottom:int = top + renderEngine.getViewportHeight();
			
			for (i = 0; i < _listSpriteBatchers.length; i++)
			{
				var batcher:IVertexBatcher = _listSpriteBatchers[i];
				/*
				if (batcher.preRenderFunction != null)
				{
				batcher.preRenderFunction();
				}
				*/
				var verticesData:ByteArray = batcher.getVerticesData();
				if (batcher.numTriangles == 0)
				{
					continue;
				}
				
				if (tm.getTextureByAtlasID(batcher.textureAtlasID) == null)
				{
					continue;
				}
				
				spriteBatcher = batcher as SpriteBatcher;
				if (spriteBatcher != null &&
					(spriteBatcher.right < left ||
					spriteBatcher.left > right ||
					spriteBatcher.bottom < top ||
					spriteBatcher.top > bottom))
				{
					continue;
				}
				
				_renderEngine.setPreRenderFunction(batcher.preRenderFunction);
				_renderEngine.setPostRenderFunction(batcher.postRenderFunction);
				_renderEngine.bindTexture(batcher.textureAtlasID);
				_renderEngine.setVertexBufferData(verticesData);
				_renderEngine.setIndexBufferData(batcher.getIndicesData(passedVertices));
				_renderEngine.setBlendMode(batcher.blendMode);
				
				passedVertices = _renderEngine.drawTriangles(batcher.numTriangles);
				/*
				if (batcher.postRenderFunction != null)
				{
				batcher.postRenderFunction();
				}
				*/
			}
			
			/*
			(_renderEngine as MolehillRenderEngine).renderToSecondCamera();
			for (i = 0; i < _listSpriteBatchers.length; i++)
			{
			batcher = _listSpriteBatchers[i];
			
			if (batcher is Mesh)
			{
			continue;
			}
			
			if (batcher.preRenderFunction != null)
			{
			batcher.preRenderFunction();
			}
			
			_renderEngine.bindTexture(batcher.textureAtlasID);
			_renderEngine.setVertexBufferData(batcher.getVerticesData());
			_renderEngine.setIndexBufferData(batcher.getIndicesData());
			_renderEngine.drawTriangles(batcher.numTriangles);
			
			if (batcher.postRenderFunction != null)
			{
			batcher.postRenderFunction();
			}
			
			}
			*/
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
						"Render mode: " + (_renderEngine as MolehillRenderEngine).renderMode;
				}
				return;
			}
			
			renderScene();
			
			_renderEngine.present();
			
			renderInfo =
				"Render mode: " + (_renderEngine as MolehillRenderEngine).renderMode +
				"\nDraw calls: " +
				(_renderEngine as MolehillRenderEngine).drawCalls +
				"\nTotal tris: " + (_renderEngine as MolehillRenderEngine).totalTris +
				"\nTexture atlases: " + TextureManager.getInstance().numAtlases +
				"\nRendering to " + _renderEngine.getViewportWidth() + " x " + _renderEngine.getViewportHeight();
		}
	}
}
