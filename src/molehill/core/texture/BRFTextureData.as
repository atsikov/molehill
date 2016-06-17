package molehill.core.texture
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.BitmapDataChannel;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import molehill.core.animation.CustomAnimationManager;

	public class BRFTextureData extends TextureAtlasBitmapData
	{
		protected var _rawImageData:ByteArray;
		protected var _rawImageAlphaData:ByteArray;
		
		private var _loaderImageData:Loader;
		private var _loaderImageAlphaData:Loader;
		
		private var _rawSpriteAnimationData:Object;
		protected var _textureAtlasData:TextureAtlasData;
		public function BRFTextureData(rawData:ByteArray)
		{
			rawData.position = 0;
			
			while (rawData.bytesAvailable)
			{
				var header:String = rawData.readUTFBytes(3);
				var chunkSize:int = 0x10000 * rawData.readUnsignedByte() + 0x100 * rawData.readUnsignedByte() + rawData.readUnsignedByte();
				var chunkData:ByteArray = new ByteArray();
				switch (header)
				{
					case 'IMG': // PNG or JPEG Bytes
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						_rawImageData = chunkData;
						break;
					
					case 'IAD': // Image Alpha Data (PNG with alpha) bytes
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						_rawImageAlphaData = chunkData;
						break;
					
					case 'TAD': // Texture Atlas Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_textureAtlasData = TextureAtlasData.fromRawData(chunkData.readObject());
						break;
					
					case 'NA_': // Normalized Alpha Channel with LZMA compression
					case 'NAC': // Normalized Alpha Channel
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						
						if (header == 'NA_')
						{
							chunkData.uncompress('lzma');
						}
						
						_textureAtlasData.addNormalizedAplhaData(chunkData);
						break;
					
					case 'SAD': // Sprite Animation Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_rawSpriteAnimationData = chunkData.readObject();
						break;
					
					case 'SAP': // Sprite Animation Package
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						CustomAnimationManager.getInstance().registerAnimations(chunkData);
						break;
				}
				rawData.position += chunkSize;
			}
			
			var imageWidth:uint = 0;
			var imageHeight:uint = 0;
			_rawImageData.position = 0;
			
			var byte0:uint = _rawImageData.readUnsignedByte();
			var byte1:uint = _rawImageData.readUnsignedByte();
			var byte2:uint = _rawImageData.readUnsignedByte();
			
			if (byte0 == 137 &&
				byte1 == 80 &&
				byte2 == 78)
			{
				_rawImageData.position = 16;
				
				imageWidth = _rawImageData.readUnsignedInt();
				imageHeight = _rawImageData.readUnsignedInt();
			}
			else
			{
				var position:int = 0;
				
				var isJPEG:Boolean = false;
				while (!isJPEG && position < _rawImageData.length - 3)
				{
					_rawImageData.position = position;
					
					byte0 = _rawImageData.readUnsignedByte();
					byte1 = _rawImageData.readUnsignedByte();
					byte2 = _rawImageData.readUnsignedByte();
					
					if (byte0 == 0xFF &&
						byte1 == 0xD8 &&
						byte2 == 0xFF)
					{
						isJPEG = true;
						break;
					}
					
					position++;
				}
				
				if (isJPEG)
				{
					var hasSize:Boolean = false;
					while (!hasSize && position < _rawImageData.length - 3)
					{
						_rawImageData.position = position;
						
						byte0 = _rawImageData.readUnsignedByte();
						byte1 = _rawImageData.readUnsignedByte();
						
						if (byte0 == 0xFF)
						{
							switch (byte1)
							{
								case 0xC0:
								case 0xC1:
								case 0xC2:
								case 0xC3:
								case 0xC5:
								case 0xC6:
								case 0xC7:
								case 0xC9:
								case 0xCA:
								case 0xCB:
								case 0xCD:
								case 0xCE:
								case 0xCF:
									_rawImageData.position = position + 5;
									imageHeight = _rawImageData.readUnsignedShort();
									imageWidth = _rawImageData.readUnsignedShort();
									
									hasSize = true;
									break;
							}
						}
						
						position++;
					}
				}
				
			}
			
			super(imageWidth, imageHeight);
			
			_atlasData = _textureAtlasData;
			
			_rawImageData.position = 0;
			_loaderImageData = new Loader();
			_loaderImageData.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
			_loaderImageData.loadBytes(_rawImageData);
		}
		
		override public function insert(bitmapData:BitmapData, textureID:String, textureGap:int=1, extrudeEdges:Boolean=false, nextNode:TextureAtlasDataNode=null):TextureAtlasDataNode
		{
			return null;
		}
		
		private function onImageLoaded(event:Event):void
		{
			if (_rawImageAlphaData != null)
			{
				_rawImageAlphaData.position = 0;
				_loaderImageAlphaData = new Loader();
				_loaderImageAlphaData.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageAlphaLoaded);
				_loaderImageAlphaData.loadBytes(_rawImageAlphaData);
				
				return;
			}
			
			uploadImage();
		}
		
		private function onImageAlphaLoaded(event:Event):void
		{
			uploadImage();
		}
		
		private function uploadImage():void
		{
			var bitmapData:BitmapData = (_loaderImageData.content as Bitmap).bitmapData;
			copyPixels(bitmapData, bitmapData.rect, new Point());
			bitmapData.dispose();
			
			if (_loaderImageAlphaData != null)
			{
				var alphaBitmapData:BitmapData = (_loaderImageAlphaData.content as Bitmap).bitmapData;
				copyChannel(alphaBitmapData, alphaBitmapData.rect, new Point(), BitmapDataChannel.RED, BitmapDataChannel.ALPHA);
				alphaBitmapData.dispose();
				_loaderImageAlphaData = null;
			}
					
			_loaderImageData = null;
			
			TextureManager.getInstance().reuploadTexture(this);
		}
		
		public function get rawPNGData():ByteArray
		{
			return _rawImageData;
		}
		
		public function get rawSpriteAnimationData():Object
		{
			return _rawSpriteAnimationData;
		}
	}
}