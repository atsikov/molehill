package molehill.core.render
{
	
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.display3D.textures.Texture;
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.SpriteAnimationData;
	import molehill.core.sprite.SpriteData;
	import molehill.core.texture.SpriteSheetData;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;

	public class AnimatedSprite3D extends Sprite3D
	{
		public function AnimatedSprite3D()
		{
			super();
		}
		
		// Fields
		
		private var _totalFrames:uint
		public function get totalFrames():uint
		{
			return _totalFrames;
		}

		public function set totalFrames(value:uint):void
		{
			_totalFrames = value;
		}
		
		private var _currentFrame:int = 0;
		public function get currentFrame():int
		{
			return _currentFrame;
		}
		
		private var _regionsInRow:int = 1;
		public function get regionsInRow():int
		{
			return _regionsInRow;
		}

		public function set regionsInRow(value:int):void
		{
			_regionsInRow = value;
		}
		
		override public function set textureID(value:String):void
		{
			super.textureID = value;
			
			updateFrame();
		}
		
		override public function setSize(width:Number, height:Number):void
		{
			super.setSize(width, height);
			
			updateFrame();
		}
		
		// Public Methods
		public function play(frame:int = -1):void
		{
			if (frame == -1 && SpriteAnimationUpdater.getInstance().hasAnimation(this))
			{
				return;
			}
			
			if (frame != -1)
			{
				_currentFrame = frame;
			}
			nextFrame();
			
			SpriteAnimationUpdater.getInstance().addAnimation(this);
		}
		
		public function stop(frame:int = -1):void
		{
			if (frame != -1)
			{
				_currentFrame = frame;
			}
			updateFrame();
			
			SpriteAnimationUpdater.getInstance().removeAnimation(this);
		}
		
		private var _animationData:SpriteAnimationData;
		public function get animationData():SpriteAnimationData
		{
			return _animationData;
		}
		
		public function set animationData(value:SpriteAnimationData):void
		{
			_animationData = value;
			_totalFrames = _animationData.totalFrames;
			
			updateFrame();
		}
		
		internal function nextFrame():void
		{
			updateFrame();
			
			_currentFrame++;
			if (_currentFrame == int.MAX_VALUE)
			{
				_currentFrame = 0;
			}
			
			_textureChanged = true;
		}
		
		private function updateFrame():void
		{
			var texture:Texture = TextureManager.getInstance().getTextureByID(textureID);
			if (texture == null)
			{
				SpriteAnimationUpdater.getInstance().removeAnimation(this);
				return;
			}
			
			var spriteSheetData:SpriteSheetData = TextureManager.getInstance().getSpriteSheetData(textureID);
			if (spriteSheetData != null)
			{
				var frameRegion:Rectangle = spriteSheetData.getFrameRectangle(_currentFrame % spriteSheetData.totalFrames);
				var atlasID:String = TextureManager.getInstance().getAtlasIDByTexture(texture);
				var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByID(atlasID);
				var sheetRegion:Rectangle = atlas.getTextureBitmapRect(textureID);
				
				frameRegion.x += sheetRegion.x;
				frameRegion.y += sheetRegion.y;
				
				frameRegion.x /= atlas.width;
				frameRegion.y /= atlas.height;
				frameRegion.width /= atlas.width;
				frameRegion.height /= atlas.height;
				
				textureRegion = frameRegion;
			}
			else
			{
				textureRegion =  TextureManager.getInstance().getTextureRegion(textureID);
			}
			
			if (_animationData != null)
			{
				var state:SpriteData = _animationData.getFrameState(_currentFrame % _animationData.totalFrames);
				if (state != null)
				{
					state.applyScale(_parentScaleX, _parentScaleY);
					
					visible = true;
					state.applyValues(this);
				}
				else
				{
					visible = false;
				}
			}
		}
	}
}