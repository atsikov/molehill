package molehill.core.texture
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.EventDispatcher;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import utils.MultipartURLLoader;

	public class TextureManager extends EventDispatcher
	{
		private static var _instance:TextureManager;
		public static function getInstance():TextureManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new TextureManager();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function TextureManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use TextureManager::getInstance()");
			}
			
			reset();
		}
		
		public function get isReady():Boolean
		{
			return _context3D != null && _context3D.driverInfo != "Disposed";
		}
		
		private var _context3D:Context3D;
		public function setContext(value:Context3D):void
		{
			_context3D = value;
			
			_hashTextureTypeByTexture = new Dictionary();
			
			for (var field:Object in _hashTexturesByAtlasBitmap)
			{
				var atlas:TextureAtlasBitmapData = field as TextureAtlasBitmapData;
				var texture:Texture = _context3D.createTexture(atlas.atlasData.width, atlas.atlasData.height, Context3DTextureFormat.BGRA, false);
				texture.uploadFromBitmapData(atlas);
				_hashTexturesByAtlasBitmap[atlas] = texture;
				_hashTexturesByAtlasData[atlas.atlasData] = texture;
				_hashTexturesByAtlasID[atlas.atlasData.atlasID] = texture;
				_hashAtlasDataByAtlasID[atlas.atlasData.atlasID] = atlas.atlasData;
				_hashAtlasIDByTexture[texture] = atlas.atlasData.atlasID;
				_hashTextureTypeByTexture[texture] = false;
				
				for (var textureID:String in atlas.atlasData._hashTextures)
				{
					_hashAtlasDataByTextureID[textureID] = atlas.atlasData;
					_hashAtlasIDByTextureID[textureID] = atlas.atlasData.atlasID;
					_hashTexturesByTextureID[textureID] = texture;
				}
			}
			
			for (field in _hashCompressedTexturesByARFData)
			{
				var arf:ARFTextureData = field as ARFTextureData;
				texture = _context3D.createTexture(arf.width, arf.height, Context3DTextureFormat.BGRA, false);
				texture.uploadCompressedTextureFromByteArray(arf.rawATFData, 0);
				_hashCompressedTexturesByARFData[arf] = texture;
				_hashTexturesByAtlasData[arf.textureAtlasData] = texture;
				_hashTexturesByAtlasID[arf.textureAtlasData.atlasID] = texture;
				_hashAtlasDataByAtlasID[arf.textureAtlasData.atlasID] = arf.textureAtlasData;
				_hashAtlasIDByTexture[texture] = arf.textureAtlasData.atlasID;
				_hashTextureTypeByTexture[texture] = true;
				
				for (textureID in arf.textureAtlasData._hashTextures)
				{
					_hashAtlasDataByTextureID[textureID] = arf.textureAtlasData;
					_hashAtlasIDByTextureID[textureID] = arf.textureAtlasData.atlasID;
					_hashTexturesByTextureID[textureID] = texture;
				}
			}
		}
		
		private var _hashCompressedTexturesByARFData:Dictionary;
		private var _textureWidth:int = 2048;
		private var _textureHeight:int = 2048;
		public function createTextureFromBitmapData(bitmapData:BitmapData, textureID:String, width:int = 0, height:int = 0):Texture
		{
			var atlas:TextureAtlasBitmapData;
			var node:TextureAtlasDataNode;
			for (var field:Object in _hashTexturesByAtlasBitmap)
			{
				atlas = field as TextureAtlasBitmapData;
				if (atlas.atlasData.getTextureData(textureID) != null)
				{
					return _hashTexturesByAtlasBitmap[field] as Texture;
				}
				
				node = (atlas as TextureAtlasBitmapData).insert(bitmapData, textureID);
				if (node != null)
				{
					break;
				}
			}
			
			if (isReady)
			{
				var texture:Texture;
				if (node == null)
				{
					atlas = new TextureAtlasBitmapData(width == 0 ? _textureWidth : width, height == 0 ? _textureHeight : height);
					atlas.insert(bitmapData, textureID);
					texture = _context3D.createTexture(atlas.width, atlas.height, Context3DTextureFormat.BGRA, false);
					_hashTexturesByAtlasBitmap[atlas] = texture;
					_hashTexturesByAtlasData[atlas.atlasData] = texture;
					_hashTexturesByAtlasID[atlas.atlasData.atlasID] = texture;
					_hashAtlasDataByAtlasID[atlas.atlasData.atlasID] = atlas.atlasData;
					_hashAtlasIDByTexture[texture] = atlas.atlasData.atlasID;
					_hashTextureTypeByTexture[texture] = false;
				}
				else
				{
					texture = _hashTexturesByAtlasBitmap[atlas] as Texture;
				}
				
				
				texture.uploadFromBitmapData(atlas as TextureAtlasBitmapData);
			}
			
			if (bitmapData is SpriteSheet)
			{
				atlas.atlasData.getTextureData(textureID).spriteSheetData = (bitmapData as SpriteSheet).spriteSheetData;
			}
			
			_hashAtlasIDByTextureID[textureID] = atlas.atlasData.atlasID;
			_hashTexturesByTextureID[textureID] = texture;
			_hashAtlasDataByTextureID[textureID] = atlas.atlasData;
			
			return texture;
		}
		
		// Objects for hashing by strings
		//    by atlas id
		private var _hashTexturesByAtlasID:Object;
		private var _hashAtlasDataByAtlasID:Object;
		//    by texture id
		private var _hashAtlasDataByTextureID:Object;
		private var _hashAtlasIDByTextureID:Object;
		private var _hashTexturesByTextureID:Object;
		
		// Dictionaries for hashing by objects
		private var _hashTexturesByAtlasBitmap:Dictionary;
		private var _hashAtlasIDByTexture:Dictionary;
		private var _hashTexturesByAtlasData:Dictionary;
		public function createCompressedTextureFromARF(textureData:ARFTextureData):Texture
		{
			/*
			var atlas:TextureAtlasBitmapData;
			var node:TextureAtlasDataNode;
			for (var field:Object in _hashTexturesByAtlas)
			{
				atlas = field as TextureAtlasBitmapData;
				if (atlas.getTextureCoords(textureID) != null)
				{
					return _hashTexturesByAtlas[field] as Texture;
				}
				
				node = (atlas as TextureAtlasBitmapData).insert(bitmapData, textureID);
				if (node != null)
				{
					break;
				}
			}
			*/
			if (_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] != null)
			{
				return _hashTexturesByAtlasID[textureData.textureAtlasData.atlasID];
			}
			
			if (isReady)
			{
				var texture:Texture;
				texture = _context3D.createTexture(textureData.width, textureData.height, Context3DTextureFormat.BGRA, false);
				
				_hashCompressedTexturesByARFData[textureData] = texture;
				/*
				if (node == null)
				{
					atlas = new TextureAtlasBitmapData(width == 0 ? _textureWidth : width, height == 0 ? _textureHeight : height);
					atlas.insert(bitmapData, textureID);
					_hashTexturesByAtlas[atlas] = texture;
				}
				else
				{
					texture = _hashTexturesByAtlas[atlas] as Texture;
				}
				*/
				texture.uploadCompressedTextureFromByteArray(textureData.rawATFData, 0, true);
				_hashTexturesByAtlasData[textureData.textureAtlasData] = texture;
				_hashAtlasDataByAtlasID[textureData.textureAtlasData.atlasID] = textureData.textureAtlasData;
				_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] = texture;
				_hashAtlasIDByTexture[texture] = textureData.textureAtlasData.atlasID;
				
				for (var textureID:String in textureData.textureAtlasData._hashTextures)
				{
					_hashAtlasIDByTextureID[textureID] = textureData.textureAtlasData.atlasID;
					_hashTexturesByTextureID[textureID] = texture;
					_hashAtlasDataByTextureID[textureID] = textureData.textureAtlasData;
				}
				
				_hashTextureTypeByTexture[texture] = true;
			}
			/*
			if (bitmapData is SpriteSheet)
			{
				_hashSpriteSheetDatas[textureID] = (bitmapData as SpriteSheet).spriteSheetData;
			}
			*/
			return texture;
		}
		
		public function getTextureByID(textureID:String):Texture
		{
			return _hashTexturesByTextureID[textureID] as Texture;
		}
		
		private var _hashTextureTypeByTexture:Dictionary;
		public function textureIsCompressed(texture:Texture):Boolean
		{
			return _hashTextureTypeByTexture[texture];
		}
		
		public function getTextureRegion(textureID:String):Rectangle
		{
			var atlasData:TextureAtlasData = _hashAtlasDataByTextureID[textureID];
			if (atlasData == null)
			{
				return null;
			}
			
			return atlasData.getTextureRegion(textureID);
		}
		
		public function getTextureDataByID(textureID:String):TextureData
		{
			var atlasData:TextureAtlasData = _hashAtlasDataByTextureID[textureID];
			if (atlasData == null)
			{
				return null;
			}
			
			return atlasData.getTextureData(textureID);
		}
		
		public function getBitmapRectangleByID(textureID:String):Rectangle
		{
			var atlasData:TextureAtlasData = _hashAtlasDataByTextureID[textureID];
			if (atlasData == null)
			{
				return null;
			}
			
			return atlasData.getTextureBitmapRect(textureID);
		}
		
		public function get numAtlases():uint
		{
			var num:uint = 0;
			for (var atlas:Object in _hashTexturesByAtlasBitmap)
			{
				num++;
			}
			
			return num;
		}
		
		public function getAtlases():Array
		{
			var tmp:Array = new Array();
			for (var atlas:Object in _hashTexturesByAtlasBitmap)
			{
				tmp.push(atlas);
			}
			
			return tmp;
		}
		
		public function hasAtlas(atlasID:String):Boolean
		{
			return _hashAtlasDataByAtlasID[atlasID] != null;
		}
		
		public function getAtlasDataByID(atlasID:String):TextureAtlasData
		{
			return _hashAtlasDataByAtlasID[atlasID];
		}
		
		public function getAtlasDataByTextureID(textureID:String):TextureAtlasData
		{
			return _hashAtlasDataByAtlasID[_hashAtlasIDByTextureID[textureID]];
		}
		
		public function getAtlasBitmapByID(atlasID:String):TextureAtlasBitmapData
		{
			for (var atlas:Object in _hashTexturesByAtlasBitmap)
			{
				if ((atlas as TextureAtlasBitmapData).atlasData.atlasID == atlasID)
				{
					return atlas as TextureAtlasBitmapData;
				}
			}
			
			return null;
		}
		
		public function getTextureByAtlasID(atlasID:String):Texture
		{
			return _hashTexturesByAtlasID[atlasID];
		}
		
		public function getAtlasIDByTexture(value:Texture):String
		{
			return _hashAtlasIDByTexture[value];
		}
		
		public function getSpriteSheetData(textureID:String):SpriteSheetData
		{
			var atlasID:String = _hashAtlasIDByTextureID[textureID];
			var atlasData:TextureAtlasData = _hashAtlasDataByAtlasID[atlasID];
			if (atlasData == null)
			{
				return null;
			}
			
			var textureData:TextureData = atlasData.getTextureData(textureID);
			
			return textureData == null ? null : textureData.spriteSheetData;
		}
		
		public function disposeTexture(texture:Texture):void
		{
			for (var field:Object in _hashTexturesByAtlasBitmap)
			{
				var atlas:TextureAtlasBitmapData = field as TextureAtlasBitmapData;
				if (_hashTexturesByAtlasBitmap[atlas] === texture)
				{
					if (atlas is BitmapData)
					{
						atlas.dispose();
					}
					texture.dispose();
					delete _hashTexturesByAtlasBitmap[atlas];
					return;
				}
			}
		}
		
		public function reset():void
		{
			if (_hashTexturesByAtlasID != null)
			{
				var listAtlases:Array = new Array();
				for (var field:Object in _hashTexturesByAtlasID)
				{
					var atlasID:String = field.toString();
					_hashTexturesByAtlasID[atlasID].dispose();
				}
			}
			
			if (_hashTexturesByAtlasBitmap != null)
			{
				for (field in _hashTexturesByAtlasBitmap)
				{
					(field as TextureAtlasBitmapData).dispose();
				}
			}
			
			_hashAtlasIDByTextureID = new Object();
			_hashTexturesByAtlasID = new Object();
			_hashAtlasDataByAtlasID = new Object();
			_hashTexturesByTextureID = new Object();
			_hashAtlasDataByTextureID = new Object();
			
			_hashAtlasIDByTexture = new Dictionary();
			_hashTexturesByAtlasBitmap = new Dictionary();
			_hashCompressedTexturesByARFData = new Dictionary();
			_hashTexturesByAtlasData = new Dictionary();
			
			_hashTextureTypeByTexture = new Dictionary();
		}
	}
}