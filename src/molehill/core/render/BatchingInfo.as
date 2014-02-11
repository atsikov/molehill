package molehill.core.render
{
	import utils.StringUtils;
	import molehill.core.sprite.Sprite3D;

	internal final class BatchingInfo
	{
		private var _child:Sprite3D;
		public function BatchingInfo(child:Sprite3D)
		{
			_child = child;
		}
		
		public function get child():Sprite3D
		{
			return _child;
		}
		
		private var _batcher:IVertexBatcher;
		public function get batcher():IVertexBatcher
		{
			return _batcher;
		}
		
		public function set batcher(batcher:IVertexBatcher):void
		{
			_batcher = batcher;
		}
		
		public function toString():String
		{
			return _child.toString();
		}
	}
}