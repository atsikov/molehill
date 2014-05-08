package molehill.easy.ui3d
{
	import flash.events.Event;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.texture.TextureManager;
	
	import resources.Resource;
	import resources.ResourceFactory;
	import resources.ResourceTypes;
	import resources.events.ResourceEvent;
	
	[Event(name="resize", type="flash.events.Event")]
	[Event(name="ready", type="resources.events.ResourceEvent")]
	
	public class ResourceView extends Sprite3D
	{
		private var _res:Resource;
		private var _type:int;
		
		public function ResourceView(type:int = ResourceTypes.UNKNOWN)
		{
			_type = type;
			super();
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
				return;
			
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
				setTexture(null);
			}
			
		}
		
		private function update():void
		{
			if (TextureManager.getInstance().isTextureCreated(_urlToTextureID))
			{
				setTexture(_urlToTextureID);
				
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
		
		private function onResourceReady(event:Event):void
		{
			TextureManager.createTexture(
				_res.getContentInstance(), _urlToTextureID
			);
			
			setTexture(_urlToTextureID);
			
			dispatchEvent(
				new ResourceEvent(ResourceEvent.READY)
			);
		}
	}
}