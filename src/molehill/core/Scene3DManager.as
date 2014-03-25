package molehill.core
{
	import flash.display.Stage;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DRenderMode;
	import flash.events.Event;
	
	import molehill.core.render.Scene3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.render.shader.Shader3DCache;
	import molehill.core.texture.TextureManager;

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
		public function Scene3DManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use SceneManager::getInstance()");
			}
			
			_hashScenes = new Object();
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
				
				if (_activeScene != null)
				{
					_activeScene.setRenderEngine(_renderer);
				}
				
				_stage.stage3Ds[0].removeEventListener(Event.CONTEXT3D_CREATE, onContext3DReady);
				_stage.stage3Ds[0].addEventListener(Event.CONTEXT3D_CREATE, onContext3DLost);
				
				if (_initCallback != null)
				{
					_initCallback(context);
				}
			}
			
		}
		
		private function onContext3DLost(event:Event):void
		{
			var context:Context3D = _stage.stage3Ds[0].context3D;
			TextureManager.getInstance().setContext(context);
			_renderer.setContext3D(context);
			_renderer.setViewportSize(_stage.stageWidth, _stage.stageHeight);
			
			if (_contextLossCallback != null)
			{
				_contextLossCallback(context);
			}
		}
		
		/**
		 *  Scenes management
		 **/
		private var _hashScenes:Object;
		private var _activeScene:Scene3D;
		public function createEmptyScene(alias:String):void
		{
			var scene:Scene3D = new Scene3D();
			
			if (_hashScenes[alias] != null)
			{
				throw new Error("SceneManager: scene with alias " + alias + " already added. Remove existing scene or use new alias.");
			}
			
			_hashScenes[alias] = scene;
			
			if (_activeScene == null)
			{
				switchScene(alias);
			}
		}
		
		public function addScene(alias:String, scene:Scene3D):void
		{
			if (_hashScenes[alias] != null)
			{
				throw new Error("Scene3DManager: scene with alias " + alias + " already added. Remove existing scene or use new alias.");
			}
			
			_hashScenes[alias] = scene;
			
			if (_activeScene == null)
			{
				switchScene(alias);
			}
		}
		
		public function removeScene(alias:String):void
		{
			if (_hashScenes[alias] === _activeScene)
			{
				throw new Error("Scene3DManager: unable to remove active scene. Switch to another scene first.");
			}
			
			if (_hashScenes[alias] != null)
			{
				delete _hashScenes[alias];
			}
		}
		
		public function get renderEngine():RenderEngine
		{
			return _renderer;
		}
		
		public function getScene(alias:String):Scene3D
		{
			return _hashScenes[alias];
		}
		
		public function switchScene(alias:String):void
		{
			if (_activeScene != null)
			{
				_activeScene.setRenderEngine(null);
			}
			
			_activeScene = _hashScenes[alias];
			_activeScene.setRenderEngine(_renderer);
			_activeSceneAlias = alias;
		}
		
		public function get activeScene():Scene3D
		{
			return _activeScene;
		}
		
		private var _activeSceneAlias:String = "";
		public function get activeSceneAlias():String
		{
			return _activeSceneAlias;
		}
	}
}