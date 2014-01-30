package molehill.core.render.engine
{
	import flash.geom.Point;
	import flash.utils.ByteArray;

	public interface IRenderEngine
	{
		function get isReady():Boolean;
		
		function configureVertexBuffer(verticesOffset:int, colorOffset:int, textureOffset:int, dataPerVertex:int):void;
		
		function setViewportSize(width:int, height:int):void;
		function getViewportWidth():int;
		function getViewportHeight():int;
		
		function bindTexture(textureAtlasID:String, sampler:uint = 0):void;
		
		function setPreRenderFunction(value:Function):void;
		function setPostRenderFunction(value:Function):void;
		
		function setVertexBufferData(data:ByteArray):void;
		function setIndexBufferData(data:ByteArray):void;
		
		function drawTriangles(numTriangles:int):uint;
		
		function clear():void;
		function present():void;
		
 		function setCameraPosition(position:Point):void;
		
		function setBlendMode(blendMode:String):void;
	}
}