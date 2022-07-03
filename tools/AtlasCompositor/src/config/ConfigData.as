package config
{
	public class ConfigData
	{
		public static function validate(data:Object):Boolean
		{
			//dump validation
			if (data == null ||	data["label"] == null)
			{
				return false;
			}
			
			return true;
		}
		
		public function ConfigData(data:Object = null, path:String = "")
		{
			_path = path;
			
			if (data == null)
			{
				return;
			}
			
			_label = data["label"] == null ? "New Config" : data["label"];
			_listSourcePath = data["src"] == null ? null : data["src"].split(';');
			_compressAtlas = uint(data["compress"]) == 1;
			_advancedCompression = uint(data["jpeg_compress"]) == 1;
			_includeBinAlpha = uint(data["include_alpha"]) == 1;
			_combineSpriteSheet = uint(data["combine_spritesheet"]) == 1;
			_cropWhitespace = uint(data["crop_whitespace"]) == 1;
			_createHighlights = uint(data["highlights"]) == 1;
			_generateClass = uint(data["generate_class"]) == 1;
			_embedAnimation = uint(data["embed_animation"]) == 1;
			_extrudeEdges = uint(data["extrude_edges"]) == 1;
			_compressionLevel = uint(data["compression_level"]);
			_mipLevels = uint(data["mip_levels"]);
			_textureGap = uint(data["texture_gap"]);
			_updateClassFilePath = data["class_path"] == null ? "" : data["class_path"];
			_updateClassFile = uint(data["update_class"]) == 1;
			_updateClassFilePackage = data["class_package"];
			_updateAtlasFilePath = data["atlas_path"] == null ? "" : data["atlas_path"];
			_updateAtlasFile = uint(data["update_atlas"]) == 1;
			_removeTemp = uint(data["remove_temp"]) == 1;
			_useDXT = uint(data["dxt"]) == 1;
		}
		
		private var _label:String = "";
		
		public function get label():String
		{
			return _label;
		}

		public function set label(value:String):void
		{
			_label = value;
		}
		
		private var _path:String = "";

		public function get path():String
		{
			if (_path == null)
			{
				_path = "";
			}
			return _path;
		}

		public function set path(value:String):void
		{
			_path = value;
		}

		
		private var _listSourcePath:Array;

		public function get listSourcePath():Array
		{
			return _listSourcePath;
		}

		public function set listSourcePath(value:Array):void
		{
			_listSourcePath = value;
		}
		
		private var _compressAtlas:Boolean = true;

		public function get compressAtlas():Boolean
		{
			return _compressAtlas;
		}

		public function set compressAtlas(value:Boolean):void
		{
			_compressAtlas = value;
			_advancedCompression = !value;
		}
		
		private var _useDXT:Boolean = false;
		
		public function get useDXT():Boolean
		{
			return _useDXT;
		}
		
		public function set useDXT(value:Boolean):void
		{
			_useDXT = value;
		}
		
		private var _includeBinAlpha:Boolean = false;

		public function get includeBinAlpha():Boolean
		{
			return _includeBinAlpha;
		}

		public function set includeBinAlpha(value:Boolean):void
		{
			_includeBinAlpha = value;
		}
		
		private var _combineSpriteSheet:Boolean = false;

		public function get combineSpriteSheet():Boolean
		{
			return _combineSpriteSheet;
		}

		public function set combineSpriteSheet(value:Boolean):void
		{
			_combineSpriteSheet = value;
		}
		
		private var _cropWhitespace:Boolean = false;
		public function get cropWhitespace():Boolean
		{ 
			return _cropWhitespace; 
		}
		
		public function set cropWhitespace(value:Boolean):void
		{
			_cropWhitespace = value;
		}
		
		private var _createHighlights:Boolean = false;
		public function get createHighlights():Boolean
		{ 
			return _createHighlights; 
		}
		
		public function set createHighlights(value:Boolean):void
		{
			_createHighlights = value;
		}
		
		private var _generateClass:Boolean = false;
		public function get generateClass():Boolean
		{ 
			return _generateClass; 
		}
		
		public function set generateClass(value:Boolean):void
		{
			_generateClass = value;
		}
		
		private var _updateClassFile:Boolean = false;
		public function get updateClassFileEnabled():Boolean
		{ 
			return _updateClassFile; 
		}
		
		public function set updateClassFileEnabled(value:Boolean):void
		{
			_updateClassFile = value;
		}
		
		private var _updateClassFilePath:String = "";
		public function get updateClassFilePath():String
		{ 
			if (_updateClassFilePath == null)
			{
				_updateClassFilePath = "";
			}
			return _updateClassFilePath; 
		}
		
		public function set updateClassFilePath(value:String):void
		{
			_updateClassFilePath = value;
		}
		
		private var _updateClassFilePackage:String = "";
		public function get updateClassFilePackage():String
		{ 
			if (_updateClassFilePackage == null)
			{
				_updateClassFilePackage = "";
			}
			return _updateClassFilePackage; 
		}
		
		public function set updateClassFilePackage(value:String):void
		{
			_updateClassFilePackage = value;
		}
		
		private var _embedAnimation:Boolean = false;
		public function get embedAnimation():Boolean
		{ 
			return _embedAnimation; 
		}
		
		public function set embedAnimation(value:Boolean):void
		{
			_embedAnimation = value;
		}
		
		private var _extrudeEdges:Boolean = false;
		public function get extrudeEdges():Boolean
		{ 
			return _extrudeEdges; 
		}
		
		public function set extrudeEdges(value:Boolean):void
		{
			_extrudeEdges = value;
		}
		
		private var _compressionLevel:uint = 30;
		public function get compressionLevel():uint
		{ 
			return _compressionLevel; 
		}
		
		public function set compressionLevel(value:uint):void
		{
			_compressionLevel = value;
		}
		
		private var _mipLevels:uint = 0;
		public function get mipLevels():uint
		{ 
			return _mipLevels; 
		}
		
		public function set mipLevels(value:uint):void
		{
			_mipLevels = value;
		}
		
		private var _textureGap:uint = 1;
		public function get textureGap():uint
		{ 
			return _textureGap; 
		}
		
		public function set textureGap(value:uint):void
		{
			_textureGap = value;
		}
		
		private var _updateAtlasFile:Boolean = false;
		public function get updateAtlasFileEnabled():Boolean
		{ 
			return _updateAtlasFile; 
		}
		
		public function set updateAtlasFileEnabled(value:Boolean):void
		{
			_updateAtlasFile = value;
		}
		
		private var _updateAtlasFilePath:String = "";
		public function get updateAtlasFilePath():String
		{ 
			if (_updateAtlasFilePath == null)
			{
				_updateAtlasFilePath = "";
			}
			return _updateAtlasFilePath; 
		}
		
		public function set updateAtlasFilePath(value:String):void
		{
			_updateAtlasFilePath = value;
		}
		
		private var _removeTemp:Boolean = false;
		public function get removeTemp():Boolean
		{ 
			return _removeTemp; 
		}
		
		public function set removeTemp(value:Boolean):void
		{
			_removeTemp = value;
		}
		
		private var _advancedCompression:Boolean = false;
		public function get advancedCompression():Boolean
		{
			return _advancedCompression;
		}

		public function set advancedCompression(value:Boolean):void
		{
			_advancedCompression = value;
			_compressAtlas = !value;
		}
		
		
		private var _useFolderName:Boolean = true;
		public function get useFolderName():Boolean
		{
			return _useFolderName;
		}
		
		public function set useFolderName(value:Boolean):void
		{
			_useFolderName = value;
		}

		
		//
		
		public function get dataObject():Object
		{
			var data:Object = new Object();
			
			data["label"] = _label;
			data["src"] = _listSourcePath.join(';');
			
			data["compress"] = _compressAtlas ? 1 : 0;
			data["jpeg_compress"] = _advancedCompression ? 1 : 0;
			data["include_alpha"] = _includeBinAlpha ? 1 : 0;
			data["combine_spritesheet"] = _combineSpriteSheet ? 1 : 0;
			data["crop_whitespace"] = _cropWhitespace ? 1 : 0;
			data["highlights"] = _createHighlights ? 1 : 0;
			data["generate_class"] = _generateClass ? 1 : 0;
			data["embed_animation"] = _embedAnimation ? 1 : 0;
			data["extrude_edges"] = _extrudeEdges ? 1 : 0;
			
			data["dxt"] = _useDXT ? 1 : 0;
			data["compression_level"] = _compressionLevel;
			data["mip_levels"] = _mipLevels;
			data["texture_gap"] = _textureGap;
			data["class_path"] = _updateClassFilePath;
			data["class_package"] = _updateClassFilePackage;
			
			data["update_class"] = _updateClassFile ? 1 : 0;
			
			data["atlas_path"] = _updateAtlasFilePath;
			
			data["update_atlas"] = _updateAtlasFile ? 1 : 0;
			data["remove_temp"] = _removeTemp ? 1 : 0;
			
			return data;
		}
	}
}