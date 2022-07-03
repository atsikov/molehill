package model.events
{
	import flash.events.Event;
	
	public class TrainPrefabEditorPanelEvent extends Event
	{
		/**
		 * @eventType placeAnchors
		 **/
		public static const PLACE_ANCHORS:String = "placeAnchors";
		/**
		 * @eventType mirrorAnchors
		 **/
		public static const MIRROR_ANCHORS:String = "mirrorAnchors";
		/**
		 * @eventType copyAnchors
		 **/
		public static const COPY_ANCHORS:String = "copyAnchors";
		/**
		 * @eventType pasteAnchors
		 **/
		public static const PASTE_ANCHORS:String = "pasteAnchors";
		
		public function TrainPrefabEditorPanelEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}