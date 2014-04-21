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
			size:uint = 12,
			color:uint = 0,
			align:String = "alignLeft"
		)
		{
			this.font = font;
			this.size = size;
			this.color = color;
			this.align = align;
		}
	}
}