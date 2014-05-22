package molehill.core.texture
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTextureFormat;
	import flash.display3D.textures.Texture;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	import flash.utils.Timer;
	
	import molehill.core.errors.TextureManagerError;

	public class TextureManager extends EventDispatcher
	{
		public static function createTexture(textureData:*, ... params):Texture
		{
			var tm:TextureManager = getInstance();
			var texture:Texture;
			if (textureData is ARFTextureData)
			{
				texture = tm.createCompressedTextureFromARF(textureData);
			}
			else if (textureData is BRFTextureData)
			{
				texture = tm.createTextureFromBRF(textureData);
			}
			else if (textureData is FontBRFTextureData)
			{
				texture = tm.createFontTextureFromBitmapData(textureData);
			}
			else if (textureData is BitmapData || textureData is Bitmap)
			{
				var bitmapData:BitmapData = textureData is Bitmap ? (textureData as Bitmap).bitmapData : textureData;
				
				if (params[1] == null)
				{
					texture = tm.createTextureFromBitmapData(bitmapData, params[0]);
				}
				else if (params[2] == null)
				{
					texture = tm.createTextureFromBitmapData(bitmapData, params[0], params[1]);
				}
				else
				{
					texture = tm.createTextureFromBitmapData(bitmapData, params[0], params[1], params[2]);
				}
			}
			else if (textureData == null)
			{
				throw new TextureManagerError("TextureManager::createTexture(): Parameter textureData cannot be null!")
			}
			else
			{
				throw new TextureManagerError("TextureManager::createTexture(): Unknown texture format!")
			}
			
			return texture;
		}
		
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
		private var _gcTimer:Timer;
		public function TextureManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use TextureManager::getInstance()");
			}
			
			reset();
			
			_gcTimer = new Timer(5000);
			_gcTimer.addEventListener(TimerEvent.TIMER, onGCTimer);
			_gcTimer.start();
		}
		
		private function onGCTimer(event:Event):void
		{
			for (var field:Object in _notUsedTextures)
			{
				var texture:Texture = field as Texture;
				texture.dispose();
				var atlasID:String = _hashAtlasIDByTexture[texture];
				
				var atlasData:TextureAtlasData = _hashAtlasDataByAtlasID[atlasID];
				
				delete _hashTexturesByAtlasData[atlasData];
				delete _hashTexturesByAtlasID[atlasID];
				
				_hashAtlasIDByTexture[texture] = null;
				
				for (var textureId:String in atlasData._hashTextures)
				{
					delete _hashTexturesByTextureID[textureId];
				}
				
				if (_hashARFDataByTextureID[textureId] != null)
				{
					delete _hashCompressedTexturesByARFData[_hashARFDataByTextureID[textureId]];
				}
				else
				{
					delete _hashTexturesByTextureID[_hashAtlasBitmapByTextureID[textureId]];
				}
				
				delete _hashTextureTypeByTexture[texture];
			}
			
			_notUsedTextures = new Dictionary();
			for each (texture in _hashTexturesByAtlasID)
			{
				_notUsedTextures[texture] = true;
			}
		}
		
		public function get isReady():Boolean
		{
			return _context3D != null && _context3D.driverInfo != "Disposed";
		}
		
		private var _context3D:Context3D;
		public function setContext(value:Context3D):void
		{
			_context3D = value;
			for each (var texture:Texture in _hashTexturesByAtlasID)
			{
				texture.dispose();
				var atlasID:String = _hashAtlasIDByTexture[texture];
				
				var atlasData:TextureAtlasData = _hashAtlasDataByAtlasID[atlasID];
				
				delete _hashTexturesByAtlasData[atlasData];
				delete _hashTexturesByAtlasID[atlasID];
				
				_hashAtlasIDByTexture[texture] = null;
				
				for (var textureId:String in atlasData._hashTextures)
				{
					delete _hashTexturesByTextureID[textureId];
				}
				
				if (_hashARFDataByTextureID[textureId] != null)
				{
					delete _hashCompressedTexturesByARFData[_hashARFDataByTextureID[textureId]];
				}
				else
				{
					delete _hashTexturesByTextureID[_hashAtlasBitmapByTextureID[textureId]];
				}
				
				delete _hashTextureTypeByTexture[texture];
			}
			
			_notUsedTextures = new Dictionary();
			
			/*
			_hashTextureTypeByTexture = new Dictionary();
			
			for (var field:Object in _hashTexturesByAtlasBitmap)
			{
				var atlas:TextureAtlasBitmapData = field as TextureAtlasBitmapData;
				var streamingLevel:int = 0;
				if (atlas is FontBRFTextureData)
				{
					Math.min(
						MathUtils.log2(atlas.width),
						MathUtils.log2(atlas.height),
						7
					);
				}
				var texture:Texture = _context3D.createTexture(atlas.textureAtlasData.width, atlas.textureAtlasData.height, Context3DTextureFormat.BGRA, false, streamingLevel);
				texture.uploadFromBitmapData(atlas);
				
				if (atlas is FontBRFTextureData)
				{
					var mipWidth:int = atlas.width / 2;
					var mipHeight:int = atlas.height / 2;
					
					var scaleTransform:Matrix = new Matrix();
					scaleTransform.scale(0.5, 0.5);
					
					var mipLevel:int = 1;
					var mipImage:BitmapData = new BitmapData(mipWidth, mipHeight, true, 0x00000000);
					
					while (mipWidth > 0 && mipHeight > 0)
					{
						mipImage.draw(atlas, scaleTransform, null, null, null, true);
						texture.uploadFromBitmapData(mipImage, mipLevel);
						scaleTransform.scale(0.5, 0.5);
						mipLevel++;
						mipWidth >>= 1;
						mipHeight >>= 1;
					}
					
					mipImage.dispose();
				}
				
				_hashTexturesByAtlasBitmap[atlas] = texture;
				_hashTexturesByAtlasData[atlas.textureAtlasData] = texture;
				_hashTexturesByAtlasID[atlas.textureAtlasData.atlasID] = texture;
				_hashAtlasDataByAtlasID[atlas.textureAtlasData.atlasID] = atlas.textureAtlasData;
				_hashAtlasIDByTexture[texture] = atlas.textureAtlasData.atlasID;
				_hashTextureTypeByTexture[texture] = false;
				
				for (var textureID:String in atlas.textureAtlasData._hashTextures)
				{
					_hashAtlasDataByTextureID[textureID] = atlas.textureAtlasData;
					_hashAtlasIDByTextureID[textureID] = atlas.textureAtlasData.atlasID;
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
			*/
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
				if (atlas.textureAtlasData.getTextureData(textureID) != null)
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
				if (node == null)
				{
					atlas = new TextureAtlasBitmapData(width == 0 ? _textureWidth : width, height == 0 ? _textureHeight : height);
					atlas.textureAtlasData.atlasID = "atlas" + uint(Math.random() * uint.MAX_VALUE).toString();
					atlas.insert(bitmapData, textureID);
					
					//texture = _context3D.createTexture(atlas.width, atlas.height, Context3DTextureFormat.BGRA, false);
					
					//_hashTexturesByAtlasBitmap[atlas] = texture;
					//_hashTexturesByAtlasData[atlas.textureAtlasData] = texture;
					//_hashTexturesByAtlasID[atlas.textureAtlasData.atlasID] = texture;
					_hashAtlasDataByAtlasID[atlas.textureAtlasData.atlasID] = atlas.textureAtlasData;
					//_hashAtlasIDByTexture[texture] = atlas.textureAtlasData.atlasID;
					
					//_hashTextureTypeByTexture[texture] = false;
				}
				else
				{
					//texture = _hashTexturesByAtlasBitmap[atlas] as Texture;
				}
				
				if (_hashTexturesByAtlasBitmap[atlas] != null)
				{
					var texture:Texture = _hashTexturesByAtlasBitmap[atlas];
					texture.uploadFromBitmapData(atlas as TextureAtlasBitmapData);
				}
				//texture.uploadFromBitmapData(atlas as TextureAtlasBitmapData);
			}
			
			if (bitmapData is SpriteSheet)
			{
				atlas.textureAtlasData.getTextureData(textureID).spriteSheetData = (bitmapData as SpriteSheet).spriteSheetData;
			}
			
			_hashAtlasIDByTextureID[textureID] = atlas.textureAtlasData.atlasID;
			//_hashTexturesByTextureID[textureID] = texture;
			_hashAtlasDataByTextureID[textureID] = atlas.textureAtlasData;
			_hashAtlasBitmapByTextureID[textureID] = atlas;
			
			return null;//texture;
		}
		
		public function createCompressedTextureFromARF(textureData:ARFTextureData):Texture
		{
			if (textureData.textureAtlasData.atlasID == null)
			{
				textureData.textureAtlasData.atlasID = "atlas" + uint(Math.random() * uint.MAX_VALUE).toString();
			}
			
			if (_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] != null)
			{
				return _hashTexturesByAtlasID[textureData.textureAtlasData.atlasID];
			}
			
			if (isReady)
			{
				//var texture:Texture;
				//texture = _context3D.createTexture(textureData.width, textureData.height, Context3DTextureFormat.BGRA, false, Math.min(textureData.numTextures, 7));
				
				//_hashCompressedTexturesByARFData[textureData] = texture;
				//texture.uploadCompressedTextureFromByteArray(textureData.rawATFData, 0, true);
				//_hashTexturesByAtlasData[textureData.textureAtlasData] = texture;
				_hashAtlasDataByAtlasID[textureData.textureAtlasData.atlasID] = textureData.textureAtlasData;
				//_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] = texture;
				//_hashAtlasIDByTexture[texture] = textureData.textureAtlasData.atlasID;
				
				for (var textureID:String in textureData.textureAtlasData._hashTextures)
				{
					if (_hashAtlasIDByTextureID[textureID] != null)
					{
						throw new TextureManagerError("Atlas with the same texture ID already created!");
					}
					
					_hashAtlasIDByTextureID[textureID] = textureData.textureAtlasData.atlasID;
					//_hashTexturesByTextureID[textureID] = texture;
					_hashAtlasDataByTextureID[textureID] = textureData.textureAtlasData;
					_hashARFDataByTextureID[textureID] = textureData;
				}
				
				//_hashTextureTypeByTexture[texture] = true;
			}
			return null; //texture;
		}
		
		public function createTextureFromBRF(textureData:BRFTextureData):Texture
		{
			if (textureData.textureAtlasData.atlasID == null)
			{
				textureData.textureAtlasData.atlasID = "atlas" + uint(Math.random() * uint.MAX_VALUE).toString();
			}
			
			if (_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] != null)
			{
				return _hashTexturesByAtlasID[textureData.textureAtlasData.atlasID];
			}
			
			if (isReady)
			{
				//var texture:Texture;
				//texture = _context3D.createTexture(textureData.width, textureData.height, Context3DTextureFormat.BGRA, false);
				
				//_hashTexturesByAtlasBitmap[textureData] = texture;
				//texture.uploadFromBitmapData(textureData, 0);
				//_hashTexturesByAtlasData[textureData.textureAtlasData] = texture;
				_hashAtlasDataByAtlasID[textureData.textureAtlasData.atlasID] = textureData.textureAtlasData;
				//_hashTexturesByAtlasID[textureData.textureAtlasData.atlasID] = texture;
				//_hashAtlasIDByTexture[texture] = textureData.textureAtlasData.atlasID;
				
				for (var textureID:String in textureData.textureAtlasData._hashTextures)
				{
					_hashAtlasIDByTextureID[textureID] = textureData.textureAtlasData.atlasID;
					//_hashTexturesByTextureID[textureID] = texture;
					_hashAtlasDataByTextureID[textureID] = textureData.textureAtlasData;
					_hashAtlasBitmapByTextureID[textureID] = textureData;
				}
				
				//_hashTextureTypeByTexture[texture] = false;
			}
			return null; //texture;
		}
		
		public function createFontTextureFromBitmapData(fontBitmap:FontBRFTextureData):Texture
		{
			if (fontBitmap.textureAtlasData.atlasID == null)
			{
				fontBitmap.textureAtlasData.atlasID = "atlas" + uint(Math.random() * uint.MAX_VALUE).toString();
			}
			
			if (_hashTexturesByAtlasID[fontBitmap.textureAtlasData.atlasID] != null)
			{
				return _hashTexturesByAtlasID[fontBitmap.textureAtlasData.atlasID];
			}
			
			if (isReady)
			{
				//var texture:Texture;
				//texture = _context3D.createTexture(
				//	fontBitmap.width,
				//	fontBitmap.height,
				//	Context3DTextureFormat.BGRA,
				//	false,
				//	Math.min(
				//		MathUtils.log2(fontBitmap.width),
				//		MathUtils.log2(fontBitmap.height),
				//		7
				//	)
				//);
				
				//_hashTexturesByAtlasBitmap[fontBitmap] = texture;
				//texture.uploadFromBitmapData(fontBitmap);
				//_hashTexturesByAtlasData[fontBitmap.textureAtlasData] = texture;
				_hashAtlasDataByAtlasID[fontBitmap.textureAtlasData.atlasID] = fontBitmap.textureAtlasData;
				//_hashTexturesByAtlasID[fontBitmap.textureAtlasData.atlasID] = texture;
				//_hashAtlasIDByTexture[texture] = fontBitmap.textureAtlasData.atlasID;
				
				for (var textureID:String in fontBitmap.textureAtlasData._hashTextures)
				{
					_hashAtlasIDByTextureID[textureID] = fontBitmap.textureAtlasData.atlasID;
					//_hashTexturesByTextureID[textureID] = texture;
					_hashAtlasDataByTextureID[textureID] = fontBitmap.textureAtlasData;
					_hashAtlasBitmapByTextureID[textureID] = fontBitmap;
				}
				
				//_hashTextureTypeByTexture[texture] = false;
			}
			
			var mipWidth:int = fontBitmap.width / 2;
			var mipHeight:int = fontBitmap.height / 2;
			
			var scaleTransform:Matrix = new Matrix();
			scaleTransform.scale(0.5, 0.5);
			
			var mipLevel:int = 1;
			var mipImage:BitmapData = new BitmapData(mipWidth, mipHeight, true, 0x00000000);
			
			while (mipWidth > 0 && mipHeight > 0)
			{
				mipImage.draw(fontBitmap, scaleTransform, null, null, null, true);
				//texture.uploadFromBitmapData(mipImage, mipLevel);
				scaleTransform.scale(0.5, 0.5);
				mipLevel++;
				mipWidth >>= 1;
				mipHeight >>= 1;
			}
			
			mipImage.dispose();
			
			return null; //texture;
		}
		
		public function reuploadTexture(bitmapData:BitmapData):void
		{
			var texture:Texture = _hashTexturesByAtlasBitmap[bitmapData];
			if (texture != null)
			{
				texture.uploadFromBitmapData(bitmapData);
			}
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
		
		// Dictionaries for restoring GCed textures
		private var _hashAtlasBitmapByTextureID:Object;
		private var _hashARFDataByTextureID:Object;
		
		private var _notUsedTextures:Dictionary;
		private function tryRestoreTexture(textureId:String):Boolean
		{
			if (_hashAtlasDataByTextureID[textureId] == null)
			{
				return false;
			}
			
			var texture:Texture;
			var id:String;
			if (_hashARFDataByTextureID[textureId] != null)
			{
				var arfData:ARFTextureData = _hashARFDataByTextureID[textureId];
				texture = _context3D.createTexture(arfData.width, arfData.height, Context3DTextureFormat.BGRA, false, Math.min(arfData.numTextures, 7));
				texture.uploadCompressedTextureFromByteArray(arfData.rawATFData, 0, true);
				
				_hashCompressedTexturesByARFData[arfData] = texture;
				_hashTexturesByAtlasData[arfData.textureAtlasData] = texture;
				_hashTexturesByAtlasID[arfData.textureAtlasData.atlasID] = texture;
				_hashAtlasIDByTexture[texture] = arfData.textureAtlasData.atlasID;
				
				for (id in arfData.textureAtlasData._hashTextures)
				{
					_hashTexturesByTextureID[id] = texture;
				}
				
				_hashTextureTypeByTexture[texture] = true;
				
				return true;
			}
			else if (_hashAtlasBitmapByTextureID[textureId] != null)
			{
				var atlas:TextureAtlasBitmapData = _hashAtlasBitmapByTextureID[textureId];
				var needMipmaps:Boolean = atlas is FontBRFTextureData;
				texture = _context3D.createTexture(atlas.width, atlas.height, Context3DTextureFormat.BGRA, false, needMipmaps ? 7 : 0);
				texture.uploadFromBitmapData(atlas, 0);
				
				_hashTexturesByAtlasBitmap[atlas] = texture;
				_hashTexturesByAtlasData[atlas.textureAtlasData] = texture;
				_hashTexturesByAtlasID[atlas.textureAtlasData.atlasID] = texture;
				_hashAtlasIDByTexture[texture] = atlas.textureAtlasData.atlasID;
				
				for (id in atlas.textureAtlasData._hashTextures)
				{
					_hashTexturesByTextureID[id] = texture;
				}
				
				_hashTextureTypeByTexture[texture] = false;
				
				if (needMipmaps)
				{
					var mipWidth:int = atlas.width / 2;
					var mipHeight:int = atlas.height / 2;
					
					var scaleTransform:Matrix = new Matrix();
					scaleTransform.scale(0.5, 0.5);
					
					var mipLevel:int = 1;
					var mipImage:BitmapData = new BitmapData(mipWidth, mipHeight, true, 0x00000000);
					
					while (mipWidth > 0 && mipHeight > 0)
					{
						mipImage.draw(atlas, scaleTransform, null, null, null, true);
						texture.uploadFromBitmapData(mipImage, mipLevel);
						scaleTransform.scale(0.5, 0.5);
						mipLevel++;
						mipWidth >>= 1;
						mipHeight >>= 1;
					}
					
					mipImage.dispose();
				}
				
				return true;
			}
			
			return false;
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
		
		public function isTextureCreated(textureID:String):Boolean
		{
			return _hashAtlasBitmapByTextureID[textureID] != null || _hashARFDataByTextureID[textureID] != null;
		}
		
		public function isAtlasCreated(atlasID:String):Boolean
		{
			return _hashAtlasDataByAtlasID[atlasID] != null;
		}
		
		public function isARFUploaded(arf:ARFTextureData):Boolean
		{
			var listTextures:Array = arf.textureAtlasData.listTexturesNames;
			return isTextureCreated(listTextures[0]);
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
		
		public function get numBitmapAtlases():uint
		{
			var num:uint = 0;
			for (var atlas:Object in _hashTexturesByAtlasBitmap)
			{
				num++;
			}
			
			return num;
		}
		
		public function get numCompressedAtlases():uint
		{
			var num:uint = 0;
			for (var atlas:Object in _hashCompressedTexturesByARFData)
			{
				num++;
			}
			
			return num;
		}
		
		public function getAtlases():Array
		{
			var tmp:Array = new Array();
			for each (var atlas:Object in _hashAtlasDataByAtlasID)
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
			var atlasID:String = _hashAtlasIDByTextureID[textureID];
			return _hashAtlasDataByAtlasID[atlasID];
		}
		
		public function getAtlasBitmapByID(atlasID:String):TextureAtlasBitmapData
		{
			for (var atlas:Object in _hashTexturesByAtlasBitmap)
			{
				if ((atlas as TextureAtlasBitmapData).textureAtlasData.atlasID == atlasID)
				{
					return atlas as TextureAtlasBitmapData;
				}
			}
			
			return null;
		}
		
		public function getTextureByAtlasID(atlasID:String):Texture
		{
			if (_hashTexturesByAtlasID[atlasID] == null)
			{
				var atlasData:TextureAtlasData = getAtlasDataByID(atlasID);
				for (var textureId:String in atlasData._hashTextures)
				{
					break;
				}
				tryRestoreTexture(textureId);
			}
			
			var texture:Texture = _hashTexturesByAtlasID[atlasID] as Texture;
			delete _notUsedTextures[texture]
			return texture;
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
			
			_notUsedTextures = new Dictionary();
			
			_hashAtlasBitmapByTextureID = new Object();
			_hashARFDataByTextureID = new Object();
		}
	}
}