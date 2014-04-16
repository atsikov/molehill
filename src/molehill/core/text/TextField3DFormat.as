package molehill.core.text
{
	public class TextField3DFormat
	{
		public var align:String;
		public var color:uint;
		public var font:String;
		public var size:uint;
		
		public function TextField3DFormat(
			font:String = "",
			color:uint = 0,
			size:uint = 12,
			align:String = "alignLeft"
		)
		{
			this.font = font;
			this.color = color;
			this.size = size;
			this.align = align;
		}
	}
}