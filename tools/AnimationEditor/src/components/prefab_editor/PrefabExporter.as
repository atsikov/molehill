package components.prefab_editor
{
	import atlas_compositor.config.ConfigEditorView;
	import atlas_compositor.config.ConfigProcessor;
	import atlas_compositor.config.TextureBitmapData;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.geom.Point;
	import flash.net.SharedObject;
	import flash.utils.ByteArray;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import molehill.core.animation.CustomAnimationFrameData;
	import molehill.core.render.IVertexBatcher;
	import molehill.core.render.particles.ParticleEmitter;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.CustomAnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	import molehill.easy.ui3d.Sprite3D9Scale;
	import molehill.easy.ui3d.TiledSprite3D;
	
	import mx.core.FlexGlobals;
	import mx.managers.PopUpManager;
	
	import spark.components.WindowedApplication;

	public class PrefabExporter
	{
		private static var _instance:PrefabExporter;
		public static function getInstance():PrefabExporter
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new PrefabExporter();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function PrefabExporter()
		{
			if (!_allowInstantion)
			{
				throw new Error('Use SpriteStructureExporter::getInstance()');
			}
			
			saveListDefaultValues(new Sprite3D());
			saveListDefaultValues(new Sprite3DContainer());
			saveListDefaultValues(new CustomAnimatedSprite3D());
			saveListDefaultValues(new TextField3D());
			saveListDefaultValues(new TiledSprite3D());
			saveListDefaultValues(new ParticleEmitter());
		}
		
		private var _hashDefaultValuesByClass:Object;
		private function saveListDefaultValues(sprite:Sprite3D):void
		{
			var className:String = getQualifiedClassName(sprite);
			var def:XML = describeType(sprite);
			
			var accessors:XMLList = def['accessor'].(@access=='readwrite');
			var accessorsUsable:XMLList = accessors.(@type=='Number' || @type=='int' || @type=='uint' || @type=='String' || @type=='Boolean');
			
			var defaultValues:Object = new Object();
			for each (var node:XML in accessorsUsable) 
			{
				defaultValues[node.@name] = sprite[node.@name];
			}
			
			if (_hashDefaultValuesByClass == null)
			{
				_hashDefaultValuesByClass = new Object();
			}
			_hashDefaultValuesByClass[className] = defaultValues;
		}
		
		private var _container:Sprite3DContainer;
		private var _embedTexture:Boolean = false;
		private var _textureBytes:ByteArray = null;
		public function savePrefab(container:Sprite3DContainer, embedTexture:Boolean = false, textureBytes:ByteArray = null):void
		{
			_container = container;
			_embedTexture = embedTexture;
			_textureBytes = textureBytes;
			
			var so:SharedObject = SharedObject.getLocal("PrefabEditorSettings");
			var lastPath:String = so.data.lastSaveFilePath;
			
			var file:File = new File(lastPath);
			file.addEventListener(Event.SELECT, onSaveFileSelected);
			
			file.browseForSave("Save prefab");
		}
		
		private var _filePrefab:File;
		private var _textureSettings:ConfigEditorView;
		protected function onSaveFileSelected(event:Event):void
		{
			_filePrefab = event.currentTarget as File;
			
			if (_embedTexture && _textureBytes == null)
			{
				if (_textureSettings == null)
				{
					_textureSettings = new ConfigEditorView();
					_textureSettings.addEventListener(Event.COMPLETE, onTextureSettingsApplied);
				}
				
				PopUpManager.centerPopUp(_textureSettings);
				PopUpManager.addPopUp(_textureSettings, FlexGlobals.topLevelApplication as DisplayObject, true);
			}
			else
			{
				savePrefabFile();
			}
		}
		
		private function onTextureSettingsApplied(event:Event):void
		{
			_listTextures = new Array();
			var rawSceneData:Array = saveSceneStructure(_container);
			
			if (_listTextures.length > 0)
			{
				TextureExplorerComponent.prepareBitmapDatasForTetxures(_listTextures, onTexturesReady);
			}
			else
			{
				savePrefabFile();
			}
		}
		
		private function onTexturesReady():void
		{
			var listBitmaps:Vector.<TextureBitmapData> = new Vector.<TextureBitmapData>();
			for (var i:int = 0; i < _listTextures.length; i++)
			{
				var bitmap:BitmapData = TextureExplorerComponent.getBitmapDataForTexture(_listTextures[i]);
				if (bitmap == null)
				{
					continue;
				}
				
				var textureBitmapData:TextureBitmapData = new TextureBitmapData(bitmap.width, bitmap.height, true, 0x00000000);
				textureBitmapData.copyPixels(bitmap, bitmap.rect, new Point());
				textureBitmapData.textureID = _listTextures[i];
				listBitmaps.push(textureBitmapData);
				
			}
			
			_textureSettings.configData.listBitmaps = listBitmaps;
			_textureSettings.configData.removeTemp = true;
			_textureSettings.configData.sourcePath = _filePrefab.nativePath;
			
			ConfigProcessor.getInstance().addEventListener(Event.COMPLETE, onTextureReady);
			ConfigProcessor.getInstance().applyConfig(_textureSettings.configData, FlexGlobals.topLevelApplication as WindowedApplication);
		}
		
		private function onTextureReady(event:Event):void
		{
			savePrefabFile();
		}
		
		private function savePrefabFile():void
		{
			_listTextures = new Array();
			var rawSceneData:Array = saveSceneStructure(_container);
			var pathToLowerCase:String = _filePrefab.nativePath.toLowerCase();
			if (pathToLowerCase.lastIndexOf('.pre') != pathToLowerCase.length - 4)
			{
				_filePrefab.nativePath += '.pre';
			}
			
			var so:SharedObject = SharedObject.getLocal("PrefabEditorSettings");
			so.data.lastSaveFilePath = _filePrefab.parent.nativePath;
			so.flush();
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(_filePrefab, FileMode.WRITE);
			
			var bytes:ByteArray = new ByteArray();
			var listRawAnimations:Array = new Array();
			
			bytes.writeObject(rawSceneData);
			
			fileStream.writeByte(('P').charCodeAt(0));
			fileStream.writeByte(('R').charCodeAt(0));
			fileStream.writeByte(('E').charCodeAt(0));
			
			var size:int = bytes.length;
			var s1:int = (size >> 16) & 0xFF;
			var s2:int = (size >> 8) & 0xFF;
			var s3:int = size & 0xFF;
			
			fileStream.writeByte(s1);
			fileStream.writeByte(s2);
			fileStream.writeByte(s3);
			
			fileStream.writeBytes(bytes);
			
			if (_embedTexture && _listTextures.length > 0)
			{
				if (_textureBytes == null)
				{
					var fileExt:String = _textureSettings.configData.compressAtlas ? ".arf" : ".brf";
					var parentFolderName:String = _filePrefab.parent.name;
					var parentFolderPath:String = _filePrefab.parent.nativePath;
					var textureFile:File = new File(parentFolderPath + File.separator + parentFolderName + fileExt);
					
					var textureFileStream:FileStream = new FileStream();
					textureFileStream.open(textureFile, FileMode.READ);
					
					var textureBytes:ByteArray = new ByteArray();
					textureFileStream.readBytes(textureBytes);
					textureFileStream.close();
					
					fileStream.writeBytes(textureBytes);
					
					try
					{
						textureFile.deleteFile();
					} 
					catch(error:Error) 
					{
						
					}
				}
				else
				{
					fileStream.writeBytes(_textureBytes);
				}
			}
			
			fileStream.close();
		}
		
		private var _listTextures:Array;
		private function saveSceneStructure(container:Sprite3DContainer):Array
		{
			var pointer:Array = new Array();
			
			for (var i:int = 0; i < container.numChildren; i++)
			{
				var child:Sprite3D = container.getChildAt(i);
				pointer[i] = new Object();
				pointer[i].values = getSpriteChangedValues(child);
				
				if (child is TextField3D ||
					child is TiledSprite3D ||
					child is Sprite3D9Scale)
				{
					continue;
				}
				else if (child is Sprite3DContainer)
				{
					pointer[i].children = saveSceneStructure(child as Sprite3DContainer);
				}
			}
			
			return pointer;
		}
		
		private function getSpriteChangedValues(sprite:Sprite3D):Object
		{
			var values:Object = new Object();
			var className:String = getQualifiedClassName(sprite);
			values['class_name'] = className;
			if (sprite.textureID != null && !(sprite is TextField3D) && !(sprite is AnimatedSprite3D))
			{
				values['textureID'] = sprite.textureID;
				if (_listTextures.indexOf(sprite.textureID) == -1 && !(sprite is ParticleEmitter))
				{
					_listTextures.push(sprite.textureID);
				}
			}
			
			if (_hashDefaultValuesByClass[className] == null)
			{
				return values;
			}
			
			if (sprite is CustomAnimatedSprite3D && (sprite as CustomAnimatedSprite3D).customAnimationData != null)
			{
				var rawCustomAnimationData:Object = JSON.parse(
					JSON.stringify(
						(sprite as CustomAnimatedSprite3D).customAnimationData
					)
				);
				delete rawCustomAnimationData['frameTime'];
				delete rawCustomAnimationData['totalFrames'];
				delete rawCustomAnimationData['animationDuration'];
				values['custom_animation'] = rawCustomAnimationData;
				
				var listFrames:Vector.<CustomAnimationFrameData> = (sprite as CustomAnimatedSprite3D).customAnimationData.listFrames;
				for (var i:int = 0; i < listFrames.length; i++)
				{
					var textureID:String = listFrames[i].textureName;
					if (_listTextures.indexOf(textureID) == -1)
					{
						_listTextures.push(textureID);
					}
				}
			}

			var spriteClassValues:Object = _hashDefaultValuesByClass[className];
			for (var field:String in spriteClassValues)
			{
				if (sprite is Sprite3DContainer && !(sprite is TiledSprite3D) && !(sprite is TextField3D) && !(sprite is Sprite3D9Scale))
				{
					if (SpritePropertiesView.IGNORE_CONTAINER_PROP_CHANGES.indexOf(field) != -1)
					{
						continue;
					}
				}
				
				if (sprite[field] != spriteClassValues[field])
				{
					values[field] = sprite[field];
				}
			}
			
			if (sprite.shader != null && (sprite.shader.textureReadParams & Shader3D.TEXTURE_DONT_USE_TEXTURE) > 0)
			{
				values['shader'] = 'color';
			}
			
			if (sprite is IVertexBatcher)
			{
				delete values['textureAtlasID'];
			}
			
			return values;
		}
	}
}