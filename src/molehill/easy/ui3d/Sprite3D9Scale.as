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
		public function Sprite3D9Scale(bgTextureID:String, scaleRect:Rectangle)
		{
			super();
			
			var tm:TextureManager = TextureManager.getInstance();
			var textureRegion:Rectangle = tm.getTextureRegion(bgTextureID);
			var textureData:TextureData = tm.getTextureDataByID(bgTextureID);
			var textureScaleRect:Rectangle = new Rectangle();
			textureScaleRect.left = textureRegion.left + scaleRect.left / textureData.width * textureRegion.width
			textureScaleRect.top = textureRegion.top + scaleRect.top / textureData.height * textureRegion.height
			textureScaleRect.right = textureRegion.left + scaleRect.right / textureData.width * textureRegion.width
			textureScaleRect.bottom = textureRegion.top + scaleRect.bottom / textureData.height * textureRegion.height
			
			_scaleRect = scaleRect;
			
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
			
			_bitmapT = new Sprite3D();
			_bitmapT.setTexture(bgTextureID);
			_bitmapT.width = scaleRect.width;
			_bitmapT.height = scaleRect.y;
			_bitmapT.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureRegion.y,
				textureScaleRect.width, 
				textureScaleRect.y - textureRegion.y
			);
			
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
			_bitmapL = new Sprite3D();
			_bitmapL.setTexture(bgTextureID);
			_bitmapL.width = scaleRect.x;
			_bitmapL.height = scaleRect.height;
			_bitmapL.textureRegion = new Rectangle(
				textureRegion.x,
				textureScaleRect.y,
				textureScaleRect.x - textureRegion.x, 
				textureScaleRect.height
			);
			
			_bitmapC = new Sprite3D();
			_bitmapC.setTexture(bgTextureID);
			_bitmapC.width = scaleRect.width;
			_bitmapC.height = scaleRect.height;
			_bitmapC.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.y,
				textureScaleRect.width, 
				textureScaleRect.height
			);
			
			_bitmapR = new Sprite3D();
			_bitmapR.setTexture(bgTextureID);
			_bitmapR.width = textureData.width - scaleRect.x - scaleRect.width;
			_bitmapR.height = scaleRect.height;
			_bitmapR.textureRegion = new Rectangle(
				textureScaleRect.right,
				textureScaleRect.y,
				textureRegion.right - textureScaleRect.right, 
				textureScaleRect.height
			);
			
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
			
			_bitmapB = new Sprite3D();
			_bitmapB.setTexture(bgTextureID);
			_bitmapB.width = scaleRect.width;
			_bitmapB.height = textureData.height - scaleRect.height - scaleRect.y;
			_bitmapB.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.bottom,
				textureScaleRect.width, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
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
			
			_width = textureData.width;
			_height = textureData.height;
			
			resize();
		}
		
		public function resize():void
		{
			_bitmapT.width = _bitmapC.width = _bitmapB.width = _width - _bitmapTL.width - _bitmapTR.width;
			_bitmapL.height = _bitmapC.height = _bitmapR.height = _height - _bitmapTL.height - _bitmapBL.height;
			
			_bitmapT.x = _bitmapC.x = _bitmapB.x = _bitmapTL.width;
			_bitmapTR.x = _bitmapR.x = _bitmapBR.x = _bitmapTL.width + _bitmapT.width;
			_bitmapL.y = _bitmapC.y = _bitmapR.y = _bitmapTL.height;
			_bitmapBL.y = _bitmapB.y = _bitmapBR.y = _bitmapTL.height + _bitmapL.height;
		}
		
		override public function get width():Number
		{
			return _width;
		}
		
		override public function set width(value:Number):void
		{
			_width = value;
		}
		
		override public function get height():Number
		{
			return _height;
		}
		
		override public function set height(value:Number):void
		{
			_height = value;
		}
	}
}