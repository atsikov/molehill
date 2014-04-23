package molehill.easy.ui3d
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.PixelSnapping;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	public class Sprite3D9Scale extends Sprite3DContainer
	{
		private var _bitmapTL:Sprite3D;
		private var _bitmapT:Sprite3D;
		private var _bitmapTR:Sprite3D;
		private var _bitmapL:Sprite3D;
		private var _bitmapC:Sprite3D;
		private var _bitmapR:Sprite3D;
		private var _bitmapBL:Sprite3D;
		private var _bitmapB:Sprite3D;
		private var _bitmapBR:Sprite3D;
		
		private var _scaleRect:Rectangle;
		
		private var _totalWidth:Number = 0;
		private var _totalHeight:Number = 0;
		
		private var _fillMethod:String;
		public function Sprite3D9Scale(bgTextureID:String, scaleRect:Rectangle, fillMethod:String = "stretch")
		{
			super();
			
			_fillMethod = fillMethod;
			
			var tm:TextureManager = TextureManager.getInstance();
			var textureRegion:Rectangle = tm.getTextureRegion(bgTextureID);
			var textureData:TextureData = tm.getTextureDataByID(bgTextureID);
			var textureScaleRect:Rectangle = new Rectangle();
			textureScaleRect.left = textureRegion.left + scaleRect.left / textureData.width * textureRegion.width
			textureScaleRect.top = textureRegion.top + scaleRect.top / textureData.height * textureRegion.height
			textureScaleRect.right = textureRegion.left + scaleRect.right / textureData.width * textureRegion.width
			textureScaleRect.bottom = textureRegion.top + scaleRect.bottom / textureData.height * textureRegion.height
			
			_scaleRect = scaleRect;
			
			var spriteClass:Class;
			switch (fillMethod)
			{
				case Sprite3D9ScaleFillMethod.STRETCH:
					spriteClass = Sprite3D;
					break;
				
				case Sprite3D9ScaleFillMethod.TILE:
					spriteClass = TiledSprite3D;
					break;
			}
			
			// -------------------------------------
			_bitmapTL = new Sprite3D();
			_bitmapTL.setTexture(bgTextureID);
			_bitmapTL.width = scaleRect.x;
			_bitmapTL.height = scaleRect.y;
			_bitmapTL.textureRegion = new Rectangle(
				textureRegion.x,
				textureRegion.y,
				textureScaleRect.x - textureRegion.x, 
				textureScaleRect.y - textureRegion.y
			);
			
			_bitmapT = new spriteClass();
			_bitmapT.setTexture(bgTextureID);
			_bitmapT.width = scaleRect.width;
			_bitmapT.height = scaleRect.y;
			_bitmapT.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureRegion.y,
				textureScaleRect.width, 
				textureScaleRect.y - textureRegion.y
			);
			
			if (_bitmapT is TiledSprite3D)
			{
				(_bitmapT as TiledSprite3D).setTileSize(
					scaleRect.width,
					scaleRect.top
				);
			}
			
			_bitmapTR = new Sprite3D();
			_bitmapTR.setTexture(bgTextureID);
			_bitmapTR.width = textureData.width - scaleRect.x - scaleRect.width;
			_bitmapTR.height = scaleRect.y;
			_bitmapTR.textureRegion = new Rectangle( 
				textureScaleRect.right,
				textureRegion.y,
				textureRegion.right - textureScaleRect.right, 
				textureScaleRect.y - textureRegion.y
			);
			
			// -------------------------------------
			_bitmapL = new spriteClass();
			_bitmapL.setTexture(bgTextureID);
			_bitmapL.width = scaleRect.x;
			_bitmapL.height = scaleRect.height;
			_bitmapL.textureRegion = new Rectangle(
				textureRegion.x,
				textureScaleRect.y,
				textureScaleRect.x - textureRegion.x, 
				textureScaleRect.height
			);
			
			if (_bitmapL is TiledSprite3D)
			{
				(_bitmapL as TiledSprite3D).setTileSize(
					scaleRect.left,
					scaleRect.height
				);
			}
			
			_bitmapC = new spriteClass();
			_bitmapC.setTexture(bgTextureID);
			_bitmapC.width = scaleRect.width;
			_bitmapC.height = scaleRect.height;
			_bitmapC.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.y,
				textureScaleRect.width, 
				textureScaleRect.height
			);
			
			if (_bitmapC is TiledSprite3D)
			{
				(_bitmapC as TiledSprite3D).setTileSize(
					scaleRect.width,
					scaleRect.height
				);
			}
			
			_bitmapR = new spriteClass();
			_bitmapR.setTexture(bgTextureID);
			_bitmapR.width = textureData.width - scaleRect.x - scaleRect.width;
			_bitmapR.height = scaleRect.height;
			_bitmapR.textureRegion = new Rectangle(
				textureScaleRect.right,
				textureScaleRect.y,
				textureRegion.right - textureScaleRect.right, 
				textureScaleRect.height
			);
			
			if (_bitmapR is TiledSprite3D)
			{
				(_bitmapR as TiledSprite3D).setTileSize(
					textureData.width - scaleRect.right,
					scaleRect.height
				);
			}
			
			// -------------------------------------
			_bitmapBL = new Sprite3D();
			_bitmapBL.setTexture(bgTextureID);
			_bitmapBL.width = scaleRect.x;
			_bitmapBL.height = textureData.height - scaleRect.height - scaleRect.y;
			_bitmapBL.textureRegion = new Rectangle(
				textureRegion.x,
				textureScaleRect.bottom,
				textureScaleRect.x - textureRegion.x, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
			_bitmapB = new spriteClass();
			_bitmapB.setTexture(bgTextureID);
			_bitmapB.width = scaleRect.width;
			_bitmapB.height = textureData.height - scaleRect.height - scaleRect.y;
			_bitmapB.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.bottom,
				textureScaleRect.width, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
			if (_bitmapB is TiledSprite3D)
			{
				(_bitmapB as TiledSprite3D).setTileSize(
					scaleRect.width,
					textureData.height - scaleRect.bottom
				);
			}
			
			_bitmapBR = new Sprite3D();
			_bitmapBR.setTexture(bgTextureID);
			_bitmapBR.width = textureData.width - scaleRect.x - scaleRect.width;
			_bitmapBR.height = textureData.height - scaleRect.height - scaleRect.y;
			_bitmapBR.textureRegion = new Rectangle(
				textureScaleRect.right,
				textureScaleRect.bottom,
				textureRegion.right - textureScaleRect.right, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
			addChild(_bitmapTL);
			addChild(_bitmapT);
			addChild(_bitmapTR);
			addChild(_bitmapL);
			addChild(_bitmapC);
			addChild(_bitmapR);
			addChild(_bitmapBL);
			addChild(_bitmapB);
			addChild(_bitmapBR);
			
			_totalWidth = textureData.width;
			_totalHeight = textureData.height;
			
			resize();
		}
		
		public function resize():void
		{
			_bitmapT.width = _bitmapC.width = _bitmapB.width = _totalWidth - _bitmapTL.width - _bitmapTR.width;
			_bitmapL.height = _bitmapC.height = _bitmapR.height = _totalHeight - _bitmapTL.height - _bitmapBL.height;
			
			_bitmapT.x = _bitmapC.x = _bitmapB.x = _bitmapTL.width;
			_bitmapTR.x = _bitmapR.x = _bitmapBR.x = _bitmapTL.width + _bitmapT.width;
			_bitmapL.y = _bitmapC.y = _bitmapR.y = _bitmapTL.height;
			_bitmapBL.y = _bitmapB.y = _bitmapBR.y = _bitmapTL.height + _bitmapL.height;
		}
		
		override public function get width():Number
		{
			return _totalWidth;
		}
		
		override public function set width(value:Number):void
		{
			_totalWidth = value;
		}
		
		override public function get height():Number
		{
			return _totalHeight;
		}
		
		override public function set height(value:Number):void
		{
			_totalHeight = value;
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			_totalWidth = w;
			_totalHeight = h;
			
			resize();
		}
	}
}