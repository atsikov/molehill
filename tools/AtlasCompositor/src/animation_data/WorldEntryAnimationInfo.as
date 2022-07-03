package animation_data
{
	public class WorldEntryAnimationInfo
	{
		private static var _instance:WorldEntryAnimationInfo;
		public static function getInstance():WorldEntryAnimationInfo
		{
			if (_instance == null)
			{
				_allowInstantion = true;
				_instance = new WorldEntryAnimationInfo();
				_allowInstantion = false;
			}
			
			return _instance;
		}
		
		private static var _allowInstantion:Boolean = false;
		private var _hashAnimationsInfo:Object;
		public function WorldEntryAnimationInfo()
		{
			if (!_allowInstantion)
			{
				throw new Error("Use WorldEntryAnimationInfo::getInstance()");
			}
			
			_hashAnimationsInfo = new Object();
		}
		
		public function reset():void
		{
			_hashAnimationsInfo = new Object();
		}
		
		public function addAnimationInfo(entryId:String, animationData:Object):void
		{
			if (_hashAnimationsInfo[entryId] != null)
			{
				return;
			}
			
			_hashAnimationsInfo[entryId] = animationData;
		}
		
		public function getAnimationInfo(entryId:String):Object
		{
			return _hashAnimationsInfo[entryId];
		}
	}
}