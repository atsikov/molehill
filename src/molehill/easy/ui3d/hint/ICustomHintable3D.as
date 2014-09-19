package molehill.easy.ui3d.hint
{
	import flash.events.IEventDispatcher;
	import flash.events.MouseEvent;

	[Event(name="mouseOver", type="molehill.core.events.Input3DMouseEvent")]
	
	[Event(name="mouseOut", type="molehill.core.events.Input3DMouseEvent")]
	
	public interface ICustomHintable3D extends IEventDispatcher
	{
		function get hintData():*
	}
}