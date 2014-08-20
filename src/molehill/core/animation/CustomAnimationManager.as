package molehill.core.animation
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import molehill.core.events.CustomAnimationManagerEvent;
	
	[Event(name="animationsAdded", type="molehill.core.events.CustomAnimationManagerEvent")]
	public class CustomAnimationManager extends EventDispatcher
	{
		private static var _instance:CustomAnimationManager;
		public static function getInstance():CustomAnimationManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new CustomAnimationManager();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		private var _hashAnimations:Object;
		public function CustomAnimationManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use CustomAnimationManager::getInstance()");
			}
			
			_hashAnimations = new Object();
		}
		
		public function getAnimationData(animationName:String):CustomAnimationData
		{
			return _hashAnimations[animationName];
		}
		
		private var _listAnimationNames:Array;
		public function get listAnimationNames():Array
		{
			if (_listAnimationNames == null)
			{
				_listAnimationNames = new Array();
			}
			
			return _listAnimationNames;
		}
		
		private var _listLoadedAnimations:Array;
		public function isAnimationLoaded(url:String):Boolean
		{
			if (_listLoadedAnimations == null)
			{
				return false;
			}
			
			return _listLoadedAnimations.indexOf(url) != -1;
		}
		
		private var _queueLoadingAnimations:Array;
		public function loadAnimations(url:String):void
		{
			if (_queueLoadingAnimations == null)
			{
				_queueLoadingAnimations = new Array();
			}
			
			if (_queueLoadingAnimations.indexOf(url) != -1)
			{
				return;
			}
			
			_queueLoadingAnimations.push(url);
			
			checkLoadingQueue();
		}
		
		private var _isLoading:Boolean = false;
		private function checkLoadingQueue():void
		{
			if (_queueLoadingAnimations.length == 0)
			{
				return;
			}
			
			if (_isLoading)
			{
				return;
			}
			
			_isLoading = true;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE, onAnimationLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onAnimationLoadFailed);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onAnimationLoadFailed);
			loader.load(
				new URLRequest(_queueLoadingAnimations[0])
			);
		}
		
		private function onAnimationLoaded(event:Event):void
		{
			_isLoading = false;
			
			var bytes:ByteArray = (event.target as URLLoader).data;
			bytes.position = 6;
			
			registerAnimations(bytes);
			
			if (_listLoadedAnimations == null)
			{
				_listLoadedAnimations = new Array();
			}
			_listLoadedAnimations.push(
				_queueLoadingAnimations.shift()
			);
				
			dispatchEvent(
				new CustomAnimationManagerEvent(CustomAnimationManagerEvent.ANIMATIONS_ADDED)
			);
			
			checkLoadingQueue();
		}
		
		public function registerAnimations(animationBytes:ByteArray):void
		{
			animationBytes.position = 0;
			var header:String = animationBytes.readUTFBytes(3);
			
			animationBytes.position = header == 'SAP' ? 6 : 0; 
			var listRawAnimations:Array = animationBytes.readObject();
			for (var i:int = 0; i < listRawAnimations.length; i++)
			{
				var animation:CustomAnimationData = CustomAnimationData.fromRawData(listRawAnimations[i]);
				_hashAnimations[animation.animationName] = animation;
				
				if (listAnimationNames.indexOf(animation.animationName) == -1)
				{
					listAnimationNames.push(animation.animationName);
				}
			}
			
			listAnimationNames.sort();
		}
		
		private function onAnimationLoadFailed(event:Event):void
		{
			_isLoading = false;
			_queueLoadingAnimations.shift();
			checkLoadingQueue();
		}
		
		public function addAnimationData(animationData:CustomAnimationData):void
		{
			_hashAnimations[animationData.animationName] = animationData;
			
			if (listAnimationNames.indexOf(animationData.animationName) == -1)
			{
				listAnimationNames.push(animationData.animationName);
			}
			
			listAnimationNames.sort();
			
			dispatchEvent(
				new CustomAnimationManagerEvent(CustomAnimationManagerEvent.ANIMATIONS_ADDED)
			);
		}
	}
}