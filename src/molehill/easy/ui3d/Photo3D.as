package molehill.easy.ui3d
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Graphics;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	import molehill.core.render.Sprite3D;
	import molehill.core.render.Sprite3DContainer;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.base.ColorFillShader;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	public class Photo3D extends Sprite3DContainer
	{
		static private var _emptyPhotoTextureID:String;
		static private function set emptyPhotoTextureId(value:String):void
		{
			_emptyPhotoTextureID = value;
		}
		
		static private function get emptyPhotoTextureId():String
		{
			return _emptyPhotoTextureID;
		}
		
		private static var _waitAnimationClass:Class;
		
		private var _photoWidth:int = 0;
		private var _photoHeight:int = 0;
		
		private var _photo:Sprite3D;
		private var _photoTextureId:String;
		private var _photoLoader:Loader;
		
		private var _border:Shape;
		
		private var _pictureWidth:int = 0;
		private var _pictureHeight:int = 0;
		
		private var _noSpace:Boolean;
		
		public function Photo3D(
			url:String = null,
			photoWidth:int = 50,
			photoHeight:int = 0,
			pictureWidth:int = 0,
			pictureHeight:int = 0,
			noSpace:Boolean = false
		)
		{
			super();
			_photoWidth = photoWidth;
			_photoHeight = photoHeight;
			_pictureWidth = pictureWidth;
			_pictureHeight = pictureHeight;
			_noSpace = noSpace;
			
			loadPhoto(url);
		}
		
		private var _photoURL:String = null;
		public function get photoURL():String
		{
			return _photoURL;
		}
		
		public function loadPhoto(url:String = null):void
		{
			if (_photoURL == url)
				return;
			
			_photoURL = url;
			_photoTextureId = "photo_" + _photoURL.replace(/[\/\:\.\?\&]/g, '_');
			
			if (TextureManager.getInstance().isTextureCreated(_photoTextureId))
			{
				if (_photo == null)
				{
					_photo = Sprite3D.createFromTexture(_photoTextureId);
					addChild(_photo);
				}
				_photo.textureID = _photoTextureId;
				
				sizePhoto();
				return;
			}
			
			if (url == null || url == '')
			{
				useNoPhotoStub();
				return;
			}
			
			if (_photoLoader == null)
			{
				_photoLoader = new Loader();
			}
			
			_photoLoader.scaleX = 1.0;
			_photoLoader.scaleY = 1.0;
			_photoLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, onPhotoLoadSuccess);
			_photoLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR, onPhotoLoadError);
			_photoLoader.contentLoaderInfo.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onPhotoLoadError);
			
			try
			{
				_photoLoader.load(
					new URLRequest(url),
					new LoaderContext(
						true
					)
				);
			}
			catch (e:Error)
			{
				useNoPhotoStub();
			}
		}
		
		private function useNoPhotoStub():void
		{
			if (_photo == null)
			{
				if (_emptyPhotoTextureID != null)
				{
					_photo = Sprite3D.createFromTexture(_emptyPhotoTextureID);
				}
				else
				{
					_photo = new Sprite3D();
					_photo.shader = Shader3DFactory.getInstance().getShaderInstance(ColorFillShader);
				}
				addChild(_photo);
			}
			sizePhoto();
		}
		
		public function sizePhoto():void
		{
			var textureAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(_photoTextureId);
			if (textureAtlasData == null)
			{
				return;
			}
			
			var textureRegion:Rectangle = textureAtlasData.getTextureRegion(_photoTextureId);
			var unscaledPhotoWidth:Number  = textureAtlasData.getTextureData(_photoTextureId).width;
			var unscaledPhotoHeight:Number = textureAtlasData.getTextureData(_photoTextureId).height;
			
			var newPhotoWidth:Number  = 0;
			var newPhotoHeight:Number = 0;
			
			if ( (_photoWidth > 0) && (_photoHeight > 0) )
			{
				newPhotoWidth  = _photoWidth;
				newPhotoHeight = _photoHeight;
			}
			else
			{
				if ( (_photoWidth == 0) && (_photoHeight == 0) )
				{
					newPhotoWidth  = unscaledPhotoWidth;
					newPhotoHeight = unscaledPhotoHeight;
				}
				else
				{
					if (_photoWidth > 0)
					{
						newPhotoWidth  = _photoWidth;
						newPhotoHeight = unscaledPhotoHeight * (_photoWidth / unscaledPhotoWidth);
					}
					
					if (_photoHeight > 0)
					{
						newPhotoHeight = _photoHeight;
						newPhotoWidth = unscaledPhotoWidth * (_photoHeight / unscaledPhotoHeight);
					}
				}
			}
			
			var scaleCoeffW:Number = newPhotoWidth / unscaledPhotoWidth;
			var scaleCoeffH:Number = newPhotoHeight / unscaledPhotoHeight;
			var scaleCoeff:Number = _noSpace ? Math.max(scaleCoeffW, scaleCoeffH) : Math.min(scaleCoeffW, scaleCoeffH);
			
			var photoWidth:int = unscaledPhotoWidth * scaleCoeff;
			var photoHeight:int = unscaledPhotoHeight * scaleCoeff;
			
			if (_pictureWidth != 0 && _pictureHeight != 0)
			{
				textureRegion = textureRegion.clone();
				
				var scrollRectX:Number = 0;
				var scrollRectY:Number = 0;
				if (photoWidth > _pictureWidth)
				{
					scrollRectX = ((photoWidth - _pictureWidth) / scaleCoeff) / 2;
				}
				if (photoHeight > _pictureHeight)
				{
					scrollRectY = ((photoHeight - _pictureHeight) / scaleCoeff) / 2;
				}
				
				_photo.x = int((_pictureWidth - Math.min(newPhotoWidth, _pictureWidth)) / 2);
				_photo.y = int((_pictureHeight - Math.min(newPhotoHeight, _pictureHeight)) / 2);
				_photo.setSize(_pictureWidth, _pictureHeight);
				
				textureRegion.x += scrollRectX / textureAtlasData.width;
				textureRegion.y += scrollRectY / textureAtlasData.height;
				textureRegion.width -= 2 * scrollRectX / textureAtlasData.width;
				textureRegion.height -= 2 * scrollRectY / textureAtlasData.height;
				_photo.textureRegion = textureRegion;
			}
			else
			{
				_photo.width = photoWidth;
				_photo.height = photoHeight;
			}
		}

		private function onPhotoLoadSuccess(e:Event):void
		{	
			_photoLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPhotoLoadSuccess);
			_photoLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPhotoLoadError);
			_photoLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPhotoLoadError);

			var originalBitmapData:BitmapData;
			try
			{
				originalBitmapData = (_photoLoader.contentLoaderInfo.content as Bitmap).bitmapData;
			}
			catch (e:Error)
			{
				originalBitmapData = null;
			}
			
			if (originalBitmapData == null)
			{
				useNoPhotoStub();
				return;
			}
	
			if (_pictureWidth == 0)
			{
				_pictureWidth = _photoLoader.width;
			}
			if (_pictureHeight == 0)
			{
				_pictureHeight = _photoLoader.height;
			}
				
			if (_photoWidth == 0)
			{
				_photoWidth = _pictureWidth;
			}
			if (_photoHeight == 0)
			{
				_photoHeight = _pictureHeight;
			}
				
			var pointX:int = 0;
			var pointY:int = 0;
			if (_photoLoader.width < _photoWidth)
			{
				pointX = (_photoWidth - _photoLoader.width) / 2;
			}
				
			if (_photoLoader.height < _photoHeight)
			{
				pointY = (_photoHeight - _photoLoader.height) / 2;
			}
			
			_photoLoader.x = pointX;
			_photoLoader.y = pointY;
			
			TextureManager.getInstance().createTextureFromBitmapData(originalBitmapData, _photoTextureId);

			if (_photo == null)
			{
				_photo = Sprite3D.createFromTexture(_photoTextureId);
				addChild(_photo);
			}
			_photo.textureID = _photoTextureId;
			
			sizePhoto();	
				
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		private function onPhotoLoadError(e:Event):void
		{
			_photoLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onPhotoLoadSuccess);
			_photoLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR, onPhotoLoadError);
			_photoLoader.contentLoaderInfo.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, onPhotoLoadError);
					
			_photoLoader = null;
			
			useNoPhotoStub();
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
	}
}