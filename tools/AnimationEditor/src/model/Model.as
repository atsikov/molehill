package model
{
	import flash.events.EventDispatcher;
	
	import model.data.ParticleEmitterData;
	import model.events.ModelEvent;
	
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationFrameData;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	
	public class Model extends EventDispatcher
	{
		private static var _instance:Model;
		public static function getInstance():Model
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new Model();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		public function Model()
		{
			super(this);
			
			if (!_allowInstantion)
			{
				throw new Error("Use Model::getInstance()");
			}
			
			
		}
		
		private var _listCreatedAnimations:Vector.<CustomAnimationData>;
		public function get listCreatedAnimations():Vector.<CustomAnimationData>
		{
			if (_listCreatedAnimations == null)
			{
				_listCreatedAnimations = new Vector.<CustomAnimationData>();
			}
			
			return _listCreatedAnimations;
		}
		
		public function addAnimation(animationData:CustomAnimationData):void
		{
			listCreatedAnimations.push(animationData);
			
			dispatchEvent(
				new ModelEvent(ModelEvent.ANIMATION_ADDED, animationData)
			);
		}
		
		public function addNewAnimation(animationName:String):CustomAnimationData
		{
			var animationData:CustomAnimationData = new CustomAnimationData(animationName);
			listCreatedAnimations.push(animationData);
			
			dispatchEvent(
				new ModelEvent(ModelEvent.ANIMATION_ADDED, animationData)
			);
			
			return animationData;
		}
		
		public function removeAnimation(animationData:CustomAnimationData):CustomAnimationData
		{
			var animationIndex:int = _listCreatedAnimations.indexOf(animationData);
			_listCreatedAnimations.splice(animationIndex, 1);
			
			dispatchEvent(
				new ModelEvent(ModelEvent.ANIMATION_REMOVED, animationData)
			);
			
			if (_activeAnimation === animationData)
			{
				setActiveAnimation(null);
			}
			
			return animationData;
		}
		
		private var _activeAnimation:CustomAnimationData;
		public function get activeAnimationData():CustomAnimationData
		{
			return _activeAnimation;
		}
		
		public function getAnimation(animationName:String):CustomAnimationData
		{
			for (var i:int = 0; i < _listCreatedAnimations.length; i++)
			{
				if (_listCreatedAnimations[i].animationName == animationName)
				{
					return _listCreatedAnimations[i];
				}
			}
			
			return null;
		}
		
		public function setActiveAnimation(value:CustomAnimationData):void
		{
			if (_activeAnimation === value)
			{
				return;
			}
			
			_activeAnimation = value;
			setActiveFrame(_activeAnimation != null && _activeAnimation.listFrames.length > 0 ? _activeAnimation.listFrames[0] : null);
			
			dispatchEvent(
				new ModelEvent(ModelEvent.ACTIVE_ANIMATION_CHANGED, _activeAnimation)
			);
		}
		
		private var _listParticleEmitters:Vector.<ParticleEmitterData>;
		public function get listParticleEmitters():Vector.<ParticleEmitterData>
		{
			if (_listParticleEmitters == null)
			{
				_listParticleEmitters = new Vector.<ParticleEmitterData>();
			}
			
			return _listParticleEmitters;
		}
		
		public function addParticleEmitter(particleEmitter:ParticleEmitterData):void
		{
			listParticleEmitters.push(particleEmitter);
		}
		
		public function removeParticleEmitter(particleEmitter:ParticleEmitterData):ParticleEmitterData
		{
			var emitterIndex:int = listParticleEmitters.indexOf(particleEmitter);
			listParticleEmitters.splice(emitterIndex, 1);
			
			return particleEmitter;
		}
		
		public function getParticleEmitter(emitterName:String):ParticleEmitterData
		{
			for (var i:int = 0; i < listParticleEmitters.length; i++)
			{
				if (listParticleEmitters[i].name == emitterName)
				{
					return listParticleEmitters[i];
				}
			}
			
			return null;
		}
		
		private var _activeFrame:CustomAnimationFrameData;
		public function get activeFrameData():CustomAnimationFrameData
		{
			return _activeFrame;
		}
		
		public function setActiveFrame(value:CustomAnimationFrameData):void
		{
			if (_activeFrame === value)
			{
				return;
			}
			
			_activeFrame = value;
			
			dispatchEvent(
				new ModelEvent(ModelEvent.ACTIVE_FRAME_CHANGED, _activeAnimation)
			);
		}
		
		private var _listLoadedTextures:Array;
		public function get listActiveTextures():Array
		{
			if (_listLoadedTextures == null)
			{
				_listLoadedTextures = new Array();
				
				var listTextureAtlases:Array = TextureManager.getInstance().getAtlases();
				for (var i:int = 0; i < listTextureAtlases.length; i++)
				{
					var listTextureNames:Array = (listTextureAtlases[i] as TextureAtlasData).listTexturesNames;
					_listLoadedTextures = _listLoadedTextures.concat(listTextureNames);
				}
			}
			
			return _listLoadedTextures;
		}
		
		public function refreshListTextures():void
		{
			_listLoadedTextures = null;
			
			dispatchEvent(
				new ModelEvent(ModelEvent.TEXTURES_UPDATED, null)
			);
		}
	}
}