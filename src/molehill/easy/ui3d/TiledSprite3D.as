package molehill.easy.ui3d
{
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	import utils.CachingFactory;
	
	public class TiledSprite3D extends Sprite3DContainer
	{
		private var _referenceSprite:Sprite3D;
		public function TiledSprite3D()
		{
			_referenceSprite = new Sprite3D();
			
			_cacheSprites = new CachingFactory(Sprite3D);
		}
		
		override public function setTexture(textureID:String):void
		{
			_referenceSprite.setTexture(textureID);
			
			setSize(_tiledWidth, _tiledHeight);
		}
		
		override public function set textureRegion(value:Rectangle):void
		{
			_referenceSprite.textureRegion = value;
			
			setSize(_tiledWidth, _tiledHeight);
		}
		
		private var _cacheSprites:CachingFactory;
		private var _tiledWidth:Number = 0;
		private var _tiledHeight:Number = 0;
		
		override public function get width():Number
		{
			return _tiledWidth;
		}
		
		override public function set width(value:Number):void
		{
			setSize(value, _tiledHeight);
		}
		
		override public function get height():Number
		{
			return _tiledHeight;
		}
		
		override public function set height(value:Number):void
		{
			setSize(_tiledWidth, value);
		}
		
		public function setTileSize(w:Number, h:Number):void
		{
			_referenceSprite.setSize(w, h);
			setSize(_tiledWidth, _tiledHeight);
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			var sprite:Sprite3D;
			while (numChildren > 0)
			{
				sprite = removeChildAt(0);
				sprite.resetSprite();
				_cacheSprites.storeInstance(sprite);
			}
			
			_tiledWidth = w;
			_tiledHeight = h;
			
			if (_referenceSprite.textureID == null)
			{
				return;
			}
			
			if (_referenceSprite.width == 0 || _referenceSprite.height == 0)
			{
				return;
			}
			
			for (var i:Number = 0; i < w; i += _referenceSprite.width)
			{
				for (var j:Number = 0; j < h; j += _referenceSprite.height)
				{
					sprite = _cacheSprites.newInstance();
					sprite.moveTo(i, j);
					sprite.setTexture(_referenceSprite.textureID);
					sprite.textureRegion = _referenceSprite.textureRegion;
					
					var spriteWidth:Number = _referenceSprite.width;
					var spriteHeight:Number = _referenceSprite.height;
					
					if (i + spriteWidth > w)
					{
						spriteWidth = w - i;
					}
					
					if (j + spriteHeight > h)
					{
						spriteHeight = h - j;
					}
					
					sprite.setSize(spriteWidth, spriteHeight);
					
					if (spriteWidth != _referenceSprite.width ||
						spriteHeight != _referenceSprite.height)
					{
						var textureRegion:Rectangle = _referenceSprite.textureRegion.clone();
						textureRegion.width *= spriteWidth / _referenceSprite.width;
						textureRegion.height *= spriteHeight / _referenceSprite.height;
						sprite.textureRegion = textureRegion;
					}
					
					addChild(sprite);
				}
			}
		}
	}
}