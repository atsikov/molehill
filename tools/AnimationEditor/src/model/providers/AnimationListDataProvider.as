package model.providers
{
	import flash.events.Event;
	
	import model.Model;
	import model.events.ModelEvent;
	
	import molehill.core.animation.CustomAnimationData;
	import molehill.core.animation.CustomAnimationManager;
	import molehill.core.events.CustomAnimationManagerEvent;
	
	import mx.collections.ArrayCollection;
	
	public class AnimationListDataProvider extends ArrayCollection
	{
		private var _listAnimationNames:Array;
		private var _listAnimationData:Array;
		public function AnimationListDataProvider()
		{
			Model.getInstance().addEventListener(ModelEvent.ANIMATION_ADDED, onAnimationsChaged);
			Model.getInstance().addEventListener(ModelEvent.ANIMATION_REMOVED, onAnimationsChaged);
			
			CustomAnimationManager.getInstance().addEventListener(CustomAnimationManagerEvent.ANIMATIONS_ADDED, onAnimationsChaged);
			
			_listAnimationNames = new Array();
			_listAnimationData = new Array();
			
			var listCreatedAnimations:Array = CustomAnimationManager.getInstance().listAnimationNames;
			for (var i:int = 0; i < listCreatedAnimations.length; i++)
			{
				_listAnimationNames.push(listCreatedAnimations[i]);
				_listAnimationData.push(
					CustomAnimationManager.getInstance().getAnimationData(listCreatedAnimations[i])
				);
			}
			
			super(_listAnimationNames);
		}
		
		private function updateList():void
		{
			_listAnimationNames.splice(0, _listAnimationNames.length);
			
			var listCreatedAnimations:Vector.<CustomAnimationData> = Model.getInstance().listCreatedAnimations;
			for (var i:int = 0; i < listCreatedAnimations.length; i++)
			{
				_listAnimationData.push(listCreatedAnimations[i]);
				_listAnimationNames.push(listCreatedAnimations[i].animationName);
			}
			
			refresh();
		}
		
		protected function onAnimationsChaged(event:Event):void
		{
			updateList();
		}
	}
}