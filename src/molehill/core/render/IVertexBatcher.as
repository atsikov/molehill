package molehill.core.render
{
	import flash.display3D.Context3D;
	import flash.display3D.IndexBuffer3D;
	import flash.utils.ByteArray;
	
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.sprite.Sprite3D;

	public interface IVertexBatcher
	{
		function onContextRestored():void;
		
		function getVerticesData():ByteArray;
		function getIndicesData(passedVertices:uint):ByteArray;
		function get numTriangles():uint;
		
		function get textureAtlasID():String;
		function set textureAtlasID(value:String):void;
		
		function get shader():Shader3D;
		function set shader(value:Shader3D):void;
		
		function get blendMode():String;
		function set blendMode(value:String):void;
		
		function get batcherCamera():CustomCamera;
		function get cameraOwner():Sprite3D;
		function set cameraOwner(value:Sprite3D):void;
		
		function get left():Number;
		function get right():Number;
		function get top():Number;
		function get bottom():Number;
		
		function getAdditionalVertexBuffers(context:Context3D):Vector.<OrderedVertexBuffer>;
		function getCustomIndexBuffer(context:Context3D):IndexBuffer3D;
		function get indexBufferOffset():int;
	}
}