package molehill.easy.ui3d
{
	import flash.events.Event;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	
	import resources.Resource;
	import resources.ResourceFactory;
	import resources.ResourceTypes;
	import resources.events.ResourceEvent;
	
	[Event(name="resize", type="flash.events.Event")]
	[Event(name="ready", type="resources.events.ResourceEvent")]
	
	public class ResourceView3D extends Sprite3DContainer
	{
		private var _res:Resource;
		private var _content:Sprite3D;
		private var _type:int;
		
		public function ResourceView3D(type:int = ResourceTypes.UNKNOWN)
		{
			_type = type;
			super();
			
			uiHasDynamicTexture = true;
		}
		
		public function set type(value:int):void
		{
			_type = value;
		}
		
		private function reset():void
		{
			if (_res != null)
			{
				_res.removeOneTimeReadyListeners(onResourceReady);
				_res.dispose();
				_res = null;
			}
		}
		
		private var _resURL:String = null;
		public function get resURL():String
		{
			return _resURL;
		}
		private var _urlToTextureID:String = null;
		public function set resURL(value:String):void
		{
			if (_resURL == value)
			{
				dispatchEvent(
					new Event(ResourceEvent.READY)
				);
				return;
			}
			
			reset();
			
			_resURL = value;
			if (_resURL != null)
			{
				_urlToTextureID = _resURL.replace(/[\:\/\.\\\-\?]/g, '_');
			}
			else
			{
				_urlToTextureID = null;
			}
			
			if ((_resURL != null) && (_resURL != ''))
			{
				update();
			}
			else
			{
				if (_content != null && contains(_content))
				{
					removeChild(_content);
				}
			}
			
		}
		
		private function update():void
		{
			if (TextureManager.getInstance().isTextureCreated(_urlToTextureID))
			{
				if (_content == null)
				{
					_content = new Sprite3D();
				}
				if (!contains(_content))
				{
					addChildAt(_content, 0);
				}
				_content.setTexture(_urlToTextureID);
				
				dispatchEvent(
					new Event(ResourceEvent.READY)
				);
			}
			else
			{
				if (_type == ResourceTypes.UNKNOWN)
				{
					_res = ResourceFactory.getInstance().getResource(_resURL);
				}
				else
				{
					_res = ResourceFactory.getInstance().getResource(_resURL, 0, false, _type);
				}
				_res.addOneTimeReadyListeners(onResourceReady);
				_res.load();
			}
		}
		
		override public function setTexture(value:String):void
		{
			if (!TextureManager.getInstance().isTextureCreated(value))
			{
				return;
			}
			
			reset();
			_resURL = null;
			_urlToTextureID = value;
			update();
		}
		
		private function onResourceReady(event:Event):void
		{
			if (!TextureManager.getInstance().isTextureCreated(_urlToTextureID))
			{
				TextureManager.createTexture(
					_res.getContentInstance(), _urlToTextureID
				);
			}
			
			update();
			
			dispatchEvent(
				new ResourceEvent(ResourceEvent.READY)
			);
		}
		
		override public function set width(value:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.width = value;
		}
		
		override public function set height(value:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.height = value;
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.setSize(w, h);
		}
		
		override public function setScale(scaleX:Number, scaleY:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.setScale(scaleX, scaleY);
		}
		
		override public function set scaleX(value:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.scaleX = value;
		}
		
		override public function set scaleY(value:Number):void
		{
			if (_content == null)
			{
				return;
			}
			
			_content.scaleY = value;
		}
	}
}