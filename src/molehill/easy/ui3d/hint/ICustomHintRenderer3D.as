package molehill.easy.ui3d.hint
{
	import flash.geom.Rectangle;

	public interface ICustomHintRenderer3D
	{
		function get x():Number;
		function set x(value:Number):void;
		//---
		function get y():Number;
		function set y(value:Number):void;
		//---
		function get width():Number;
		function set width(value:Number):void;
		//---
		function get height():Number;
		function set height(value:Number):void;
		
		function get hintData():*;
		function set hintData(value:*):void;
		
		function update():void;
		
		function setTargetBounds(value:Rectangle):void;

		function get alwaysTop():Boolean
	}
}