package molehill.core.render.engine
{
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.textures.Texture;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.OrderedVertexBuffer;
	import molehill.core.render.shader.Shader3D;
	
	internal class RenderChunkData
	{
		public var texture:Texture;
		public var firstIndex:uint;
		public var numTriangles:uint;
		public var shader:Shader3D;
		public var blendMode:String;
		public var scrollX:Number;
		public var scrollY:Number;
		public var additionalVertexBuffers:Vector.<OrderedVertexBuffer>;
		public var customIndexBuffer:IndexBuffer3D;
	}
}