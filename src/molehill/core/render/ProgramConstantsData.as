package molehill.core.render
{
	public class ProgramConstantsData
	{
		private var _index:int;
		private var _type:String;
		private var _data:Vector.<Number>;
		public function ProgramConstantsData(index:int, type:String, data:Vector.<Number>)
		{
			_index = index;
			_type = type;
			_data = data;
		}

		public function get index():int
		{
			return _index;
		}

		public function get type():String
		{
			return _type;
		}

		public function get data():Vector.<Number>
		{
			return _data;
		}
	}
}