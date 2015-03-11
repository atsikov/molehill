package molehill.easy.ui3d
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.geom.Rectangle;
	
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
		
		private var _noSpace:Boolean;
		
		public function Photo3D(
			url:String = null,
			photoWidth:int = 0,
			photoHeight:int = 0,
			noSpace:Boolean = false
		)
		{
			super();
			_photoWidth = photoWidth;
			_photoHeight = photoHeight;
			_noSpace = noSpace;
			
			uiHasDynamicTexture = true;
			
			loadPhoto(url);
		}
		
		private var _photoLoadingPriority:int = -100;
		public function get photoLoadingPriority():int
		{
			return _photoLoadingPriority;
		}
		
		public function set photoLoadingPriority(value:int):void
		{
			_photoLoadingPriority = value;
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
				
				_photo.shader = Shader3DFactory.getInstance().getShaderInstance(null, true);
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
			
			_photoLoader = ResourceFactory.getInstance().getResource(_photoURL, _photoLoadingPriority, false, ResourceTypes.BITMAP) as BitmapResource;
			
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
					_photo.shader = Shader3DFactory.getInstance().getShaderInstance(null, true, Shader3D.TEXTURE_DONT_USE_TEXTURE);
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
					_photo.shader = Shader3DFactory.getInstance().getShaderInstance(null, true, Shader3D.TEXTURE_DONT_USE_TEXTURE);
				}
			}
			sizePhoto();
		}
		
		public function sizePhoto():void
		{
			var textureAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(_photoTextureId);
			if (textureAtlasData == null)
			{
				if (_photoWidth != 0 && _photoHeight != 0)
				{
					_photo.setSize(_photoWidth, _photoHeight);
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
			
			textureRegion = textureRegion.clone();
			
			var scrollRectX:Number = 0;
			var scrollRectY:Number = 0;
			if (photoWidth > _photoWidth)
			{
				scrollRectX = ((photoWidth - _photoWidth) / scaleCoeff) / 2;
			}
			if (photoHeight > _photoHeight)
			{
				scrollRectY = ((photoHeight - _photoHeight) / scaleCoeff) / 2;
			}
			
			photoWidth = Math.min(photoWidth, _photoWidth);
			photoHeight = Math.min(photoHeight, _photoHeight);
			
			_photo.x = int((_photoWidth - photoWidth) / 2);
			_photo.y = int((_photoHeight - photoHeight) / 2);
			_photo.setSize(photoWidth, photoHeight);
			
			textureRegion.x += scrollRectX / textureAtlasData.width;
			textureRegion.y += scrollRectY / textureAtlasData.height;
			textureRegion.width -= 2 * scrollRectX / textureAtlasData.width;
			textureRegion.height -= 2 * scrollRectY / textureAtlasData.height;
			_photo.textureRegion = textureRegion;
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
			
			_photo.shader = Shader3DFactory.getInstance().getShaderInstance(null, true);
			_photo.darkenColor = 0xFFFFFF
			_photo.setTexture(_photoTextureId);
			
			sizePhoto();	
				
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		private function onPhotoLoadError(event:Event):void
		{
			if ((event.currentTarget as Resource).url != _photoURL)
			{
				return;
			}
			
			_photoLoader.removeEventListener(ResourceEvent.READY, onPhotoLoadSuccess);
			_photoLoader.removeEventListener(ResourceEvent.INACCESSIBLE, onPhotoLoadError);
			
			useNoPhotoStub();
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
	}
}