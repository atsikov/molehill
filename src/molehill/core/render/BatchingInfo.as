package molehill.core.render
{
	import molehill.core.sprite.Sprite3D;
	
	import utils.StringUtils;

	internal final class BatchingInfo
	{
		private var _child:Sprite3D;
		public function BatchingInfo()
		{
			
		}
		
		public function get child():Sprite3D
		{
			return _child;
		}
		
		public function set child(value:Sprite3D):void
		{
			_child = value;
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
		
		public function reset():void
		{
			_child = null;
			_batcher = null;
		}
		
		public function toString():String
		{
			return _child.toString() + " Batcher " + StringUtils.getObjectAddress(_batcher);
		}
	}
}