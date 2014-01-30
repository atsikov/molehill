package molehill.easy.ui3d.list
{
	import easy.ui.IEasyItemRenderer;
	
	import molehill.core.render.Sprite3DContainer;

	public class EasyList3DItemRenderer extends Sprite3DContainer implements IEasyItemRenderer
	{
		public function EasyList3DItemRenderer()
		{
			super();
		}
		
		protected var _itemData:Object;
		public function get itemData():Object
		{
			return _itemData;
		}
		public function set itemData(value:Object):void
		{
			_itemData = value;
		}
		
		public function get isSelectable():Boolean
		{
			return _itemData != null;
		}
		
		protected var _selected:Boolean;
		public function get selected():Boolean
		{
			return _selected;
		}
		public function set selected(value:Boolean):void
		{
			_selected = value;
		}
		
		public function get isHighlightable():Boolean
		{
			return _itemData != null;
		}
		
		protected var _highlighted:Boolean;
		public function get highlighted():Boolean
		{
			return _highlighted;
		}
		public function set highlighted(value:Boolean):void
		{
			_highlighted = value;
		}
		
		public function update():void
		{
		}
	}
}