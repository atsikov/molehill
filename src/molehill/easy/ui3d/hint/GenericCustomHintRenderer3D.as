package molehill.easy.ui3d.hint
{
	import flash.geom.Rectangle;
	
	import molehill.core.sprite.Sprite3DContainer;

	public class GenericCustomHintRenderer3D extends Sprite3DContainer implements ICustomHintRenderer3D
	{
		public function GenericCustomHintRenderer3D()
		{
			mouseEnabled = false;
		}
		
		protected var _itemData:*;
		public function get hintData():*
		{
			return _itemData;
		}
		public function set hintData(value:*):void
		{
			_itemData = value;
		}
		
		public function update():void
		{
			//override
		}
		
		public function get targetPadding():int
		{
			return 10;
		}
		
		public function setTargetBounds(value:Rectangle):void
		{
			//override
		}
		
		public function get alwaysTop():Boolean
		{
			return false;
		}
	}
}