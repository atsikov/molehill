package molehill.core.render.engine
{
	import flash.display3D.textures.Texture;

	public class RenderChunkData
	{
		public var texture:Texture;
		public var firstIndex:uint;
		public var numTrinagles:uint;
		public var preRenderFunction:Function;
		public var postRenderFunction:Function;
		public var blendMode:String;
	}
}