package molehill.core.render
{
	/**
	 * 
	 *  This class is using certain batching to move all text fields to the top layer.
	 *  This allow to draw all texts in container within one draw call. 
	 * 
	 **/
	public class UIComponent3D extends Sprite3DContainer
	{
		public function UIComponent3D()
		{
			super();
			
			mouseEnabled = true;
		}
		
		override public function addChild(child:Sprite3D):Sprite3D
		{
			child.mouseEnabled = true;
			
			return super.addChild(child);
		}
		
		override public function addChildAt(child:Sprite3D, index:int):Sprite3D
		{
			child.mouseEnabled = true;
			
			return super.addChildAt(child, index);
		}
	}
}