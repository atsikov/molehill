package molehill.core.sort
{
	import easy.ui.EasySprite;
	
	import flash.display.Graphics;
	import flash.display.Shape;
	import flash.events.Event;
	
	import molehill.core.render.Sprite3D;
	import molehill.core.render.Sprite3DContainer;
	

	public class ZSortContainer extends Sprite3DContainer
	{
		private var _listChildren:ZSortedLinkedList = new ZSortedLinkedList();
		
		public function ZSortContainer()
		{
			
		}
		
		public override function addChild(child:Sprite3D) : Sprite3D
		{
			var needReplace:Boolean = _listChildren.add(child);
			
			if (needReplace)
			{
				var next:Sprite3D = _listChildren.getNextOf(child) as Sprite3D;
				if (next != null)
				{
					if (contains(child))
					{
						removeChild(child);
					}
					var index:int = getChildIndex(next);
					super.addChildAt(child, index);
				}
				else
				{
					super.addChild(child);
				}
			}
			else if (!contains(child))
			{
				super.addChildAt(child, 0);
			}
			
			child.addEventListener(ZSortEvent.MOVE, onChildMove);
			
			return child;
		}
		
		/*private var _debugShape:Shape = new Shape();//*/
		
		public override function removeChild(child:Sprite3D) : Sprite3D
		{
			super.removeChild(child);
			_listChildren.remove(child);
			
			child.removeEventListener(ZSortEvent.MOVE, onChildMove);
			
			return child;
		}
		
		public override function addChildAt(child:Sprite3D, index:int) : Sprite3D
		{
			return addChild(child);
		}
		
		public override function removeChildAt(index:int) : Sprite3D
		{
			var child:Sprite3D = getChildAt(index);
			return removeChild(child);
		}
		
		//----------------------------------------------------------------------------------
		public function updatePosition(child:Sprite3D):void
		{
			var needReplace:Boolean = _listChildren.updatePlace(child);
			
			if (needReplace)
			{
				super.removeChild(child);
				var next:Sprite3D = _listChildren.getNextOf(child) as Sprite3D;
				if (next != null)
				{
					var index:int = getChildIndex(next);
					super.addChildAt(child, index);
				}
				else
				{
					super.addChild(child);
				}
			}
		}
		
		private function onChildMove(event:Event):void
		{
			var child:Sprite3D = event.target as Sprite3D;
			if (child == null)
				return;
			
			if ( !contains(child) )
				return;
			
			updatePosition(child);
		}
	}
}