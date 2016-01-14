package molehill.core.text
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	
	import molehill.core.events.Font3DManagerEvent;
	import molehill.core.texture.FontARFTextureData;
	import molehill.core.texture.FontBRFTextureData;
	import molehill.core.texture.FontTextureData;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	[Event(name="fontReady", type="molehill.core.events.Font3DManagerEvent")]
	[Event(name="fontLoadError", type="molehill.core.events.Font3DManagerEvent")]
	public class Font3DManager extends EventDispatcher
	{
		private static var _instance:Font3DManager;
		public static function getInstance():Font3DManager
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new Font3DManager();
				_allowInstantion = false;
			}
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function Font3DManager()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use Font3DManager::getInstance()");
			}
			
			_hashFontBitmaps = new Object();
			_hashFontAtlasDatas = new Object();
		}
		
		private var _defaultSystemFont:String = "Arial";
		public function get defaultSystemFont():String
		{
			return _defaultSystemFont;
		}
		
		public function set defaultSystemFont(value:String):void
		{
			_defaultSystemFont = value;
		}
		
		public function loadARFFont(url:String):void
		{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onFontLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onFontLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFontLoadError);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(new URLRequest(url));
		}
		
		private function onFontLoaded(event:Event):void
		{
			var bytes:ByteArray = (event.currentTarget as URLLoader).data;
			var fontTexture:FontARFTextureData = new FontARFTextureData(bytes);
			
			var fontName:String = (fontTexture.textureAtlasData as FontTextureData).fontName;
			TextureManager.getInstance().createCompressedTextureFromARF(fontTexture);
			_hashFontAtlasDatas[fontName] = fontTexture.textureAtlasData;
			
			dispatchEvent(
				new Font3DManagerEvent(Font3DManagerEvent.FONT_READY, (fontTexture.textureAtlasData as FontTextureData).fontName)
			);
		}
		
		private function onFontLoadError(event:Event):void
		{
			trace("Error loading font!");
			dispatchEvent(
				new Font3DManagerEvent(Font3DManagerEvent.FONT_LOAD_ERROR)
			);
		}
		
		public function loadBitmapFont(url:String):void
		{
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onBitmapFontLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onFontLoadError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onFontLoadError);
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.load(new URLRequest(url));
		}
		
		public function loadBitmapFontFromByteArray(bytes:ByteArray):void
		{
			parseFontBytes(bytes);
		}
		
		private function onBitmapFontLoaded(event:Event):void
		{
			var bytes:ByteArray = (event.currentTarget as URLLoader).data;
			parseFontBytes(bytes)
		}
		
		private function parseFontBytes(bytes:ByteArray):void
		{
			bytes.position = 0;
			
			var imageBytes:ByteArray;
			var fontTextureData:FontTextureData;
			
			while (bytes.bytesAvailable)
			{
				var header:String = bytes.readUTFBytes(3);
				var chunkSize:int = 0x10000 * bytes.readUnsignedByte() + 0x100 * bytes.readUnsignedByte() + bytes.readUnsignedByte();
				var chunkData:ByteArray = new ByteArray();
				
				switch (header)
				{
					case 'IMG': // Bitmap
						chunkData.writeBytes(bytes, bytes.position, chunkSize);
						imageBytes = chunkData;
						break;
					
					case 'TAD': // Texture Atlas Data
						chunkData.writeBytes(bytes, bytes.position, chunkSize);
						chunkData.position = 0;
						fontTextureData = FontTextureData.fromRawData(chunkData.readObject());
						break;
				}
				bytes.position += chunkSize;
			}
			
			new FontImageLoader(imageBytes, fontTextureData, onBitmapFontImageLoaded);
		}
		
		private var _hashFontBitmaps:Object;
		private function onBitmapFontImageLoaded(loader:FontImageLoader):void
		{
			var tm:TextureManager = TextureManager.getInstance();
			
			var fontBitmap:FontBRFTextureData = new FontBRFTextureData(loader.fontBitmapData, loader.fontTextureData);
			fontBitmap.textureAtlasData.atlasID = '__font__' + loader.fontTextureData.fontName;
			TextureManager.getInstance().createFontTextureFromBitmapData(fontBitmap);
			
			_hashFontAtlasDatas[loader.fontTextureData.fontName] = loader.fontTextureData;
			_hashFontBitmaps[loader.fontTextureData.fontName] = fontBitmap;
			
			dispatchEvent(
				new Font3DManagerEvent(Font3DManagerEvent.FONT_READY, loader.fontTextureData.fontName)
			);
		}
		
		private function onBitmapFontLoadError(event:Event):void
		{
			dispatchEvent(
				new Font3DManagerEvent(Font3DManagerEvent.FONT_LOAD_ERROR)
			);
		}
		
		private var _hashFontAtlasDatas:Object;
		public function isFontLoaded(fontName:String):Boolean
		{
			return _hashFontAtlasDatas[fontName] != null;
		}
		
		public function getFontTextureAtlasData(fontName:String):FontTextureData
		{
			return _hashFontAtlasDatas[fontName];
		}
		
		public function getSuitableFontSize(fontName:String, size:int):int
		{
			if (!isFontLoaded(fontName))
			{
				return size;
			}
			
			var fontTextureData:FontTextureData = _hashFontAtlasDatas[fontName];
			var listSizes:Array = fontTextureData.listSizes;
			var i:int = 0;
			while (i < listSizes.length && listSizes[i] < size)
			{
				i++;
			}
			
			return i < listSizes.length ? listSizes[i] : listSizes[i - 1];
		}
		
		
		private var _hashChars:Object = new Object();
		private function getTextureIDForChar(font:String, size:uint, char:uint):String
		{
			var fontObject:Object = _hashChars[font];
			if (fontObject == null)
			{
				fontObject = new Object();
				_hashChars[font] = fontObject;
			}
			
			var sizeObject:Object = fontObject[size];
			if (sizeObject == null)
			{
				sizeObject = new Object();
				fontObject[size] = sizeObject;
			}
			
			var charTexture:String = sizeObject[char];
			if (charTexture == null)
			{
				charTexture = font + "_" + size + "_" + char;
				sizeObject[char] = charTexture;
			}
			
			return charTexture;
		}
		
		public function getTextureDataForChar(font:String, size:uint, char:uint, generateIfNeeded:Boolean = false):TextureData
		{
			var charTextureID:String = getTextureIDForChar(font, size, char);
			var textureData:TextureData = _hashFontAtlasDatas[font] != null ? 
				(_hashFontAtlasDatas[font] as FontTextureData).getTextureData(charTextureID) :
				TextureManager.getInstance().getTextureDataByID(charTextureID);
			if (generateIfNeeded &&
				textureData == null &&
				_generateMissingGlyphs)
			{
				generateGlyph(font, size, char);
				textureData = _hashFontAtlasDatas[font] != null ?
					(_hashFontAtlasDatas[font] as FontTextureData).getTextureData(charTextureID) :
					TextureManager.getInstance().getTextureDataByID(charTextureID);
			}
			return textureData;
		}
		
		private var _generateMissingGlyphs:Boolean = false; 
		public function get generateMissingGlyphs():Boolean
		{
			return _generateMissingGlyphs;
		}
		
		public function set generateMissingGlyphs(value:Boolean):void
		{
			_generateMissingGlyphs = value;
		}
		
		private var _tfGenerateGlyph:TextField;
		private var _formatGenerateGlyph:TextFormat;
		private var _matrixGenerateGlyph:Matrix;
		private function generateGlyph(font:String, size:uint, char:uint):void
		{
			if (_tfGenerateGlyph == null)
			{
				_tfGenerateGlyph = new TextField();
			}
			
			if (_formatGenerateGlyph == null)
			{
				_formatGenerateGlyph = new TextFormat();
				_formatGenerateGlyph.color = 0xFFFFFF;
			}
			
			_formatGenerateGlyph.font = font;
			_formatGenerateGlyph.size = size;
			
			_tfGenerateGlyph.embedFonts = true;
			_tfGenerateGlyph.defaultTextFormat = _formatGenerateGlyph;
			_tfGenerateGlyph.text = String.fromCharCode(char);
			
			var charRect:Rectangle = _tfGenerateGlyph.getCharBoundaries(0);
			if (charRect == null || charRect.width == 0 || charRect.width)
			{
				_tfGenerateGlyph.embedFonts = false;
				_formatGenerateGlyph.font = _defaultSystemFont;
				_tfGenerateGlyph.setTextFormat(_formatGenerateGlyph, 0, 1);
				charRect = _tfGenerateGlyph.getCharBoundaries(0);
			}
			
			if (charRect == null || charRect.width == 0 || charRect.height == 0)
			{
				return;
			}
			
			var bitmapData:BitmapData = new BitmapData(Math.round(charRect.width), Math.round(charRect.height), true, 0x00000000);
			
			if (_matrixGenerateGlyph == null)
			{
				_matrixGenerateGlyph = new Matrix();
			}
			
			_matrixGenerateGlyph.identity();
			_matrixGenerateGlyph.translate(-charRect.x, -charRect.y);
			bitmapData.draw(_tfGenerateGlyph, _matrixGenerateGlyph);
			
			if (_hashFontAtlasDatas[font] != null)
			{
				TextureManager.getInstance().addTextureToAtlas(
					bitmapData,
					getTextureIDForChar(font, size, char),
					(_hashFontAtlasDatas[font] as FontTextureData).atlasID
				);
			}
			else
			{
				TextureManager.getInstance().createTextureFromBitmapData(
					bitmapData,
					getTextureIDForChar(font, size, char)
				);
			}
			
			bitmapData.dispose();
		}
	}
}

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.events.Event;
import flash.utils.ByteArray;

import molehill.core.texture.FontTextureData;

class FontImageLoader
{
	private var _fontTextureData:FontTextureData;
	public function get fontTextureData():FontTextureData
	{
		return _fontTextureData;
	}
	
	private var _callback:Function;
	public function FontImageLoader(imageBytes:ByteArray, fontTextureData:FontTextureData, callback:Function)
	{
		_fontTextureData = fontTextureData;
		_callback = callback;
		
		var loader:Loader = new Loader();
		loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onFontImageLoaded);
		loader.loadBytes(imageBytes);
	}
	
	private var _fontBitmapData:BitmapData;
	public function get fontBitmapData():BitmapData
	{
		return _fontBitmapData;
	}

	private function onFontImageLoaded(event:Event):void
	{
		(event.currentTarget as LoaderInfo).removeEventListener(Event.COMPLETE, onFontImageLoaded);
		
		_fontBitmapData = ((event.currentTarget as LoaderInfo).loader.content as Bitmap).bitmapData;
		_callback(this);
	}
}