package molehill.core
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	
	import molehill.core.render.Scene3D;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.render.shader.Shader3DCache;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;

	public class Scene3DManager
	{
		private static var _instance:Scene3DManager;
		public static function getInstance():Scene3DManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new Scene3DManager();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		private static var _renderer:RenderEngine;
		private var _enterFrameListener:Sprite;
		public function Scene3DManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use SceneManager::getInstance()");
			}
			
			_listActiveScenes = new Vector.<Scene3D>();
			
			_enterFrameListener = new Sprite();
			_enterFrameListener.addEventListener(Event.EXIT_FRAME, onRenderEnterFrame);
			
			_listRestoredScenes = new Vector.<Scene3D>();
		}
		
		/**
		 *  Inintialization 
		 **/
		private var _tryForConstrained:Boolean = false;
		private var _stage:Stage;
		private var _initCallback:Function;
		private var _contextLossCallback:Function;
		public function initContext(stage:Stage, initCallback:Function, contextLossCallback:Function, onlyConstrained:Boolean = false, tryForConstrained:Boolean = false):void
		{
			_stage = stage;
			
			_initCallback = initCallback;
			_contextLossCallback = contextLossCallback;
			
			var requestContextMode:String = onlyConstrained ? "baselineConstrained" : "baseline";
			_tryForConstrained = !onlyConstrained && tryForConstrained;
			_stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DReady);
			_stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO, requestContextMode);
		}
		
		private function onContext3DReady(event:Event):void
		{
			var context:Context3D = _stage.stage3Ds[0].context3D;
			if (_tryForConstrained && context.driverInfo.toLocaleLowerCase().indexOf("software") != -1) 
			{
				_tryForConstrained = false;
				_stage.stage3Ds[0].requestContext3D(Context3DRenderMode.AUTO, "baselineConstrained");
			}
			else
			{
				TextureManager.getInstance().setContext(context);
				Shader3DCache.getInstance().init(context);
				_renderer = new RenderEngine(context);
				_renderer.setViewportSize(_stage.stageWidth, _stage.stageHeight);
				_renderer.configureVertexBuffer(
					Sprite3D.VERTICES_OFFSET,
					Sprite3D.COLOR_OFFSET,
					Sprite3D.TEXTURE_OFFSET,
					Sprite3D.NUM_ELEMENTS_PER_VERTEX
				);
				
				for each (var scene:Scene3D in _listActiveScenes)
				{
					scene.setRenderEngine(_renderer);
				}
				
				_stage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, onContext3DReady);
				_stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DLost);
				
				if (_initCallback != null)
				{
					_initCallback(context);
				}
			}
			
		}
		
		private var _listRestoredScenes:Vector.<Scene3D>;
		private function onContext3DLost(event:Event):void
		{
			_listRestoredScenes.splice(0, _listRestoredScenes.length);
			
			var context:Context3D = _stage.stage3Ds[0].context3D;
			TextureManager.getInstance().setContext(context);
			Shader3DCache.getInstance().init(context);
			_renderer.setContext3D(context);
			_renderer.setViewportSize(_stage.stageWidth, _stage.stageHeight);
			
			for each (var scene:Scene3D in _listActiveScenes)
			{
				scene.onContextRestored();
				_listRestoredScenes.push(scene);
			}
			
			if (_contextLossCallback != null)
			{
				_contextLossCallback(context);
			}
		}
		
		public function get renderEngine():RenderEngine
		{
			return _renderer;
		}
		
		/**
		 *  Scenes management
		 **/
		private var _listActiveScenes:Vector.<Scene3D>;
		public function addScene(scene:Scene3D):Scene3D
		{
			if (_listRestoredScenes.indexOf(scene) == -1)
			{
				scene.onContextRestored();
				_listRestoredScenes.push(scene);
			}
			
			_listActiveScenes.push(scene);
			scene.setRenderEngine(_renderer);
			return scene;
		}
		
		public function removeScene(scene:Scene3D):Scene3D
		{
			var index:int = _listActiveScenes.indexOf(scene);
			if (index != -1)
			{
				_listActiveScenes.splice(index, 1);
			}
			scene.setRenderEngine(null);
			return scene;
		}
		
		public function addSceneAt(scene:Scene3D, index:int):Scene3D
		{
			if (_listRestoredScenes.indexOf(scene) == -1)
			{
				scene.onContextRestored();
				_listRestoredScenes.push(scene);
			}
			
			if (index < 0)
			{
				index = 0;
			}
			
			if (index > _listActiveScenes.length)
			{
				index = _listActiveScenes.length;
			}
			scene.setRenderEngine(_renderer);
			_listActiveScenes.splice(index, 0, scene);
			return scene;
		}
		
		public function removeSceneAt(index:int):Scene3D
		{
			if (index < 0 || index > _listActiveScenes.length - 1)
			{
				return null;
			}
			
			var scene:Scene3D = _listActiveScenes[index];
			scene.setRenderEngine(null);
			_listActiveScenes.splice(index, 1);
			return scene;
		}
		
		public function getSceneAt(index:int):Scene3D
		{
			if (index < 0 || index > _listActiveScenes.length - 1)
			{
				return null;
			}
			
			return _listActiveScenes[index];
		}
		
		public function getSceneIndex(scene:Scene3D):int
		{
			return _listActiveScenes.indexOf(scene);
		}
		
		public function get numScenes():uint
		{
			return _listActiveScenes.length;
		}
		
		public function getScreenshot():BitmapData
		{
			if (!_renderer.isReady)
			{
				return null;
			}
			
			_renderer.toBitmapData = true;
			
			var bd:BitmapData = new BitmapData(_renderer.getViewportWidth(), _renderer.getViewportHeight(), true, 0x00000000);
			doRender();
			
			_renderer.copyToBitmapData(bd);
			_renderer.present();
			
			_renderer.toBitmapData = false;
			
			return bd;
		}
		
		/**
		 * Render cycle
		 **/
		private var _renderInfo:Object = new Object();
		public function get renderInfo():Object
		{
			return _renderInfo;
		}
		
		private function onRenderEnterFrame(event:Event):void
		{
			doRender();
		}
		
		private function doRender():void
		{
			if (_renderer == null || !_renderer.isReady)
			{
				return;
			}
			
			_renderer.clear();
			
			for (var i:int = 0; i < _listActiveScenes.length; i++)
			{
				_listActiveScenes[i].renderScene();
			}
			
			_renderer.drawScenes();
			
			if (!_renderer.toBitmapData)
			{
				_renderer.present();
			}
			
			var numBitmapAtlases:int = TextureManager.getInstance().numBitmapAtlases;
			var numCompressedAtlases:int = TextureManager.getInstance().numCompressedAtlases;
			
			_renderInfo.mode = _renderer.renderMode;
			_renderInfo.drawCalls = _renderer.drawCalls;
			_renderInfo.totalTris = _renderer.totalTris;
			_renderInfo.numBitmapAtlases = numBitmapAtlases;
			_renderInfo.numCompressedAtlases = numCompressedAtlases;
		}
	}
}