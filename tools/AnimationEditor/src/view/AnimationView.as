package view
{
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	
	import model.Model;
	import model.events.FrameDataEvent;
	import model.events.ModelEvent;
	import model.types.AnimationPlayMode;
	
	import molehill.core.Scene3DManager;
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationFrameData;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;

	public class AnimationView extends Sprite3DContainer
	{
		public function AnimationView()
		{
			_sprite = new Sprite3D();
			
			Model.getInstance().addEventListener(ModelEvent.ACTIVE_ANIMATION_CHANGED, onActiveAnimationChanged);
			Model.getInstance().addEventListener(ModelEvent.ACTIVE_FRAME_CHANGED, onActiveFrameChanged);
		}
		
		protected function onActiveAnimationChanged(event:Event):void
		{
			update();
		}
		
		private var _activeFrame:CustomAnimationFrameData;
		protected function onActiveFrameChanged(event:Event):void
		{
			Model.getInstance().addEventListener(FrameDataEvent.TEXTURE_CHANGED, onFrameTextureChanged);
			_activeFrame = Model.getInstance().activeFrameData;
			
			update();
		}
		
		private function onFrameTextureChanged(event:Event):void
		{
			update();
		}
		
		private var _sprite:Sprite3D;
		private function update():void
		{
			if (_activeFrame == null)
			{
				if (_sprite.parent != null)
				{
					removeChild(_sprite);
				}
				return;
			}
			
			var tm:TextureManager = TextureManager.getInstance();
			if (!tm.isTextureCreated(_activeFrame.textureName))
			{
				if (_sprite.parent != null)
				{
					removeChild(_sprite);
				}
				return;
			}
			
			_sprite.setTexture(_activeFrame.textureName);
			
			var renderEngine:RenderEngine = Scene3DManager.getInstance().renderEngine;
			
			_sprite.moveTo(
				renderEngine.getViewportWidth() / 2 - _sprite.width,
				renderEngine.getViewportHeight() / 2 - _sprite.height
			);
			
			if (_sprite.parent == null)
			{
				addChild(_sprite);
			}
		}
		
		private var _timer:Timer;
		public function play():void
		{
			if (_timer == null)
			{
				_timer = new Timer(1000 / 60);
			}
			
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			
			_lastLoopTime = getTimer();
			_lastFrameTime = 0;
			
			_currentFrameIndex = 0;
			_currentFrameRepeated = 0;
			_isReversed = false;
			
			_timer.reset();
			_timer.start();
		}
		
		public function stop():void
		{
			_timer.stop();
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			
			_activeFrame = Model.getInstance().activeFrameData;
			update();
		}
		
		private var _currentFrameIndex:int;
		private var _currentFrameRepeated:int;
		private var _lastLoopTime:int;
		private var _lastFrameTime:int;
		
		private var _isReversed:Boolean = false;
		private function onTimer(event:Event):void
		{
			var currentAnimation:CustomAnimationData = Model.getInstance().activeAnimationData;
			
			if (currentAnimation == null)
			{
				stop();
				return;
			}
			
			var currentFrameTime:int = getTimer() - _lastFrameTime;
			if (currentFrameTime < (1000 / currentAnimation.frameRate))
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
			
			if (_currentFrameIndex >= currentAnimation.listFrames.length || _currentFrameIndex < 0)
			{
				switch (currentAnimation.playMode)
				{
					case AnimationPlayMode.LOOP:
						_currentFrameIndex = 0;
						break;
					
					case AnimationPlayMode.PING_PONG:
						_isReversed = !_isReversed;
						_currentFrameIndex = _isReversed ? currentAnimation.listFrames.length - 1 : 0;
						
						_currentFrameRepeated = 1;
						if (currentAnimation.listFrames.length <= 1)
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
			
			if (_currentFrameIndex < currentAnimation.listFrames.length)
			{
				_activeFrame = currentAnimation.listFrames[_currentFrameIndex];
			}
			else
			{
				_activeFrame = null;
			}
			update();
		}
	}
}