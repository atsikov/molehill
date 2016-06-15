package molehill.easy.ui3d
{
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
		
		private var _totalWidth:Number = 0;
		private var _totalHeight:Number = 0;
		
		private var _fillMethod:String;
		public function Sprite3D9Scale(bgTextureID:String = null, scaleRect:Rectangle = null, fillMethod:String = "stretch")
		{
			super();
			
			_fillMethod = fillMethod;
			
			if (bgTextureID != null)
			{
				setTexture(bgTextureID);
			}
			
			if (scaleRect != null)
			{
				this.scaleRect = scaleRect;
			}
		}
		
		override public function setTexture(value:String):void
		{
			super.setTexture(value);
			if (_scaleRect != null)
			{
				updateSprite();
			}
		}
		
		private var _scaleRect:Rectangle;
		public function get scaleRect():Rectangle
		{
			return _scaleRect;
		}
		
		public function set scaleRect(value:Rectangle):void
		{
			_scaleRect = value;
			
			if (textureID != null)
			{
				updateSprite();
			}
		}
		
		private function updateSprite():void
		{
			var tm:TextureManager = TextureManager.getInstance();
			var textureRegion:Rectangle = tm.getTextureRegion(textureID);
			var textureData:TextureData = tm.getTextureDataByID(textureID);
			var textureScaleRect:Rectangle = new Rectangle();
			textureScaleRect.left = textureRegion.left + _scaleRect.left / textureData.width * textureRegion.width
			textureScaleRect.top = textureRegion.top + _scaleRect.top / textureData.height * textureRegion.height
			textureScaleRect.right = textureRegion.left + _scaleRect.right / textureData.width * textureRegion.width
			textureScaleRect.bottom = textureRegion.top + _scaleRect.bottom / textureData.height * textureRegion.height
			
			_scaleRect = _scaleRect;
			
			var spriteClass:Class;
			switch (_fillMethod)
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
			_bitmapTL.setTexture(textureID);
			_bitmapTL.width = _scaleRect.x;
			_bitmapTL.height = _scaleRect.y;
			_bitmapTL.textureRegion = new Rectangle(
				textureRegion.x,
				textureRegion.y,
				textureScaleRect.x - textureRegion.x, 
				textureScaleRect.y - textureRegion.y
			);
			
			_bitmapT = new spriteClass();
			_bitmapT.setTexture(textureID);
			_bitmapT.width = _scaleRect.width;
			_bitmapT.height = _scaleRect.y;
			_bitmapT.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureRegion.y,
				textureScaleRect.width, 
				textureScaleRect.y - textureRegion.y
			);
			
			if (_bitmapT is TiledSprite3D)
			{
				(_bitmapT as TiledSprite3D).setTileSize(
					_scaleRect.width,
					_scaleRect.top
				);
			}
			
			_bitmapTR = new Sprite3D();
			_bitmapTR.setTexture(textureID);
			_bitmapTR.width = textureData.width - _scaleRect.x - _scaleRect.width;
			_bitmapTR.height = _scaleRect.y;
			_bitmapTR.textureRegion = new Rectangle( 
				textureScaleRect.right,
				textureRegion.y,
				textureRegion.right - textureScaleRect.right, 
				textureScaleRect.y - textureRegion.y
			);
			
			// -------------------------------------
			_bitmapL = new spriteClass();
			_bitmapL.setTexture(textureID);
			_bitmapL.width = _scaleRect.x;
			_bitmapL.height = _scaleRect.height;
			_bitmapL.textureRegion = new Rectangle(
				textureRegion.x,
				textureScaleRect.y,
				textureScaleRect.x - textureRegion.x, 
				textureScaleRect.height
			);
			
			if (_bitmapL is TiledSprite3D)
			{
				(_bitmapL as TiledSprite3D).setTileSize(
					_scaleRect.left,
					_scaleRect.height
				);
			}
			
			_bitmapC = new spriteClass();
			_bitmapC.setTexture(textureID);
			_bitmapC.width = _scaleRect.width;
			_bitmapC.height = _scaleRect.height;
			_bitmapC.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.y,
				textureScaleRect.width, 
				textureScaleRect.height
			);
			
			if (_bitmapC is TiledSprite3D)
			{
				(_bitmapC as TiledSprite3D).setTileSize(
					_scaleRect.width,
					_scaleRect.height
				);
			}
			
			_bitmapR = new spriteClass();
			_bitmapR.setTexture(textureID);
			_bitmapR.width = textureData.width - _scaleRect.x - _scaleRect.width;
			_bitmapR.height = _scaleRect.height;
			_bitmapR.textureRegion = new Rectangle(
				textureScaleRect.right,
				textureScaleRect.y,
				textureRegion.right - textureScaleRect.right, 
				textureScaleRect.height
			);
			
			if (_bitmapR is TiledSprite3D)
			{
				(_bitmapR as TiledSprite3D).setTileSize(
					textureData.width - _scaleRect.right,
					_scaleRect.height
				);
			}
			
			// -------------------------------------
			_bitmapBL = new Sprite3D();
			_bitmapBL.setTexture(textureID);
			_bitmapBL.width = _scaleRect.x;
			_bitmapBL.height = textureData.height - _scaleRect.height - _scaleRect.y;
			_bitmapBL.textureRegion = new Rectangle(
				textureRegion.x,
				textureScaleRect.bottom,
				textureScaleRect.x - textureRegion.x, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
			_bitmapB = new spriteClass();
			_bitmapB.setTexture(textureID);
			_bitmapB.width = _scaleRect.width;
			_bitmapB.height = textureData.height - _scaleRect.height - _scaleRect.y;
			_bitmapB.textureRegion = new Rectangle(
				textureScaleRect.x,
				textureScaleRect.bottom,
				textureScaleRect.width, 
				textureRegion.bottom - textureScaleRect.bottom
			);
			
			if (_bitmapB is TiledSprite3D)
			{
				(_bitmapB as TiledSprite3D).setTileSize(
					_scaleRect.width,
					textureData.height - _scaleRect.bottom
				);
			}
			
			_bitmapBR = new Sprite3D();
			_bitmapBR.setTexture(textureID);
			_bitmapBR.width = textureData.width - _scaleRect.x - _scaleRect.width;
			_bitmapBR.height = textureData.height - _scaleRect.height - _scaleRect.y;
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
			if (_bitmapT == null)
			{
				return;
			}
			
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
			_totalWidth = w * scaleX;
			_totalHeight = h * scaleY;
			
			resize();
		}
	}
}