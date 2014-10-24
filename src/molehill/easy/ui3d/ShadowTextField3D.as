package molehill.easy.ui3d
{
	import flash.geom.Point;
	import flash.text.TextField;
	
	import molehill.core.sprite.Sprite3D;
	import molehill.core.text.TextField3D;
	import molehill.core.text.TextField3DFormat;
	
	public class ShadowTextField3D extends TextField3D
	{
		private var _shadow:TextField3D;
		public function ShadowTextField3D()
		{
			super();
			
			_shadow = new TextField3D();
			_shadow.moveTo(_shadowOffset.x, _shadowOffset.y);
			addChildAtImplicit(_shadow, 0);
		}
		
		private var _shadowColor:uint = 0x000000;
		public function get shadowColor():uint
		{
			return _shadowColor;
		}
		
		public function set shadowColor(value:uint):void
		{
			_shadowColor = value;
			
			var shadowFormat:TextField3DFormat = _shadow.defaultTextFormat;
			shadowFormat.color = _shadowColor;
			_shadow.defaultTextFormat = shadowFormat;
		}
		
		private var _shadowOffset:Point = new Point(1, 1);
		public function get shadowOffset():Point
		{
			return _shadowOffset;
		}
		
		public function set shadowOffset(value:Point):void
		{
			_shadowOffset.setTo(value.x, value.y);
			_shadow.moveTo(value.x, value.y);
		}
		
		override public function set defaultTextFormat(value:TextField3DFormat):void
		{
			super.defaultTextFormat = value;
			
			var formatColor:uint = value.color;
			value.color = _shadowColor;
			_shadow.defaultTextFormat = value;
			value.color = formatColor;
		}
		
		override public function set text(value:String):void
		{
			super.text = value;
			_shadow.text = value;
		}
		
		override public function set width(value:Number):void
		{
			super.width = value;
			_shadow.width = value;
		}
		
		override public function set height(value:Number):void
		{
			super.height = value;
			_shadow.height = value;
		}
		
		override public function set wordWrap(value:Boolean):void
		{
			super.wordWrap = value;
			_shadow.wordWrap = value;
		}
		
		override protected function updateLayout():void
		{
			removeChildImplicit(_shadow);
			super.updateLayout();
			addChildAtImplicit(_shadow, 0);
		}
	}
}