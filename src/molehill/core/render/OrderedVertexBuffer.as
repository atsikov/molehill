package molehill.core.render
{
	import flash.display3D.VertexBuffer3D;

	public class OrderedVertexBuffer
	{
		private var _index:int;
		private var _buffer:VertexBuffer3D;
		private var _bufferOffset:uint;
		private var _bufferFormat:String;
		public function OrderedVertexBuffer(index:int, buffer:VertexBuffer3D, bufferOffset:uint, bufferFormat:String)
		{
			_index = index;
			_buffer = buffer;
			_bufferOffset = bufferOffset;
			_bufferFormat = bufferFormat;
		}
		
		public function get index():int
		{
			return _index;
		}
		
		public function get buffer():VertexBuffer3D
		{
			return _buffer;
		}
		
		public function get bufferOffset():uint
		{
			return _bufferOffset;
		}
		
		public function get bufferFormat():String
		{
			return _bufferFormat;
		}
	}
}