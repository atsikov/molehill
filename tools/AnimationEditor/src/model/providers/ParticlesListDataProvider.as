package model.providers
{
	import model.data.ParticleEmitterData;
	
	import mx.collections.ArrayCollection;

	public class ParticlesListDataProvider extends ArrayCollection
	{
		private static var _instance:ParticlesListDataProvider;
		public static function getInstance():ParticlesListDataProvider
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new ParticlesListDataProvider();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		
		private var _listParticlesNames:Array;
		private var _listParticlesData:Array;
		public function ParticlesListDataProvider()
		{
			_listParticlesNames = new Array();
			_listParticlesData = new Array();
			
			super(_listParticlesNames);
			
			if (!_allowInstantion)
			{
				throw new Error("Use ParticlesListDataProvider::getInstance()");
			}
		}
		
		public function getParticlesDataByName(particlesName:String):ParticleEmitterData
		{
			var index:int = _listParticlesNames.indexOf(particlesName);
			if (index != -1)
			{
				return _listParticlesData[index];
			}
			
			return null;
		}
		
		public function addParticlesData(particlesData:ParticleEmitterData):void
		{
			var index:int = _listParticlesData.indexOf(particlesData);
			if (index != -1)
			{
				_listParticlesNames[index] = particlesData.name;
			}
			else
			{
				_listParticlesData.push(particlesData);
				_listParticlesNames.push(particlesData.name);
			}
			
			refresh();
		}
		
		public function removeParticlesData(particlesData:ParticleEmitterData):void
		{
			var index:int = _listParticlesData.indexOf(particlesData);
			if (index != -1)
			{
				_listParticlesNames.splice(index, 1);
				_listParticlesData.splice(index, 1);
				
				refresh();
			}
		}
	}
}