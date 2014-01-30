package molehill.core.render
{
	import flash.display3D.Context3DBlendFactor;

	public class BlendMode
	{
		private static const _blendFactors:Object = 
			{
				"normal"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
				"add"      : [ Context3DBlendFactor.ONE, Context3DBlendFactor.ONE ],
				"multiply" : [ Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ],
				"screen"   : [ Context3DBlendFactor.SOURCE_ALPHA, Context3DBlendFactor.ONE ],
				"erase"    : [ Context3DBlendFactor.ZERO, Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA ]
			};
			
		public static const NORMAL:String = "normal";
		
		public static const ADD:String = "add";
		
		public static const MULTIPLY:String = "multiply";
		
		public static const SCREEN:String = "screen";
		
		public static const ERASE:String = "erase";
		
		public static function getBlendFactors(blendMode:String):Array
		{
			if (blendMode == null)
			{
				return _blendFactors["normal"];
			}
			
			if (blendMode in _blendFactors)
			{
				return _blendFactors[blendMode];
			}
			else
			{
				return _blendFactors["normal"];
			}
		}
	}
}