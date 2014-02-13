package molehill.core.text
{
	import flash.geom.Point;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.base.BaseShaderPremultAlpha;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;

	public class TextField3D extends Sprite3DContainer
	{
		public function TextField3D()
		{
			super();
			
			_cacheSprites = new Vector.<Sprite3D>();

			shader = Shader3DFactory.getInstance().getShaderInstance(BaseShaderPremultAlpha);
		}
		
		public function get defaultTextFormat():TextField3DFormat
		{
			var format:TextField3DFormat = new TextField3DFormat();
			format.font = _fontName;
			format.align = _align;
			format.color = darkenColor;
			format.size = _fontSize;
			
			return format;
		}
		
		public function set defaultTextFormat(value:TextField3DFormat):void
		{
			_fontName = value.font;
			darkenColor = value.color;
			_align = value.align;
			_fontSize = value.size;
			_fontTextureSize = Font3DManager.getInstance().getSuitableFontSize(_fontName, value.size);
		}
		
		private var _fontName:String;
		private var _fontSize:int;
		private var _fontTextureSize:int;
		private var _align:String;
		
		private var _text:String = "";
		public function get text():String
		{
			return _text;
		}
		
		public function set text(value:String):void
		{
			_text = value;
			
			updateLayout();
		}
		
		private var _cacheSprites:Vector.<Sprite3D>;
		private function getCharacterSprite():Sprite3D
		{
			if (_cacheSprites.length > 0)
			{
				return _cacheSprites.pop();
			}
			
			return new Sprite3D();
		}
		
		private function updateLayout():void
		{
			var textLength:int = _text.length;
			var lineHeight:int = 0;
			var lineWidth:int = 0;
			var lineY:int = 0;
			var scale:Number = _fontSize / _fontTextureSize;
			
			_textWidth = 0;
			_textHeight = 0;
			
			var childIndex:int = 0;
			for (var i:int = 0; i < textLength; i++)
			{
				var charCode:int = _text.charCodeAt(i);
				if (charCode == 10 || charCode == 13)
				{
					if (_textWidth < lineWidth)
					{
						_textWidth = lineWidth;
					}
					
					lineY += lineHeight;
					lineHeight = 0;
					lineWidth = 0;
					continue;
				}
				
				var textureName:String = getTextureForChar(_fontName, _fontTextureSize, charCode);
				if (!TextureManager.getInstance().isTextureCreated(textureName))
				{
					charCode = 32;
					textureName = getTextureForChar(_fontName, _fontTextureSize, charCode);
				}
				
				var child:Sprite3D;
				if (childIndex < numChildren)
				{
					child = super.getChildAt(childIndex);
				}
				else
				{
					child = getCharacterSprite();
					super.addChild(child);
				}
				child.textureID = textureName;
				
				if (i == 0)
				{
					textureID = child.textureID;
				}
				
				var charTextureData:TextureData = TextureManager.getInstance().getTextureDataByID(textureName);
				child.textureRegion = TextureManager.getInstance().getTextureRegion(textureName);
				child.setSize(charTextureData.width * scale, charTextureData.height * scale);
				child.moveTo(lineWidth, lineY);
				
				lineWidth += Math.ceil(child.width);
				lineHeight = Math.max(lineHeight, Math.ceil(child.height));
				
				childIndex++;
			}
			
			if (_textWidth < lineWidth)
			{
				_textWidth = lineWidth;
			}
			_textHeight = lineY + lineHeight;
			
			while (numChildren > textLength)
			{
				_cacheSprites.push(super.removeChildAt(textLength - 1));
			}
			
			_containerRight = _containerX + _textWidth;
			_containerBottom = _containerY + _textHeight;
			
			_y1 = _containerBottom;
			
			_x2 = _containerRight
			_y2 = _containerBottom
			
			_x3 = _containerRight
		}
		
		override molehill_internal function updateDimensions(child:Sprite3D):void
		{
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
		}
		
		private static var _hashChars:Object = new Object();
		private static function getTextureForChar(font:String, size:uint, char:uint):String
		{
			if (_hashChars[font] == null)
			{
				_hashChars[font] = new Object();
			}
			if (_hashChars[font][size] == null)
			{
				_hashChars[font][size] = new Object();
			}
			if (_hashChars[font][size][char] == null)
			{
				_hashChars[font][size][char] = font + "_" + size + "_" + char;
			}
			
			return _hashChars[font][size][char];
		}
		
		private var _textWidth:Number = 0;
		override public function get width():Number
		{
			return _textWidth;
		}
		
		private var _textHeight:Number = 0;
		override public function get height():Number
		{
			return _textHeight;
		}
		
		// restrict any children manipulation
		override public function addChild(child:Sprite3D):Sprite3D
		{
			return null;
		}
		
		override public function addChildAt(child:Sprite3D, index:int):Sprite3D
		{
			return null;
		}
		
		override public function removeChild(child:Sprite3D):Sprite3D
		{
			return null;
		}
		
		override public function removeChildAt(index:int):Sprite3D
		{
			return null;
		}
		
		override public function getChildAt(index:int):Sprite3D
		{
			return null;
		}
		
		override public function getChildIndex(child:Sprite3D):int
		{
			return -1;
		}
		
		override public function contains(child:Sprite3D):Boolean
		{
			return false;
		}
		
		override public function getObjectsUnderPoint(point:Point, list:Vector.<Sprite3D>=null):Vector.<Sprite3D>
		{
			var objects:Vector.<Sprite3D> = super.getObjectsUnderPoint(point);
			if (objects.length > 0)
			{
				objects.splice(0, objects.length);
				objects.push(this);
			}
			
			return objects;
		}
		
		override molehill_internal function set parentShiftX(value:Number):void
		{
			_containerX = value;
			_containerRight = _containerX + _textWidth;
			
			_x0 = _containerX;
			_x1 = _containerX;
			_x2 = _containerRight
			_x3 = _containerRight
			
			super.parentShiftX = value;
		}
		
		override molehill_internal function set parentShiftY(value:Number):void
		{
			_containerY = value;
			_containerBottom = _containerY + _textHeight;
			
			_y0 = _containerY;
			_y1 = _containerBottom;
			_y2 = _containerBottom
			_y3 = _containerY;
			
			super.parentShiftY = value;
		}
		
	}
}