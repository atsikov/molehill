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
		
		override public function setTexture(textureId:String):void
		{
			_referenceSprite.setTexture(textureId);
			
			setSize(_tiledWidth, _tiledHeight);
		}
		
		private var _cacheSprites:CachingFactory;
		private var _tiledWidth:Number = 0;
		private var _tiledHeight:Number = 0;
		
		override public function set width(value:Number):void
		{
			setSize(value, _tiledHeight);
		}
		
		override public function set height(value:Number):void
		{
			setSize(_tiledWidth, value);
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
			
			for (var i:int = 0; i < w; i += _referenceSprite.width)
			{
				for (var j:int = 0; j < h; j += _referenceSprite.height)
				{
					sprite = _cacheSprites.newInstance();
					sprite.moveTo(i, j);
					sprite.setTexture(_referenceSprite.textureID);
					
					var spriteWidth:int = _referenceSprite.width;
					var spriteHeight:int = _referenceSprite.height;
					
					if (i + spriteWidth > w)
					{
						spriteWidth = w - i;
					}
					
					if (j + spriteHeight > h)
					{
						spriteHeight = h - j;
					}
					
					if (spriteWidth != _referenceSprite.width ||
						spriteHeight != _referenceSprite.height)
					{
						sprite.setSize(spriteWidth, spriteHeight);
						
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