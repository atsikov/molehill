package molehill.core.sprite
{
	import flash.utils.getTimer;
	
	import molehill.core.animation.AnimationPlayMode;
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationFrameData;
	import molehill.core.animation.SpriteAnimationUpdater;
	import molehill.core.molehill_internal;

	use namespace molehill_internal;
	
	public class CustomAnimatedSprite3D extends AnimatedSprite3D
	{
		public function CustomAnimatedSprite3D()
		{
			super();
		}
		
		private var _isPlaying:Boolean = false;
		override public function play(frame:int=-1):void
		{
			if (frame < -1)
			{
				return;
			}
			
			if (_isPlaying && frame == -1)
			{
				return;
			}
			
			if (frame > customAnimationData.listFrames.length - 1)
			{
				frame = customAnimationData.listFrames.length - 1;
			}
				
			_currentFrameIndex = frame == -1 ? _currentFrameIndex : (frame >= customAnimationData.listFrames.length ? customAnimationData.listFrames.length - 1 : frame);
			_currentFrameRepeated = 0;
			_isReversed = false;
			
			_isPlaying = true;
			
			super.play(frame);
		}
		
		override public function stop(frame:int = -1):void
		{
			if (!_isPlaying && frame == -1)
			{
				return;
			}
			
			_isPlaying = false;
			super.stop(frame);
		}
		
		private var _customAnimationData:CustomAnimationData;
		public function get customAnimationData():CustomAnimationData
		{
			return _customAnimationData;
		}
		
		public function set customAnimationData(value:CustomAnimationData):void
		{
			_customAnimationData = value;
		}
		
		private var _currentFrameIndex:int;
		private var _currentFrameRepeated:int;
		private var _lastFrameTime:int;
		
		private var _currentTimelineFrameIndex:int = 0;
		private var _lastTimelineFrameTime:int = 0;
		
		private var _isReversed:Boolean = false;
		override protected function updateFrame():void
		{
			if (_customAnimationData == null && _animationTimelineData == null)
			{
				if (_isPlaying)
				{
					stop();
				}
				return;
			}
			
			if (_animationTimelineData != null)
			{
				var numAnimationFrames:int = _animationTimelineData.totalFrames;
				var currentFrameTime:int = getTimer() - _lastTimelineFrameTime;
				
				var timelineFrameRate:int = _animationTimelineData.frameRate > 0 ? _animationTimelineData.frameRate : SpriteAnimationUpdater.getInstance().fps;
				var currentFrameIndex:int = _currentTimelineFrameIndex;
				if (currentFrameTime > (1000 / timelineFrameRate))
				{
					_currentTimelineFrameIndex++;
				}
				
				if (currentFrameIndex != _currentTimelineFrameIndex)
				{
					if (_currentTimelineFrameIndex >= numAnimationFrames)
					{
						_currentTimelineFrameIndex = 0;
					}
					
					var state:SpriteData = _animationTimelineData.getFrameState(_currentTimelineFrameIndex);
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
				
				_lastTimelineFrameTime = getTimer();
			}
			
			if (_customAnimationData == null)
			{
				return;
			}
			
			numAnimationFrames = _customAnimationData.listFrames.length;
			currentFrameTime = getTimer() - _lastFrameTime;
			if (currentFrameTime < (1000 / _customAnimationData.frameRate))
			{
				return;
			}
			
			_lastFrameTime = getTimer();
			
			
			if (_isPlaying)
			{
				if (_activeFrame != null && _currentFrameRepeated >= _activeFrame.repeatCount)
				{
					_currentFrameRepeated = 0;
					if (_isReversed)
					{
						_currentFrameIndex--;
					}
					else
					{
						_currentFrameIndex++;
					}
				}
				
				if (_currentFrameIndex >= numAnimationFrames || _currentFrameIndex < 0)
				{
					switch (_customAnimationData.playMode)
					{
						case AnimationPlayMode.LOOP:
							_currentFrameIndex = 0;
							break;
						
						case AnimationPlayMode.PING_PONG:
							_isReversed = !_isReversed;
							_currentFrameIndex = _isReversed ? numAnimationFrames - 1 : 0;
							
							_currentFrameRepeated = 1;
							if (numAnimationFrames <= 1)
							{
								_currentFrameIndex = 0;
							}
							else
							{
								if (_activeFrame != null && _currentFrameRepeated >= _activeFrame.repeatCount)
								{
									_currentFrameRepeated = 0;
									if (_isReversed)
									{
										_currentFrameIndex--;
									}
									else
									{
										_currentFrameIndex++;
									}
								}
								
							}
							break;
					}
				}
				_currentFrameRepeated++;
			}
			
			if (_currentFrameIndex < numAnimationFrames)
			{
				setCurrentFrame(_customAnimationData.listFrames[_currentFrameIndex]);
			}
			else
			{
				setCurrentFrame(null);
			}
		}
		
		private var _activeFrame:CustomAnimationFrameData;
		private function setCurrentFrame(frameData:CustomAnimationFrameData):void
		{
			if (_activeFrame === frameData)
			{
				return;
			}
			
			_activeFrame = frameData;
			
			updateSprite();
		}
		
		private function updateSprite():void
		{
			setTexture(_activeFrame.textureName);
		}
	}
}