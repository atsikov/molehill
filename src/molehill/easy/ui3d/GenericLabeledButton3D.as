package molehill.easy.ui3d
{
	import flash.geom.Rectangle;
	
	import molehill.core.text.TextField3D;
	
	public class GenericLabeledButton3D extends Button9Scale3D
	{
		protected var _label:TextField3D;
		
		protected var _normalTextureID:String;
		protected var _overTextureID:String;
		protected var _downTextureID:String;
		protected var _disabledTextureID:String;
		protected var _rect9Scale:Rectangle;
		protected var _fillMethod:String = Sprite3D9ScaleFillMethod.STRETCH;
		
		public function GenericLabeledButton3D(label:String = "")
		{
			setButtonTextures();
			
			super(
				_normalTextureID,
				_rect9Scale,
				_fillMethod,
				_overTextureID,
				_downTextureID,
				_disabledTextureID
			);
			
			createLabel(label);
			
			if (_label != null)
			{
				resize();
			}
		}
		
		protected function setButtonTextures():void
		{
			//MUST OVERRIDE
		}
		
		protected function createLabel(label:String = ""):void
		{
			//MUST OVERRIDE
		}
		
		override public function set width(value:Number):void
		{
			super.width = value;
			
			updateLabelPostion();
		}
		
		override public function setSize(w:Number, h:Number):void
		{
			super.setSize(w, h);
			
			updateLabelPostion();
		}
		
		public function get label():String
		{
			return _label.text;
		}
		
		public function set label(value:String):void
		{
			_label.text = value;
			resize();
		}
		
		protected var _minWidth:Number = 0;
		public function set minWidth(value:Number):void
		{
			_minWidth = value;
			resize();
		}
		
		protected var _autoSize:Boolean = true;
		public function get autoSize():Boolean
		{
			return _autoSize;
		}
		/** default - true */
		public function set autoSize(value:Boolean):void
		{
			_autoSize = value;
			resize();
		}
		
		protected var _labelGap:int = 8;
		public function get labelGap():int
		{
			return _labelGap;
		}
		public function set labelGap(value:int):void
		{
			_labelGap = value;
			resize();
		}

		protected function resize():void
		{
			if (_autoSize)
			{
				width = Math.max(_label.width + 2 * _labelGap, _minWidth);
			}
			
			updateLabelPostion();
		}
		
		protected function updateLabelPostion():void
		{
			_label.x = int((width - _label.width) / 2);
		}

	}
}