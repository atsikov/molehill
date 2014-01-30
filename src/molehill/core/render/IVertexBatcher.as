package molehill.core.render
{
	import flash.utils.ByteArray;

	public interface IVertexBatcher
	{
		function getVerticesData():ByteArray;
		function getIndicesData(passedVertices:uint):ByteArray;
		function get numTriangles():uint;
		
		function get textureAtlasID():String;
		function set textureAtlasID(value:String):void;
		
		function get preRenderFunction():Function;
		function set preRenderFunction(value:Function):void;
		
		function get postRenderFunction():Function;
		function set postRenderFunction(value:Function):void;
		
		function get blendMode():String;
		function set blendMode(value:String):void;
	}
}