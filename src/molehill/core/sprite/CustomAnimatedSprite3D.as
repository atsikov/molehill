package molehill.core.sprite
{
	import flash.utils.getTimer;
	
	import molehill.core.animation.AnimationPlayMode;
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationFrameData;

	public class CustomAnimatedSprite3D extends AnimatedSprite3D
	{
		public function CustomAnimatedSprite3D()
		{
			super();
		}
		
		private var _isPlaying:Boolean = false;
		override public function play(frame:int=-1):void
		{
			_currentFrameIndex = 0;
			_currentFrameRepeated = 0;
			_isReversed = false;
			
			_isPlaying = true;
			
			super.play(frame);
		}
		
		override public function stop(frame:int = -1):void
		{
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
		private var _isReversed:Boolean = false;
		override protected function updateFrame():void
		{
			if (_customAnimationData == null)
			{
				if (_isPlaying)
				{
					stop();
				}
				return;
			}
			
			var numAnimationFrames:int = _customAnimationData.listFrames.length;
			var currentFrameTime:int = getTimer() - _lastFrameTime;
			if (currentFrameTime < (1000 / _customAnimationData.frameRate))
			{
				return;
			}
			
			_lastFrameTime = getTimer();
			
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