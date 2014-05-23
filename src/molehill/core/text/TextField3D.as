package molehill.core.text
{
	import flash.geom.Point;
	
	import molehill.core.molehill_internal;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.base.BaseShaderPremultAlpha;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	use namespace molehill_internal;

	public class TextField3D extends Sprite3DContainer
	{
		public function TextField3D()
		{
			super();
			
			_cacheSprites = new Vector.<TextField3DCharacter>();

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
			
			updateLayout();
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
		
		private var _cacheSprites:Vector.<TextField3DCharacter>;
		private function getCharacterSprite():TextField3DCharacter
		{
			if (_cacheSprites.length > 0)
			{
				return _cacheSprites.pop();
			}
			
			return new TextField3DCharacter();
		}
		
		protected var _hashSymbolsByLine:Object;
		protected var _numLines:uint = 0;
		private var _lastChild:Sprite3D;
		private function updateLayout():void
		{
			var textLength:int = _text.length;
			var lineHeight:int = 0;
			var lineWidth:int = 0;
			var lineY:int = 0;
			var scale:Number = _fontSize / _fontTextureSize;
			
			_hashSymbolsByLine = new Object();
			_numLines = 1;
			
			_textWidth = 0;
			_textHeight = 0;
			
			_notifyParentOnChange = false;
			
			if (_scene != null)
			{
				var updateBatchersFlag:Boolean = _scene._needUpdateBatchers;
			}
			
			var charAtlasData:TextureAtlasData;
			var childIndex:int = 0;
			var numGlyphs:int = 0;
			var lineStart:int = 0;
			var placedChildIndex:int = 0;
			for (var i:int = 0; i < textLength; i++)
			{
				var charCode:int = _text.charCodeAt(i);
				if (charCode == 10 || charCode == 13)
				{
					if (_textWidth < lineWidth)
					{
						_textWidth = lineWidth;
					}
					
					switch (_align)
					{
						case TextField3DAlign.LEFT:
							lineStart = 0;
							break;
						case TextField3DAlign.RIGHT:
							lineStart = -lineWidth;
							break;
						case TextField3DAlign.CENTER:
							lineStart = -lineWidth / 2;
							break;
						default:
							lineStart = 0;
							break;
					}
					
					for (var j:int = placedChildIndex; j < childIndex; j++)
					{
						child = super.getChildAt(j) as TextField3DCharacter;
						child.moveTo(lineStart, lineY);
						lineStart += Math.ceil(child.width);
					}
					
					lineY += lineHeight;
					lineHeight = 0;
					lineWidth = 0;
					
					placedChildIndex = childIndex;
					
					_numLines++;
					
					continue;
				}
				
				var textureName:String = getTextureForChar(_fontName, _fontTextureSize, charCode);
				if (charAtlasData == null)
				{
					charAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(textureName);
				}
				
				if (charAtlasData == null)
				{
					charCode = 32;
					textureName = getTextureForChar(_fontName, _fontTextureSize, charCode);
					
					charAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(textureName);
				}
				
				var charTextureData:TextureData = charAtlasData.getTextureData(textureName);
				
				if (charTextureData == null)
				{
					charCode = 32;
					textureName = getTextureForChar(_fontName, _fontTextureSize, charCode);
					
					charTextureData = charAtlasData.getTextureData(textureName);
				}
				
				var child:TextField3DCharacter;
				if (childIndex < numChildren)
				{
					child = super.getChildAt(childIndex) as TextField3DCharacter;
				}
				else
				{
					child = getCharacterSprite();
					super.addChild(child);
					
					updateBatchersFlag = true;
				}
				
				child.setTexture(textureName);
				child.setSize(charTextureData.width * scale, charTextureData.height * scale);
				
				lineWidth += Math.ceil(child.width);
				lineHeight = Math.max(lineHeight, Math.ceil(child.height));
				
				childIndex++;
				
				_hashSymbolsByLine[_numLines - 1] = uint(_hashSymbolsByLine[_numLines - 1]) + 1;
			}
			
			switch (_align)
			{
				case TextField3DAlign.LEFT:
					lineStart = 0;
					break;
				case TextField3DAlign.RIGHT:
					lineStart = -lineWidth;
					break;
				case TextField3DAlign.CENTER:
					lineStart = -lineWidth / 2;
					break;
				default:
					lineStart = 0;
					break;
			}
			
			for (i = placedChildIndex; i < childIndex; i++)
			{
				child = super.getChildAt(i) as TextField3DCharacter;
				child.moveTo(lineStart, lineY);
				lineStart += Math.ceil(child.width);
			}
			
			if (_textWidth < lineWidth)
			{
				_textWidth = lineWidth;
			}
			_textHeight = lineY + lineHeight;
			
			while (numChildren > childIndex)
			{
				_cacheSprites.push(super.removeChildAt(numChildren - 1));
				
				treeStructureChanged = true;
				updateBatchersFlag = true;
			}
			
			_lastChild = numChildren > 0 ? super.getChildAt(numChildren - 1) : null;
				
			
			if (_scene != null)
			{
				// do not need to update batcher cause we assume that all fonts for one textfield are on the same atlas
				_scene._needUpdateBatchers = updateBatchersFlag;
			}
			
			treeStructureChanged ||= textureAtlasChanged;
			_notifyParentOnChange = true;
			updateDimensions(this);
		}
		
		private var _notifyParentOnChange:Boolean = true;
		override molehill_internal function updateDimensions(child:Sprite3D, needUpdateParent:Boolean=true):void
		{
			if (!_notifyParentOnChange)
			{
				return;
			}
			
			if (child !== _lastChild)
			{
				return;
			}
			
			_containerX = _shiftX * _parentScaleX + _parentShiftX;
			_containerRight = _containerX + _textWidth;
			
			_x0 = _containerX;
			_x1 = _containerX;
			_x2 = _containerRight
			_x3 = _containerRight
			
			_containerRight = _containerX + _textWidth;
			_containerBottom = _containerY + _textHeight;
			
			_containerY = _shiftY + _parentShiftY * _parentScaleY;
			_containerBottom = _containerY + _textHeight;
			
			_y0 = _containerY;
			_y1 = _containerBottom;
			_y2 = _containerBottom
			_y3 = _containerY;
			
			if (_parent != null && needUpdateParent)
			{
				_parent.updateDimensions(this, needUpdateParent);
			}
		}
		
		private static var _hashChars:Object = new Object();
		private static function getTextureForChar(font:String, size:uint, char:uint):String
		{
			var fontObject:Object = _hashChars[font];
			if (fontObject == null)
			{
				fontObject = new Object();
				_hashChars[font] = fontObject;
			}
			
			var sizeObject:Object = fontObject[size];
			if (sizeObject == null)
			{
				sizeObject = new Object();
				fontObject[size] = sizeObject;
			}
			
			var charTexture:String = sizeObject[char];
			if (charTexture == null)
			{
				charTexture = font + "_" + size + "_" + char;
				sizeObject[char] = charTexture;
			}
			
			return charTexture;
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
		
		// TODO: add new characters instead of performing full update
		public function appendText(text:String):void
		{
			_text += text;
			updateLayout();
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
			var listLength:int = list == null ? 0 : list.length;
			list = super.getObjectsUnderPoint(point, list);
			if (list.length > listLength)
			{
				list.splice(listLength, list.length - listLength);
				list.push(this);
			}
			
			return list;
		}
		
		override molehill_internal function set parentShiftX(value:Number):void
		{
			_containerX = _shiftX + value;
			_containerRight = _containerX + _textWidth;
			
			_x0 = _containerX;
			_x1 = _containerX;
			_x2 = _containerRight
			_x3 = _containerRight
			
			super.parentShiftX = value;
		}
		
		override molehill_internal function set parentShiftY(value:Number):void
		{
			_containerY = _shiftY + value;
			_containerBottom = _containerY + _textHeight;
			
			_y0 = _containerY;
			_y1 = _containerBottom;
			_y2 = _containerBottom
			_y3 = _containerY;
			
			super.parentShiftY = value;
		}
		
		override molehill_internal function markChanged(value:Boolean, updateParent:Boolean=true):void
		{
			super.markChanged(value);
			
			if (hasChanged)
			{
				updateDimensions(this);
			}
		}
	}
}