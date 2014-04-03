package molehill.core.sprite
{
	
	import flash.geom.Rectangle;
	
	import molehill.core.molehill_internal;
	import molehill.core.texture.SpriteSheetData;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	import molehill.core.animation.SpriteAnimationData;
	import molehill.core.animation.SpriteAnimationUpdater;
	
	use namespace molehill_internal;

	public class AnimatedSprite3D extends Sprite3D
	{
		public static function createFromTexture(textureID:String):AnimatedSprite3D
		{
			var sprite:AnimatedSprite3D = new AnimatedSprite3D();
			sprite.setTexture(textureID);
			
			var spriteSheetData:SpriteSheetData = TextureManager.getInstance().getSpriteSheetData(textureID);
			
			// overriding default setSize
			sprite._width = spriteSheetData.frameWidth;
			sprite._croppedWidth = spriteSheetData.frameWidth;
			sprite._height = spriteSheetData.frameHeight;
			sprite._croppedHeight = spriteSheetData.frameHeight;
			
			sprite.totalFrames = spriteSheetData.totalFrames;
			sprite.regionsInRow = spriteSheetData.framesPerRow;
			
			return sprite;
		}
		
		public function AnimatedSprite3D()
		{
			super();
		}
		
		// Fields
		
		private var _totalFrames:uint = int.MAX_VALUE;
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
		
		molehill_internal function nextFrame():void
		{
			updateFrame();
			
			_currentFrame++;
			if (_currentFrame == _totalFrames)
			{
				_currentFrame = 0;
			}
			
			_textureChanged = true;
		}
		
		protected function updateFrame():void
		{
			if (!TextureManager.getInstance().isTextureCreated(textureID))
			{
				SpriteAnimationUpdater.getInstance().removeAnimation(this);
				return;
			}
			
			_silentChange = true;
			var spriteSheetData:SpriteSheetData = TextureManager.getInstance().getSpriteSheetData(textureID);
			if (spriteSheetData != null)
			{
				var frameRegion:Rectangle = spriteSheetData.getFrameRectangle(_currentFrame % spriteSheetData.totalFrames);
				var atlas:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(textureID);
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
			_silentChange = false;
			hasChanged = true;
		}
	}
}