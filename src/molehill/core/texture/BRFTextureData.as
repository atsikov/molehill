package molehill.core.texture
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	
	import molehill.core.animation.CustomAnimationManager;

	public class BRFTextureData extends TextureAtlasBitmapData
	{
		protected var _rawPNGData:ByteArray;
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
					case 'IMG': // PNG Bytes
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						_rawPNGData = chunkData;
						break;
					
					case 'TAD': // Texture Atlas Data
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
						_textureAtlasData = TextureAtlasData.fromRawData(chunkData.readObject());
						break;
					
					case 'NAC': // Normalized Alpha Channel
						chunkData.writeBytes(rawData, rawData.position, chunkSize);
						chunkData.position = 0;
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
			
			_rawPNGData.position = 16;
			
			var pngWidth:uint = _rawPNGData.readUnsignedInt();
			var pngHeight:uint = _rawPNGData.readUnsignedInt();
			super(pngWidth, pngHeight);
			
			_atlasData = _textureAtlasData;
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageLoaded);
			loader.loadBytes(_rawPNGData);
		}
		
		override public function insert(bitmapData:BitmapData, textureID:String, textureGap:int = 1, nextNode:TextureAtlasDataNode = null):TextureAtlasDataNode
		{
			return null;
		}
		
		private function onImageLoaded(event:Event):void
		{
			var bitmapData:BitmapData = ((event.currentTarget as LoaderInfo).content as Bitmap).bitmapData;
			
			copyPixels(bitmapData, bitmapData.rect, new Point());
			TextureManager.getInstance().reuploadTexture(this);
		}
		
		public function get rawPNGData():ByteArray
		{
			return _rawPNGData;
		}
		
		public function get rawSpriteAnimationData():Object
		{
			return _rawSpriteAnimationData;
		}
	}
}