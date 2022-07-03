package atlas_compositor.config
{
	import atlas_compositor.components.ImageViewer;
	import atlas_compositor.components.PopupHighlights;
	import atlas_compositor.components.PopupLoadingImages;
	import atlas_compositor.components.TextPrompt;
	import atlas_compositor.model.types.TemplateClassCreation;
	
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.events.NativeProcessExitEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.SharedObject;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	
	import model.events.TextPromptEvent;
	
	import molehill.core.texture.SpriteSheet;
	import molehill.core.texture.SpriteSheetData;
	import molehill.core.texture.TextureAtlasBitmapData;
	import molehill.core.texture.TextureData;
	
	import mx.events.FlexEvent;
	import mx.events.ResizeEvent;
	import mx.graphics.codec.PNGEncoder;
	import mx.managers.PopUpManager;
	
	import spark.components.TextArea;
	import spark.components.WindowedApplication;
	
	public class ConfigProcessor extends EventDispatcher
	{
		private static var _instance:ConfigProcessor
		public static function getInstance():ConfigProcessor
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new ConfigProcessor();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function ConfigProcessor()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use ConfigProcessor::getInstance()");
			}
			
			_popupHighlights = new PopupHighlights();
			
			_popupHighlights.addEventListener(FlexEvent.CREATION_COMPLETE, onPopupHighlightsCreationComplete);
			
			_popupLoadingImages = new PopupLoadingImages();
			_popupLoadingImages.addEventListener(FlexEvent.CREATION_COMPLETE, onPopupLoadingImagesCreationComplete);
		}
		
		private var _popupHighlightsCreated:Boolean = false;
		private var _popupLoadingImagesCreated:Boolean = false;
		
		private function onPopupLoadingImagesCreationComplete(event:FlexEvent):void
		{
			_popupLoadingImagesCreated = true;
			PopUpManager.removePopUp(_popupLoadingImages);
			
			if (isReady && _delayedApply)
			{
				applyConfig(_configData, _mainApp, _taLog);
			}
		}
		
		private function onPopupHighlightsCreationComplete(event:FlexEvent):void
		{
			_popupHighlightsCreated = true;
			_popupHighlights.btnHighlightsOK.addEventListener(MouseEvent.CLICK, onBtnHighlightsOKClick);
			_popupHighlights.btnHighlightsCancel.addEventListener(MouseEvent.CLICK, onBtnHighlightsCancelClick);
			
			PopUpManager.removePopUp(_popupHighlights);
			PopUpManager.addPopUp(_popupLoadingImages, _mainApp, true);
			PopUpManager.centerPopUp(_popupLoadingImages);
		}
		
		private function get isReady():Boolean
		{
			return _popupHighlightsCreated && _popupLoadingImagesCreated;
		}
		
		private var _taLog:TextArea = new TextArea();
		private var _mainApp:WindowedApplication;
		private var _popupLoadingImages:PopupLoadingImages;
		private var _popupHighlights:PopupHighlights;
		//private var _tgListImages:TileGroup;
		
		private var _chosenPNG:File;
		private var _configData:ConfigData;
		
		private var _delayedApply:Boolean;

		public function applyConfig(
			configData:ConfigData, 
			mainApp:WindowedApplication,
			taLog:TextArea = null
		):void
		{
			_configData = configData;
			_mainApp = mainApp;
			_mainApp.addEventListener(ResizeEvent.RESIZE, onMainAppResized);
			_taLog = taLog;
			
			if (!isReady)
			{
				_delayedApply = true;
				_mainApp.enabled = false;
				PopUpManager.addPopUp(_popupHighlights, _mainApp, true);
				PopUpManager.centerPopUp(_popupHighlights);
				return;
			}
			else
			{
				_delayedApply = false;
				_mainApp.enabled = true;
			}
			
			try
			{
				_chosenPNG = new File(configData.sourcePath);
			} 
			catch(error:Error) 
			{
				_chosenPNG = null;
			}
			
			if (_chosenPNG == null)
			{
				var so:SharedObject = SharedObject.getLocal("PrefabEditorSettings");
				var lastPath:String = so.data.lastPath;
				
				_chosenPNG = new File(lastPath);
				_chosenPNG.addEventListener(Event.SELECT, onSourcePNGChosen);
				_chosenPNG.browseForOpen("Please select PNG file...", [new FileFilter("PNG Image", "*.png")]);
			}
			else
			{
				onSourcePNGChosen(null);
			}
		}
		
		private function onMainAppResized(event:ResizeEvent):void
		{
			if (_popupHighlights.stage != null)
			{
				PopUpManager.centerPopUp(_popupHighlights);
			}
			
			if (_popupLoadingImages.stage != null)
			{
				PopUpManager.centerPopUp(_popupLoadingImages);
			}
		}
		
		private var _currentFolder:File;
		private var _currentBitmaps:Object;
		private var _currentFileName:String = "";
		private var _listBitmaps:Array;
		private var _hashCropRects:Dictionary;
		private var _hashOrigBitmaps:Dictionary;
		private var _listHighlightBitmaps:Array;
		
		private var _currentFileIndex:int = 0;
		private var _currentFile:File;
		//private var _currentFolder:File;
		
		private var _listTextureNames:Array;
		private var _loadedAnimationPackage:ByteArray;
		
		private function onSourcePNGChosen(event:Event):void
		{
			if (_taLog != null)
			{
				_taLog.appendText("Process config: " + _configData.label + "\n");
				_taLog.appendText(_chosenPNG.nativePath + " selected for processing\n");
			}
			_currentFolder = new File(_chosenPNG.isDirectory ? _chosenPNG.nativePath : _chosenPNG.parent.nativePath);
			_currentBitmaps = new Object();
			_listBitmaps = new Array();
			_currentFileIndex = 0;
			_loadedAnimationPackage = null;
			
			_hashCropRects = null;
			_hashOrigBitmaps = null;
			
			var so:SharedObject = SharedObject.getLocal("PrefabEditorSettings");
			so.data.lastPath = _currentFolder.nativePath;
			so.flush();
			
			_listHighlightBitmaps = null;
			if (_mainApp != null)
			{
				_mainApp.enabled = false;
			}
			
			if (_configData.listBitmaps != null)
			{
				for (var i:int = 0; i < _configData.listBitmaps.length; i++)
				{
					var textureBitmapData:TextureBitmapData = _configData.listBitmaps[i];
					_currentFileName = textureBitmapData.textureID + ".bmd";
					
					var bitmapData:BitmapData = textureBitmapData;
					if (_configData.cropWhitespace)
					{
						bitmapData = cropWhitespate(bitmapData);
					}
					_currentBitmaps[_currentFileName] = bitmapData;
					_listBitmaps.push(bitmapData);
				}
				
				processLoadedImages();
			}
			else
			{
				PopUpManager.addPopUp(_popupLoadingImages, _mainApp, true);
				PopUpManager.centerPopUp(_popupLoadingImages);
				
				processNextImage();
			}
		}
		
		private function processNextImage():void
		{
			_popupLoadingImages.prgImages.setProgress(_currentFileIndex, _currentFolder.getDirectoryListing().length);
			
			if (_currentFileIndex >= _currentFolder.getDirectoryListing().length)
			{
				PopUpManager.removePopUp(_popupLoadingImages);
				processLoadedImages();
				return;
			}
			
			do
			{
				_currentFile = _currentFolder.getDirectoryListing()[_currentFileIndex];
				_currentFileIndex++;
			}
			while (_currentFileIndex < _currentFolder.getDirectoryListing().length && (_currentFile.isDirectory || _currentFile.name.indexOf(".png") == -1));
			
			if (_currentFile.isDirectory || _currentFile.name.indexOf(".png") == -1)
			{
				PopUpManager.removePopUp(_popupLoadingImages);
				processLoadedImages();
				return;
			}
			
			var fileStream:FileStream = new FileStream();
			fileStream.open(_currentFile, FileMode.READ);
			
			var bdBytes:ByteArray = new ByteArray();
			fileStream.readBytes(bdBytes, 0, _currentFile.size);
			fileStream.close();
			
			_currentFileName = _currentFile.name;
			
			var loader:Loader = new Loader();
			loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onImageReady);
			loader.loadBytes(bdBytes);
		}
		
		private function onImageReady(event:Event):void
		{
			var bitmapData:BitmapData = ((event.currentTarget as LoaderInfo).loader.content as Bitmap).bitmapData;
			if (_configData.cropWhitespace)
			{
				bitmapData = cropWhitespate(bitmapData);
			}
			
			_currentBitmaps[_currentFileName] = bitmapData;
			_listBitmaps.push(bitmapData);
			processNextImage();
		}
		
		private function cropWhitespate(bitmapData:BitmapData):BitmapData
		{
			var origWidth:int = bitmapData.width;
			var origHeight:int = bitmapData.height;
			
			var cropRect:Rectangle = new Rectangle();
			
			// check left side
			var border:int = 0;
			for (var i:int = 0; i < bitmapData.width / 2; i++)
			{
				for (var j:int = 0; j < bitmapData.height; j++)
				{
					var pixel:uint = bitmapData.getPixel32(i, j);
					if (pixel > 0x1000000)
					{
						break;
					}
				}
				
				if (j == bitmapData.height)
				{
					border++;
				}
				else
				{
					break;
				}
			}
			
			cropRect.left = border;
			
			// check right side
			border = 0;
			for (i = bitmapData.width - 1; i > bitmapData.width / 2; i--)
			{
				for (j = 0; j < bitmapData.height; j++)
				{
					pixel = bitmapData.getPixel32(i, j);
					if (pixel > 0x1000000)
					{
						break;
					}
				}
				
				if (j == bitmapData.height)
				{
					border++;
				}
				else
				{
					break;
				}
			}
			
			cropRect.right = bitmapData.width - border;
			
			// check top side
			border = 0;
			for (i = 0; i < bitmapData.height / 2; i++)
			{
				for (j = cropRect.left; j < cropRect.right; j++)
				{
					pixel = bitmapData.getPixel32(j, i);
					if (pixel > 0x1000000)
					{
						break;
					}
				}
				
				if (j == cropRect.right)
				{
					border++;
				}
				else
				{
					break;
				}
			}
			
			cropRect.top = border;
			
			// check bottom side
			border = 0;
			for (i = bitmapData.height - 1; i > bitmapData.height / 2; i--)
			{
				for (j = cropRect.left; j < cropRect.right; j++)
				{
					pixel = bitmapData.getPixel32(j, i);
					if (pixel > 0x1000000)
					{
						break;
					}
				}
				
				if (j == cropRect.right)
				{
					border++;
				}
				else
				{
					break;
				}
			}
			
			cropRect.bottom = bitmapData.height - border;
			
			if (cropRect.width != bitmapData.width || cropRect.height != bitmapData.height)
			{
				if (_hashCropRects == null)
				{
					_hashCropRects = new Dictionary();
				}
				
				if (_hashOrigBitmaps == null)
				{
					_hashOrigBitmaps = new Dictionary();
				}
				
				var croppedBitmapData:BitmapData = new BitmapData(cropRect.width, cropRect.height, true, 0x00000000);
				croppedBitmapData.copyPixels(bitmapData, cropRect, new Point());
				
				_hashOrigBitmaps[croppedBitmapData] = bitmapData;
				
				bitmapData = croppedBitmapData;
				cropRect.width = origWidth;
				cropRect.height = origHeight;
				_hashCropRects[bitmapData] = cropRect;
			}
			
			return bitmapData;
		}
		
		private function showHighlightsSelector():void
		{
			_popupHighlights.tgListImages.removeAllElements();
			
			PopUpManager.addPopUp(_popupHighlights, _mainApp, true);
			PopUpManager.centerPopUp(_popupHighlights);
			
			var listNames:Array = new Array();
			for (var bitmapName:String in _currentBitmaps)
			{
				listNames[_listBitmaps.indexOf(_currentBitmaps[bitmapName])] = bitmapName;
			}
			
			for (var i:int = 0; i < _listBitmaps.length; i++)
			{
				var tile:ImageViewer = new ImageViewer();
				tile.setImage(_listBitmaps[i], listNames[i]);
				
				_popupHighlights.tgListImages.addElement(tile);
			}
		}
		
		private function onBtnHighlightsOKClick(event:MouseEvent):void
		{
			_listHighlightBitmaps = new Array();
			
			for (var i:int = 0; i < _popupHighlights.tgListImages.numElements; i++)
			{
				var element:ImageViewer = _popupHighlights.tgListImages.getElementAt(i) as ImageViewer;
				if (element == null || !element.chkImageName.selected)
				{
					continue;
				}
				
				_listHighlightBitmaps.push(element.imgSource.source);
			}
			
			PopUpManager.removePopUp(_popupHighlights);
			processLoadedImages();
		}
		
		private function onBtnHighlightsCancelClick(event:MouseEvent):void
		{
			PopUpManager.removePopUp(_popupHighlights);
			_listHighlightBitmaps = new Array();
			
			processLoadedImages();
		}
		
		private function browseForSAP():void
		{
			var file:File = new File(_currentFolder.nativePath);
			file.addEventListener(Event.SELECT, onSapSelected);
			file.browseForOpen(
				"Select animation package to embed",
				[
					new FileFilter("SAP Package", "*.sap", "*.sap")
				]
			);
		}
		
		protected function onSapSelected(event:Event):void
		{
			var file:File = event.currentTarget as File;
			
			var inputStream:FileStream = new FileStream();
			inputStream.open(file, FileMode.READ);
			
			_loadedAnimationPackage = new ByteArray();
			inputStream.readBytes(_loadedAnimationPackage, 0, file.size);
			inputStream.close();
			
			processLoadedImages();
		}
		
		private function processLoadedImages():void
		{
			if (_listHighlightBitmaps == null && _configData.createHighlights)
			{
				showHighlightsSelector();
				return;
			}
			
			if (_configData.embedAnimation && _loadedAnimationPackage == null)
			{
				browseForSAP();
				return;
			}
			
			_listTextureNames = new Array();
			var hashAlphaByName:Object = new Object();
			var baseBitmap:BitmapData;
			var bitmapName:String;
			if (!_configData.combineSpriteSheet)
			{
				_listBitmaps.sortOn("width", Array.NUMERIC | Array.DESCENDING);
			}
			
			var hashHighlights:Object = new Object();
			for (bitmapName in _currentBitmaps)
			{
				var bitmapData:BitmapData = _currentBitmaps[bitmapName];
				_listTextureNames[_listBitmaps.indexOf(bitmapData)] = bitmapName.substr(0, bitmapName.length - 4);
				
				if (_listHighlightBitmaps != null && _listHighlightBitmaps.indexOf(bitmapData) != -1)
				{
					bitmapData = _hashOrigBitmaps[bitmapData];
					
					var highlightBitmapData:BitmapData = new BitmapData(Math.ceil(bitmapData.width / 4), Math.ceil(bitmapData.height / 4), true, 0x00000000);
					highlightBitmapData = new BitmapData(Math.ceil(bitmapData.width * 0.3), Math.ceil(bitmapData.height * 0.3), true, 0x00000000);
					highlightBitmapData.draw(
						bitmapData,
						new Matrix(0.25, 0, 0, 0.25, bitmapData.width * 0.025, bitmapData.height * 0.025)
					);
					highlightBitmapData.applyFilter(
						highlightBitmapData,
						highlightBitmapData.rect,
						new Point(),
						new GlowFilter(0xFFFFFF, 1, 2, 2, 4, 3)
					);
					highlightBitmapData.applyFilter(
						highlightBitmapData,
						highlightBitmapData.rect,
						new Point(),
						new ColorMatrixFilter([
							1, 1, 1, 0, 0,
							1, 1, 1, 0, 0,
							1, 1, 1, 0, 0,
							0, 0, 0, 1, 0
						])
					);
					
					if (_configData.cropWhitespace)
					{
						highlightBitmapData = cropWhitespate(highlightBitmapData);
					}
					
					hashHighlights[bitmapName.substr(0, bitmapName.length - 4) + "hl.png"] = highlightBitmapData;
					_listBitmaps.push(highlightBitmapData);
					_listTextureNames[_listBitmaps.indexOf(highlightBitmapData)] =  bitmapName.substr(0, bitmapName.length - 4) + "hl";
				}
			}
			
			for (bitmapName in hashHighlights)
			{
				_currentBitmaps[bitmapName] = hashHighlights[bitmapName];
			}
			
			if (!_configData.combineSpriteSheet)
			{
				var atlasWidth:int = 2;
				var atlasHeight:int = 2;
				while (atlasWidth < _listBitmaps[0].width)
				{
					atlasWidth *= 2;
				}
				
				while (atlasHeight < _listBitmaps[0].height)
				{
					atlasHeight *= 2;
				}
			}
			else
			{
				var totalSquare:int = _listBitmaps[0].width * _listBitmaps[0].height * _listBitmaps.length;
				var side:Number = Math.sqrt(totalSquare);
				
				var maxMidth:Number = side;
				
				var cols:int = int(maxMidth / _listBitmaps[0].width);
				var rows:int = int((_listBitmaps.length - 1) / cols) + 1;
				if (rows > 1)
				{
					atlasWidth = cols * _listBitmaps[0].width;
					atlasHeight = rows * _listBitmaps[0].height;
				}
				else
				{
					atlasWidth = _listBitmaps[0].width * _listBitmaps[0].length;
					atlasHeight = _listBitmaps[0].height;
				}
				
				var listKeyFrames:Array = [];
				for (i = 0; i < _listBitmaps.length; i++)
				{
					listKeyFrames.push(SpriteSheet.KEY_FRAME);
				}
				
				var spriteSheetData:SpriteSheetData = new SpriteSheetData(
					_listBitmaps[0].width,
					_listBitmaps[0].height,
					_listBitmaps.length,
					cols,
					listKeyFrames
				);
				
				var totalBitmap:BitmapData = new BitmapData(atlasWidth, atlasHeight, true, 0x00000000);
				
				for (i = 0; i < _listBitmaps.length; i++)
				{
					totalBitmap.copyPixels(
						_listBitmaps[i],
						_listBitmaps[i].rect,
						new Point(
							(i % cols) * _listBitmaps[i].width,
							int(i / cols) * _listBitmaps[i].height
						)
					);
				}
				
				_listBitmaps = [totalBitmap];
				
				var namePrefix:String = _listTextureNames[0];
				namePrefix = namePrefix.replace(/(.*?)_?\d+$/gm, "$1");
				_listTextureNames = [namePrefix];
				
				atlasWidth = 2;
				atlasHeight = 2;
				while (atlasWidth < _listBitmaps[0].width)
				{
					atlasWidth *= 2;
				}
				
				while (atlasHeight < _listBitmaps[0].height)
				{
					atlasHeight *= 2;
				}
			}
			
			var i:int = 0;
			var textureAtlas:TextureAtlasBitmapData;
			while (i < _listBitmaps.length)
			{
				if (textureAtlas == null)
				{
					textureAtlas = new TextureAtlasBitmapData(atlasWidth, atlasHeight);
				}
				
				if (textureAtlas.insert(_listBitmaps[i], _listTextureNames[i], _configData.textureGap, _configData.extrudeEdges) != null)
				{
					if (_hashCropRects != null && _hashCropRects[_listBitmaps[i]] != null)
					{
						var cropRect:Rectangle = _hashCropRects[_listBitmaps[i]];
						var textureData:TextureData = textureAtlas.textureAtlasData.getTextureData(_listTextureNames[i]);
						textureData.setBlankRectValues(
							cropRect.x, cropRect.y, cropRect.width, cropRect.height
						);
					}
					i++;
				}
				else
				{
					if (atlasHeight < atlasWidth)
					{
						atlasHeight *= 2;
						
						i = 0;
						textureAtlas.dispose();
						textureAtlas = null;
					}
					else if (atlasHeight < 2048)
					{
						atlasWidth *= 2;
						
						i = 0;
						textureAtlas.dispose();
						textureAtlas = null;
					}
					else
					{
						if (_taLog != null)
						{
							_taLog.appendText("Cannot fit images on 2048x2048 texture");
						}
						break;
					}
				}
			}
			
			if (_configData.includeBinAlpha)
			{
				var alphaData:ByteArray = new ByteArray();
				for (var l:int = 0; l < _listTextureNames.length; l++)
				{
					textureData = textureAtlas.textureAtlasData.getTextureData(_listTextureNames[l]);
					if (textureData == null)
					{
						continue;
					}
					
					alphaData.writeUTF(textureData.textureID);
					var numBytes:uint = int((textureData.croppedWidth + 8 - 1) / 8) * textureData.croppedHeight + 4;
					alphaData.writeShort(numBytes);
					alphaData.writeShort(int((textureData.croppedWidth + 8 - 1) / 8) * 8);
					alphaData.writeShort(textureData.croppedHeight);
					
					var alphaByte:uint = 0;
					for (i = textureData.top; i < textureData.top + textureData.croppedHeight; i++)
					{
						for (var j:int = textureData.left; j < textureData.left + textureData.croppedWidth; j += 8)
						{
							alphaByte = 0;
							for (var k:int = 0; k < 8; k++)
							{
								var pixel32:uint = (j + k) < textureData.left + textureData.width ? textureAtlas.getPixel32(j + k, i) : 0;
								pixel32 = pixel32 >> 24;
								if (pixel32 > 0)
								{
									pixel32 = 1;
								}
								pixel32 = pixel32 << (7 - k);
								alphaByte += pixel32;
							}
							alphaData.writeByte(alphaByte);
						}
					}
				}
			}
			
			if (_configData.combineSpriteSheet)
			{
				textureData = textureAtlas.textureAtlasData.getTextureData(_listTextureNames[0]);
				textureData.spriteSheetData = spriteSheetData;					
			}
			
			var fileStream:FileStream = new FileStream();
			var outputFile:File = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.png");
			fileStream.open(outputFile, FileMode.WRITE);
			
			var png:ByteArray = new PNGEncoder().encode(textureAtlas);
			fileStream.writeBytes(png, 0, png.length);
			fileStream.close();
			
			outputFile = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.tad");
			fileStream = new FileStream();
			fileStream.open(outputFile, FileMode.WRITE);
			fileStream.writeObject(textureAtlas.textureAtlasData.getRawData());
			fileStream.close();
			
			if (_configData.includeBinAlpha)
			{
				alphaData.compress("lzma");
				alphaData.position = 0;
				
				outputFile = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.na_");
				fileStream = new FileStream();
				fileStream.open(outputFile, FileMode.WRITE);
				fileStream.writeBytes(alphaData);
				fileStream.close();
			}
			
			if (_taLog != null)
			{
				_taLog.appendText("Created atlas for " + _currentFolder.name + "\n");
			}
			
			if (_configData.compressAtlas)
			{
				var executableName:String = "";
				if (Capabilities.os.indexOf("Windows") != -1)
				{
					executableName = "png2atf.exe";
				}
				else if (Capabilities.os.indexOf("Mac") != -1)
				{
					executableName = "png2atf";
				}
				else
				{
					if (_taLog != null)
					{
						_taLog.appendText("This host OS isn't supported!\n");
					}
					return;
				}
				
				var npInfo:NativeProcessStartupInfo = new NativeProcessStartupInfo();
				var file:File = new File(File.applicationDirectory.nativePath + "/assets/" + executableName);
				
				npInfo.executable = file;
				npInfo.workingDirectory = _currentFolder;
				var arguments:Vector.<String> = new Vector.<String>();
				arguments.push(
					"-i",
					_currentFolder.nativePath + "/" + _currentFolder.name + "_atlas.png",
					"-o",
					_currentFolder.nativePath + "/" + _currentFolder.name + ".atf",
					"-q",
					_configData.compressionLevel,
					"-s",
					"-n",
					"0," + _configData.mipLevels
				);
				npInfo.arguments = arguments;
				
				var nativeProcess:NativeProcess = new NativeProcess();
				nativeProcess.addEventListener(NativeProcessExitEvent.EXIT, onATFConverterExit);
				nativeProcess.start(npInfo);
			}
			else
			{
				onATFConverterExit(null);
			}
		}
		
		protected function onATFConverterExit(event:NativeProcessExitEvent):void
		{
			var file:File;
			var fsIn:FileStream;
			var ba:ByteArray;
			
			var extension:String = _configData.compressAtlas ? 'arf' : 'brf';
			var arfFile:File;
			
			if (_configData.updateAtlasFileEnabled)
			{
				try
				{
					arfFile = new File(_configData.updateAtlasFilePath);
				} 
				catch(error:Error) 
				{
					arfFile = null;
				}
			}
			
			if (arfFile == null)
			{
				arfFile = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "." + extension);
			}
			var fsOut:FileStream = new FileStream();
			fsOut.open(arfFile, FileMode.WRITE);
			
			if (_configData.compressAtlas)
			{
				file = new File(_currentFolder.nativePath + '/' + _currentFolder.name + ".atf");
				fsIn = new FileStream();
				fsIn.open(file, FileMode.READ);
				ba = new ByteArray();
				fsIn.readBytes(ba, 0, file.size);
				fsIn.close();
				fsOut.writeBytes(ba, 0, ba.length);
			}
			else
			{
				file = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.png");
				fsIn = new FileStream();
				fsIn.open(file, FileMode.READ);
				ba = new ByteArray();
				fsIn.readBytes(ba, 0, file.size);
				fsIn.close();
				
				fsOut.writeByte(('I').charCodeAt(0));
				fsOut.writeByte(('M').charCodeAt(0));
				fsOut.writeByte(('G').charCodeAt(0));
				
				var size:int = ba.length;
				var s1:int = (size >> 16) & 0xFF;
				var s2:int = (size >> 8) & 0xFF;
				var s3:int = size & 0xFF;
				
				fsOut.writeByte(s1);
				fsOut.writeByte(s2);
				fsOut.writeByte(s3);
				
				fsOut.writeBytes(ba, 0, ba.length);
			}
			
			file = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.tad");
			fsIn = new FileStream();
			fsIn.open(file, FileMode.READ);
			ba = new ByteArray();
			fsIn.readBytes(ba, 0, file.size);
			fsIn.close();
			
			fsOut.writeByte(('T').charCodeAt(0));
			fsOut.writeByte(('A').charCodeAt(0));
			fsOut.writeByte(('D').charCodeAt(0));
			
			size = ba.length;
			s1 = (size >> 16) & 0xFF;
			s2 = (size >> 8) & 0xFF;
			s3 = size & 0xFF;
			
			fsOut.writeByte(s1);
			fsOut.writeByte(s2);
			fsOut.writeByte(s3);
			
			fsOut.writeBytes(ba, 0, ba.length);
			
			if (_configData.includeBinAlpha)
			{
				file = new File(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.na_");
				fsIn = new FileStream();
				fsIn.open(file, FileMode.READ);
				ba = new ByteArray();
				fsIn.readBytes(ba, 0, file.size);
				fsIn.close();
				
				fsOut.writeByte(('N').charCodeAt(0));
				fsOut.writeByte(('A').charCodeAt(0));
				fsOut.writeByte(('_').charCodeAt(0));
				
				size = ba.length;
				s1 = (size >> 16) & 0xFF;
				s2 = (size >> 8) & 0xFF;
				s3 = size & 0xFF;
				
				fsOut.writeByte(s1);
				fsOut.writeByte(s2);
				fsOut.writeByte(s3);
				
				fsOut.writeBytes(ba, 0, ba.length);
			}
			
			if (_loadedAnimationPackage != null)
			{
				fsOut.writeBytes(_loadedAnimationPackage, 0, _loadedAnimationPackage.length);
			}
			
			fsOut.close();
			
			if (_configData.generateClass)
			{
				var asFile:File;
				if (_configData.updateClassFileEnabled)
				{
					try
					{
						asFile = new File(_configData.updateClassFilePath);
					} 
					catch(error:Error) 
					{
						asFile = null;
					}
				}
				
				if (asFile == null)
				{
					var prompt:atlas_compositor.components.TextPrompt = new TextPrompt();
					prompt.addEventListener(TextPromptEvent.OK, onClassNameSelected);
					prompt.addEventListener(TextPromptEvent.CANCEL, onClassNameCanceled);
					prompt.title = "Select name for description class";
					prompt.checkTextFunction = checkClassName;
					
					PopUpManager.addPopUp(prompt, _mainApp, true);
					PopUpManager.centerPopUp(prompt);
				}
				else
				{
					writeAsFile(asFile);
				}
			}
			
			_mainApp.enabled = true;
			
			if (_configData.removeTemp)
			{
				if (_taLog != null)
				{
					_taLog.appendText("Removing temp files...\n");
				}
				
				if (_configData.includeBinAlpha)
				{
					deleteFile(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.na_");
				}
				
				if (_configData.compressAtlas)
				{
					deleteFile(_currentFolder.nativePath + '/' + _currentFolder.name + ".atf");
				}
				
				deleteFile(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.tad");
				
				deleteFile(_currentFolder.nativePath + '/' + _currentFolder.name + "_atlas.png");
			}
			
			if (_taLog != null)
			{
				_taLog.appendText("Folder processed!\n\n");
			}
			cleanup();
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		private function checkClassName(name:String):Boolean
		{
			if (name == null)
			{
				return false;
			}
			
			var matches:Array = name.match(/^(?!\d+)\w+$/g);
			return matches != null && matches.length > 0;
		}
		
		private function onClassNameSelected(event:TextPromptEvent):void
		{
			PopUpManager.removePopUp(event.currentTarget as TextPrompt);
			
			var className:String = (event.currentTarget as TextPrompt).edtPromptValue.text;
			
			var file:File;
			
			var asFile:File = new File(_currentFolder.nativePath + '/' + className + ".as");
			writeAsFile(asFile);
		}
		
		private function writeAsFile(asFile:File):void
		{
			var classContent:String;
			var classBody:String;
			
			var fsIn:FileStream = new FileStream();
			fsIn.open(asFile, FileMode.READ);
			classContent = fsIn.readUTFBytes(fsIn.bytesAvailable);
			fsIn.close();
			
			var classParts:Array = classContent.split(TemplateClassCreation.AUTO_GENERATION_START);
			
			
			if (classParts.length < 2)
			{
				classBody = getNewClassContent(asFile);
			}
			else
			{
				var classEnd:String = classParts[1].split(TemplateClassCreation.AUTO_GENERATION_END)[1];
				
				classBody = classParts[0] + TemplateClassCreation.AUTO_GENERATION_START + '\n';
				
				_listTextureNames.sort(Array.CASEINSENSITIVE);
				for (var i:int = 0; i < _listTextureNames.length; i++)
				{
					classBody += TemplateClassCreation.PUBLIC_VAR_STRING.replace(/\$var_name/g, _listTextureNames[i]);
				}
				
				classBody += TemplateClassCreation.AUTO_GENERATION_END + classEnd;
			}
			
			var fsOut:FileStream = new FileStream();
			fsOut.open(asFile, FileMode.WRITE);
			
			fsOut.writeUTFBytes(classBody);
			
			fsOut.close();
			
			if (_taLog != null)
			{
				_taLog.appendText("Description class created\n");
			}
		}
		
		private function getNewClassContent(asFile:File):String
		{
			var className:String = asFile.name.split("." + asFile.extension)[0];
			var classBody:String = TemplateClassCreation.CLASS_BODY.replace(/\$class_name/, className);
			classBody = classBody.replace(/\$package_name/, _configData.updateClassFilePackage);
			
			var classContent:String = TemplateClassCreation.AUTO_GENERATION_START + '\n';
			
			_listTextureNames.sort(Array.CASEINSENSITIVE);
			for (var i:int = 0; i < _listTextureNames.length; i++)
			{
				classContent += TemplateClassCreation.PUBLIC_VAR_STRING.replace(/\$var_name/g, _listTextureNames[i]);
			}
			
			classContent += TemplateClassCreation.AUTO_GENERATION_END + '\n';
			
			classBody = classBody.replace(/\$class_content/, classContent);
			return classBody;
		}
		
		
		protected function onClassNameCanceled(event:Event):void
		{
			PopUpManager.removePopUp(event.currentTarget as TextPrompt);
		}
		
		
		private function cleanup():void
		{
			for each (var bitmapData:BitmapData in _currentBitmaps)
			{
				bitmapData.dispose();
			}
			
			for each (bitmapData in _hashOrigBitmaps)
			{
				bitmapData.dispose();
			}
		}
		
		private function deleteFile(path:String):void
		{
			var file:File;
			if (_taLog != null)
			{
				_taLog.appendText("Removing file: " + path + "\n");
			}
			try
			{
				file = new File(path);
			} 
			catch(error:Error) 
			{
				if (_taLog != null)
				{
					_taLog.appendText("Wrong path: " + path + "\n");
				}
				return;
			}
			
			if (file != null)
			{
				if (!file.exists)
				{
					if (_taLog != null)
					{
						_taLog.appendText("File: " + path + " not found\n");
					}
				}
				else
				{
					try
					{
						file.deleteFile();
					} 
					catch(error:Error) 
					{
						if (_taLog != null)
						{
							_taLog.appendText("File: " + path + " was not deleted\n");
						}
					}
				}
			}
		}
	}
}