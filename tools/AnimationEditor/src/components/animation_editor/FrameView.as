package components.animation_editor
{
	import flash.display.GradientType;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextFormatAlign;
	
	import model.Model;
	import model.events.FrameDataEvent;
	import model.events.ModelEvent;
	
	import molehill.core.animation.CustomAnimationFrameData;
	
	import mx.core.UIComponent;
	
	public class FrameView extends UIComponent
	{
		private var _frameData:CustomAnimationFrameData;
		public function FrameView(frameData:CustomAnimationFrameData)
		{
			super();
			
			mouseChildren = false;
			
			_frameData = frameData;
			
			Model.getInstance().addEventListener(FrameDataEvent.REPEAT_COUNT_CHANGED, updateOnChange);
			Model.getInstance().addEventListener(FrameDataEvent.TEXTURE_CHANGED, updateOnChange);
			
			_tfTextureName = new TextField();
			_tfTextureName.selectable = false;
			addChild(_tfTextureName);
			
			var textFormat:TextFormat = _tfTextureName.defaultTextFormat;
			textFormat.align = TextFormatAlign.CENTER;
			_tfTextureName.defaultTextFormat = textFormat;
			
			Model.getInstance().addEventListener(ModelEvent.ACTIVE_FRAME_CHANGED, onActiveFrameChanged);
			
			addEventListener(MouseEvent.CLICK, onMouseClick);
			
			update();
		}
		
		protected function onActiveFrameChanged(event:Event):void
		{
			update();
		}
		
		protected function updateOnChange(event:Event):void
		{
			update();
		}
		
		private var _tfTextureName:TextField;
		private function update():void
		{
			graphics.clear();

			graphics.lineStyle(1, 0x000000);
			
			var gradientMatrix:Matrix = new Matrix();
			gradientMatrix.createGradientBox(_frameData.repeatCount * 100, 50, Math.PI / 2);
			
			var isSelected:Boolean = Model.getInstance().activeFrameData === _frameData;
			var colors:Array = isSelected ? [0xCACAFC, 0x9E9CC4] : [0xFCFCFC, 0xC2C0C1];
			
			graphics.beginGradientFill(GradientType.LINEAR, colors, [1, 1], [0, 255], gradientMatrix);
			graphics.drawRoundRect(0, 0, _frameData.repeatCount * 100, 50, 16, 16);
			
			width = _frameData.repeatCount * 100;
			height = 50;
			
			_tfTextureName.autoSize = TextFieldAutoSize.LEFT;
			_tfTextureName.text = _frameData.textureName + (isSelected ? "\n" + _frameData.repeatCount + " time(s)" : "");
			
			if (_tfTextureName.width > width - 20)
			{
				var tfHeight:Number = _tfTextureName.height;
				_tfTextureName.autoSize = TextFieldAutoSize.NONE;
				
				_tfTextureName.width = width - 20;
				_tfTextureName.height = tfHeight;
			}
			
			_tfTextureName.x = (width - _tfTextureName.width) / 2;
			_tfTextureName.y = (height - _tfTextureName.height) / 2; 
		}
		
		protected function onMouseClick(event:MouseEvent):void
		{
			Model.getInstance().setActiveFrame(_frameData);
		}
		
	}
}