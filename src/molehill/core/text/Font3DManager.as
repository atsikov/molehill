package molehill.core.text
{
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import molehill.core.events.Font3DManagerEvent;
	import molehill.core.texture.FontARFTextureData;
	import molehill.core.texture.FontBRFTextureData;
	import molehill.core.texture.FontTextureData;
	import molehill.core.texture.TextureManager;

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
			
			_hashLoadedFonts = new Object();
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
			
			TextureManager.getInstance().createCompressedTextureFromARF(fontTexture);
			_hashLoadedFonts[(fontTexture.textureAtlasData as FontTextureData).fontName] = fontTexture.textureAtlasData;
			
			dispatchEvent(
				new Font3DManagerEvent(Font3DManagerEvent.FONT_READY, (fontTexture.textureAtlasData as FontTextureData).fontName)
			);
		}
		
		private function onFontLoadError(event:Event):void
		{
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
		
		private function onBitmapFontLoaded(event:Event):void
		{
			var bytes:ByteArray = (event.currentTarget as URLLoader).data;
			
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
		
		private function onBitmapFontImageLoaded(loader:FontImageLoader):void
		{
			var tm:TextureManager = TextureManager.getInstance();
			
			var fontBitmap:FontBRFTextureData = new FontBRFTextureData(loader.fontBitmapData, loader.fontTextureData);
			TextureManager.getInstance().createFontTextureFromBitmapData(fontBitmap);
			
			_hashLoadedFonts[loader.fontTextureData.fontName] = loader.fontTextureData;
			
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
		
		private var _hashLoadedFonts:Object;
		public function isFontLoaded(fontName:String):Boolean
		{
			return _hashLoadedFonts[fontName] != null;
		}
		
		public function getSuitableFontSize(fontName:String, size:int):int
		{
			if (!isFontLoaded(fontName))
			{
				return -1;
			}
			
			var fontTextureData:FontTextureData = _hashLoadedFonts[fontName];
			var listSizes:Array = fontTextureData.listSizes;
			var i:int = 0;
			while (i < listSizes.length && listSizes[i] < size)
			{
				i++;
			}
			
			return i < listSizes.length ? listSizes[i] : listSizes[i - 1];
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
		_fontBitmapData = ((event.currentTarget as LoaderInfo).loader.content as Bitmap).bitmapData;
		_callback(this);
	}
}