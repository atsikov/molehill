package model.events
{
	import flash.events.Event;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	public class SceneStructureEvent extends Event
	{
		/**
		 * @eventType "childAdded"
		 **/
		public static const CHILD_ADDED:String = "childAdded";
		/**
		 * @eventType "childCopied"
		 **/
		public static const CHILD_COPIED:String = "childCopied";
		/**
		 * @eventType "childMoved"
		 **/
		public static const CHILD_MOVED:String = "childMoved";
		/**
		 * @eventType "childSelected"
		 **/
		public static const CHILD_SELECTED:String = "childSelected";
		
		public function SceneStructureEvent(type:String, child:Sprite3D, parent:Sprite3DContainer, index:int)
		{
			_child = child;
			_parent = parent;
			_index = index;
			
			super(type);
		}
		
		private var _child:Sprite3D;

		public function get child():Sprite3D
		{
			return _child;
		}

		private var _parent:Sprite3DContainer;

		public function get parent():Sprite3DContainer
		{
			return _parent;
		}

		private var _index:int;

		public function get index():int
		{
			return _index;
		}

	}
}