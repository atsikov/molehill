package atlas_compositor.config
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	
	import mx.collections.ArrayCollection;
	import mx.controls.Alert;

	public class ConfigListDataProvider extends EventDispatcher
	{
		private var _sourceArray:Array;
		private var _sourceCollection:ArrayCollection;
		
		private static var _instance:ConfigListDataProvider
		public static function getInstance():ConfigListDataProvider
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new ConfigListDataProvider();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		
		private var _lastPath:String;

		public function get lastPath():String
		{
			return _lastPath;
		}
		
		private var _changed:Boolean = false;
		
		private var _configListFile:File;
		public function get configListFile():File
		{
			return _configListFile;
		}

		public function ConfigListDataProvider()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use ConfigListDataProvider::getInstance()");
			}
			
			_configListFile = File.applicationStorageDirectory.resolvePath("config_list.dat");
			_sourceArray = new Array();
			_lastPath = File.desktopDirectory.nativePath;
			_sourceCollection = new ArrayCollection();
		}
		
		public function init():void
		{
			if (!_configListFile.exists)
			{
				saveConfigList(true);
			}
			
			var fsIn:FileStream = new FileStream();
			fsIn.open(_configListFile, FileMode.READ);
			var source:String = fsIn.readUTFBytes(fsIn.bytesAvailable);
			fsIn.close();
			
			var rawData:Array;
			try
			{
				rawData = JSON.parse(source) as Array;
			} 
			catch(error:Error) 
			{
				
			}
			if (rawData == null)
			{
				rawData = new Array();
			}
			
			parseSource(rawData);
		}
		
		public function saveConfigList(create:Boolean = false):void
		{
			if (!_changed && !create)
			{
				return;
			}
			
			var fsOut:FileStream = new FileStream();
			fsOut.open(_configListFile, FileMode.WRITE);
			fsOut.writeUTFBytes(JSON.stringify(source));
			fsOut.close();
		}
		
		private var _queue:Array;
		public function parseSource(source:Array):void
		{
			_sourceArray = source;
			
			if (_sourceArray == null)
			{
				_sourceArray = new Array();
				return;
			}
			
			_queue = _sourceArray.concat();
			
			processQueue();
		}
		
		private function processQueue():void
		{
			if (_queue.length == 0)
			{
				dispatchEvent(new Event(Event.COMPLETE));
				return;
			}
			
			var configPath:String = _queue.shift();
			var configFile:File = new File(configPath);
			
			if (configFile.exists)
			{
				loadConfig(configPath, true);
			}
			
			processQueue();
		}
		
		public function loadConfig(configPath:String, silent:Boolean = false):void
		{
			var configFile:File = new File(configPath);
			var fsIn:FileStream = new FileStream();
			fsIn.open(configFile, FileMode.READ);
			var source:String = fsIn.readUTFBytes(fsIn.bytesAvailable);
			fsIn.close();
			var data:Object;
			try
			{
				data = JSON.parse(source);
			}
			catch (e:Error)
			{
				if (!silent)
				{
					Alert.show("Error parsing file", "Error");
				}
				trace(e.message);
				data = null;
			}
			
			if (!ConfigData.validate(data) && !silent)
			{
				Alert.show("Not config file", "Error");
				return;
			}
			
			_lastPath = configFile.parent.nativePath;
			_sourceCollection.addItem(new ConfigData(data, configPath));
			
			if (_sourceArray.indexOf(configPath) == -1)
			{
				_sourceArray.push(configPath);
				_changed = true;
			}
		}
		
		public function get source():Array
		{
			return _sourceArray != null ? _sourceArray : null;
		}
		
		public function get sourceCollection():ArrayCollection
		{
			return _sourceCollection;
		}
		
		private var _savingConfigData:ConfigData;
		public function saveConfigData(configData:ConfigData):Boolean
		{
			if (configData == null || configData.path == "")
			{
				return false;
			}
			
			var configFile:File = new File(configData.path);
			var fsOut:FileStream = new FileStream();
			fsOut.open(configFile, FileMode.WRITE);
			fsOut.writeUTFBytes(JSON.stringify(configData.dataObject));
			fsOut.close();
			
			_savingConfigData = null;
			
			if (!_sourceCollection.contains(configData))
			{
				addConfig(configData);
			}
			
			return true;
		}
		
		private function addConfig(configData:ConfigData):void
		{
			if (_sourceArray.indexOf(configData.path) != -1)
			{
				return;
			}
			
			_sourceArray.push(configData.path);
			_sourceCollection.addItem(configData);
			_changed = true;
		}
		
		public function removeConfig(configData:ConfigData):void
		{
			_sourceArray.splice(_sourceArray.indexOf(configData.path), 1);
			_sourceCollection.removeItemAt(_sourceCollection.getItemIndex(configData));
			_changed = true;
		}
	}
}