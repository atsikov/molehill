package molehill.core.texture
{
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;

	public class TextureAtlasData
	{
		private static const ADDITIONAL_RAW_FIELDS:Array = ['originalWidth', 'originalHeight', 'blankOffsetX', 'blankOffsetY'];
		public static function fromRawData(rawData:Object):TextureAtlasData
		{
			var atlasData:TextureAtlasData = new TextureAtlasData(rawData.width, rawData.height);
			
			var texturesInfo:Object = rawData.info;
			for (var textureID:String in texturesInfo)
			{
				var rawTextureData:Object = texturesInfo[textureID];
				
				atlasData.addTextureDesc(
					textureID,
					rawTextureData.left,
					rawTextureData.top,
					rawTextureData.width,
					rawTextureData.height,
					SpriteSheetData.fromRawData(rawTextureData.spriteSheetData)
				);
				
				var textureData:TextureData = atlasData.getTextureData(textureID);
				for (var i:int = 0; i < ADDITIONAL_RAW_FIELDS.length; i++)
				{
					var field:String = ADDITIONAL_RAW_FIELDS[i];
					if (rawTextureData[field] != null)
					{
						textureData[field] = rawTextureData[field];
					}
				}
			}
			
			return atlasData;
		}
		
		private var _atlasWidth:uint = 0;
		private var _atlasHeight:uint = 0;
		public function TextureAtlasData(atlasWidth:uint, atlasHeight:uint)
		{
			_atlasID = "atlas" + uint(Math.random() * uint.MAX_VALUE).toString();
			
			_atlasWidth = atlasWidth;
			_atlasHeight = atlasHeight;
			
			_hashTextures = new Object();
		}
		
		internal var _hashTextures:Object;
		internal function addTextureDesc(textureID:String, left:uint, top:uint, width:int, height:int, spriteSheetData:SpriteSheetData = null):void
		{
			_hashTextures[textureID] = new TextureData(textureID, left, top, width, height, spriteSheetData);
			_listTextureNames = null;
		}
		
		public function getTextureData(textureID:String):TextureData
		{
			return _hashTextures[textureID];
		}
		
		private var _hashTextureRegion:Object = new Object();
		public function getTextureBitmapRect(textureID:String):Rectangle
		{
			var textureData:TextureData = _hashTextures[textureID];
			if (textureData == null)
			{
				return null;
			}
			
			return textureData.textureRect;
		}
		
		public function getTextureRegion(textureID:String):Rectangle
		{
			var textureData:TextureData = _hashTextures[textureID];
			if (textureData == null)
			{
				return null;
			}
			
			if (_hashTextureRegion[textureID] == null)
			{
				_hashTextureRegion[textureID] = new Rectangle(
					textureData.left / _atlasWidth,
					textureData.top / _atlasHeight,
					textureData.width / _atlasWidth,
					textureData.height / _atlasHeight
				);
			}
			
			return _hashTextureRegion[textureID];
		}
		
		private var _atlasID:String;
		public function get atlasID():String
		{
			return _atlasID;
		}
		
		/**
		 *  !!! Do NOT change this value after texture was added to TextureManager !!!
		 **/
		public function set atlasID(value:String):void
		{
			_atlasID = value;
		}
		
		public function get width():int
		{
			return _atlasWidth;
		}
		
		public function get height():int
		{
			return _atlasHeight;
		}
		
		public function getRawData():Object
		{
			var texturesRawData:Object = JSON.parse(JSON.stringify(_hashTextures));
			for each (var textureData:Object in texturesRawData)
			{
				delete textureData['textureRegion'];
				
				if (textureData['originalWidth'] == textureData['width'] &&
					textureData['originalHeight'] == textureData['height'] &&
					textureData['blankOffsetX'] == 0 &&
					textureData['blankOffsetY'] == 0)
				{
					delete textureData['originalWidth'];
					delete textureData['originalHeight'];
					delete textureData['blankOffsetX'];
					delete textureData['blankOffsetY'];
				}
			}
			var rawData:Object = {
				'width': _atlasWidth,
				'height': _atlasHeight,
				'info': texturesRawData
			};
			
			return rawData;
		}
		
		private var _listTextureNames:Array;
		public function get listTexturesNames():Array
		{
			if (_listTextureNames == null)
			{
				_listTextureNames = new Array();
				for (var textureName:String in _hashTextures)
				{
					_listTextureNames.push(textureName);
				}
				_listTextureNames.sort();
			}
			
			return _listTextureNames;
		}
		
		public function renameTexture(oldName:String, newName:String):void
		{
			if (_hashTextures[oldName] == null)
			{
				return;
			}
			
			_hashTextures[newName] = _hashTextures[oldName];
			delete _hashTextures[oldName];
			
			(_hashTextures[newName] as TextureData).rename(newName);
		}
		
		internal function addNormalizedAplhaData(rawData:ByteArray):void
		{
			while (rawData.bytesAvailable > 0)
			{
				var textureID:String = rawData.readUTF();
				var chunkSize:int = rawData.readUnsignedShort(); // 4 bytes for width and height + width / 8 * height bytes for alpha data
				var chunkData:ByteArray = new ByteArray();
				chunkData.writeBytes(rawData, rawData.position, chunkSize);
				rawData.position += chunkSize;
				
				getTextureData(textureID).setNormalizedAlpha(
					new NormalizedAlphaChannel(chunkData)
				);
			}
		}
	}
}