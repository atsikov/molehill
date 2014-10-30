package molehill.easy.ui3d
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Shape;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	
	import resources.Resource;
	import resources.ResourceFactory;
	import resources.ResourceTypes;
	import resources.events.ResourceEvent;
	import resources.species.BitmapResource;
	
	public class Photo3D extends Sprite3DContainer
	{
		static private var _emptyPhotoTextureID:String;
		static public function set emptyPhotoTextureId(value:String):void
		{
			_emptyPhotoTextureID = value;
		}
		
		static public function get emptyPhotoTextureId():String
		{
			return _emptyPhotoTextureID;
		}
		
		static private var _emptyPhotoFillColor:uint;
		static public function set emptyPhotoFillColor(value:uint):void
		{
			_emptyPhotoFillColor = value;
		}
		
		static public function get emptyPhotoFillColor():uint
		{
			return _emptyPhotoFillColor;
		}
		
		private static var _waitAnimationClass:Class;
		
		private var _photoWidth:int = 0;
		private var _photoHeight:int = 0;
		
		private var _photo:Sprite3D;
		private var _photoTextureId:String;
		private var _photoLoader:BitmapResource;
		
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
			
			uiHasDynamicTexture = true;
			
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
			_photoTextureId = _photoURL != null ? "photo_" + _photoURL.replace(/[\/\:\.\?\&]/g, '_') : null;
			
			if (_photoTextureId != null && TextureManager.getInstance().isTextureCreated(_photoTextureId))
			{
				if (_photo == null)
				{
					_photo = Sprite3D.createFromTexture(_photoTextureId);
					addChild(_photo);
				}
				_photo.darkenColor = 0xFFFFFF
				_photo.setTexture(_photoTextureId);
				
				_photo.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, true);
				sizePhoto();
				return;
			}
			
			if (url == null || url == '')
			{
				useNoPhotoStub();
				return;
			}
			
			if (_photoLoader != null)
			{
				_photoLoader.removeEventListener(ResourceEvent.READY, onPhotoLoadSuccess);
				_photoLoader.removeEventListener(ResourceEvent.INACCESSIBLE, onPhotoLoadError);
			}
			
			_photoLoader = ResourceFactory.getInstance().getResource(_photoURL, 0, false, ResourceTypes.BITMAP) as BitmapResource;
			
			_photoLoader.addEventListener(ResourceEvent.READY, onPhotoLoadSuccess);
			_photoLoader.addEventListener(ResourceEvent.INACCESSIBLE, onPhotoLoadError);
			
			_photoLoader.load();
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
					_photo.darkenColor = _emptyPhotoFillColor;
					_photo.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, true, Shader3D.TEXTURE_DONT_USE_TEXTURE);
				}
				addChild(_photo);
			}
			else
			{
				if (_emptyPhotoTextureID != null)
				{
					_photo.darkenColor = 0xFFFFFF;
					_photo.setTexture(_emptyPhotoTextureID);
				}
				else
				{
					_photo.setTexture(null);
					_photo.darkenColor = _emptyPhotoFillColor;
					_photo.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, true, Shader3D.TEXTURE_DONT_USE_TEXTURE);
				}
			}
			sizePhoto();
		}
		
		public function sizePhoto():void
		{
			var textureAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(_photoTextureId);
			if (textureAtlasData == null)
			{
				if (_pictureWidth != 0 && _pictureHeight != 0)
				{
					_photo.setSize(_pictureWidth, _pictureHeight);
				}
				
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

		private function onPhotoLoadSuccess(event:Event):void
		{
			if ((event.currentTarget as Resource).url != _photoURL)
			{
				return;
			}
			
			_photoLoader.removeEventListener(ResourceEvent.READY, onPhotoLoadSuccess);
			_photoLoader.removeEventListener(ResourceEvent.INACCESSIBLE, onPhotoLoadError);

			var originalBitmapData:BitmapData;
			try
			{
				originalBitmapData = (_photoLoader.getContentInstance() as Bitmap).bitmapData;
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
				_pictureWidth = originalBitmapData.width;
			}
			if (_pictureHeight == 0)
			{
				_pictureHeight = originalBitmapData.height;
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
			if (originalBitmapData.width < _photoWidth)
			{
				pointX = (_photoWidth - originalBitmapData.width) / 2;
			}
				
			if (originalBitmapData.height < _photoHeight)
			{
				pointY = (_photoHeight - originalBitmapData.height) / 2;
			}
			
			if (!TextureManager.getInstance().isTextureCreated(_photoTextureId))
			{
				// event may be triggered in more than one photo
				TextureManager.getInstance().createTextureFromBitmapData(originalBitmapData, _photoTextureId);
			}

			if (_photo == null)
			{
				_photo = Sprite3D.createFromTexture(_photoTextureId);
				addChild(_photo);
			}
			
			_photo.shader = Shader3DFactory.getInstance().getShaderInstance(Shader3D, true);
			_photo.darkenColor = 0xFFFFFF
			_photo.setTexture(_photoTextureId);
			
			if (originalBitmapData.width < _photoWidth)
			{
				pointX = (_photoWidth - originalBitmapData.width) / 2;
			}
			
			if (originalBitmapData.height < _photoHeight)
			{
				pointY = (_photoHeight - originalBitmapData.height) / 2;
			}
			
			_photo.moveTo(pointX, pointY);
			
			sizePhoto();	
				
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		private function onPhotoLoadError(event:Event):void
		{
			if ((event.currentTarget as LoaderInfo).url != _photoURL)
			{
				return;
			}
			
			_photoLoader.removeEventListener(ResourceEvent.READY, onPhotoLoadSuccess);
			_photoLoader.removeEventListener(ResourceEvent.INACCESSIBLE, onPhotoLoadError);
					
			_photoLoader = null;
			
			useNoPhotoStub();
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
	}
}