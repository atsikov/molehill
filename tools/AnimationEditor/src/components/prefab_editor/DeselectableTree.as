package components.prefab_editor
{
	import flash.events.MouseEvent;
	
	import mx.controls.Tree;
	import mx.controls.listClasses.IListItemRenderer;
	
	public class DeselectableTree extends Tree
	{
		public function DeselectableTree()
		{
			super();
		}
		
		override protected function mouseEventToItemRenderer(event:MouseEvent):IListItemRenderer
		{
			var row:IListItemRenderer = super.mouseEventToItemRenderer(event) as IListItemRenderer;
			
			if (row != null && event.type == MouseEvent.CLICK)
			{
				this.selectedIndex = itemRendererToIndex(row);
			}
			else if (event.type == MouseEvent.CLICK)
			{
				this.selectedIndex = -1;
			}
			
			return row;
		}
	}
}