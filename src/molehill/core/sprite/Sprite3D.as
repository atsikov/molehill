package molehill.core.sprite
{
	import avmplus.getQualifiedClassName;
	
	import easy.collections.BinarySearchTreeNode;
	
	import flash.display.BitmapData;
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.Scene3DManager;
	import molehill.core.molehill_internal;
	import molehill.core.render.BlendMode;
	import molehill.core.render.Scene3D;
	import molehill.core.render.camera.CustomCamera;
	import molehill.core.render.engine.RenderEngine;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.mask.CutoutObjectShader;
	import molehill.core.render.shader.species.mask.MaskAlphaCutoutShader;
	import molehill.core.render.shader.species.mask.MaskedObjectShader;
	import molehill.core.sort.IZSortDisplayObject;
	import molehill.core.texture.NormalizedAlphaChannel;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureData;
	import molehill.core.texture.TextureManager;
	
	import utils.StringUtils;
	
	use namespace molehill_internal;
	
	public class Sprite3D extends EventDispatcher implements IZSortDisplayObject
	{
		public static function createFromTexture(textureID:String):Sprite3D
		{
			var sprite:Sprite3D = new Sprite3D();
			sprite.setTexture(textureID);
			
			return sprite;
		}
		
		public static const NUM_VERTICES_PER_SPRITE:uint = 4;
		
		public static const VERTICES_OFFSET:uint = 0;
		public static const COLOR_OFFSET:uint = 2; //3;
		public static const TEXTURE_OFFSET:uint = 6; //7;
		
		public static const NUM_ELEMENTS_PER_VERTEX:uint = 8; //9;
		
		public static const NUM_ELEMENTS_PER_SPRITE:uint = NUM_ELEMENTS_PER_VERTEX * NUM_VERTICES_PER_SPRITE;
		
		private static var TEXTURE_MANAGER:TextureManager = TextureManager.getInstance();
		
		/**
		 * 0--3     
		 * |  |
		 * 1--2
		 **/
		
		/**
		 * X Top-Left
		 **/
		molehill_internal var _x0:Number = 0;
		/**
		 * X Bottom-Left
		 **/
		molehill_internal var _x1:Number = 0;
		/**
		 * X Bottom-Right
		 **/
		molehill_internal var _x2:Number = 1;
		/**
		 * X Top-Right
		 **/
		molehill_internal var _x3:Number = 1;

		
		/**
		 * Y Top-Left
		 **/
		molehill_internal var _y0:Number = 1;
		/**
		 * Y Bottom-Left
		 **/
		molehill_internal var _y1:Number = 0;
		/**
		 * Y Bottom-Right
		 **/
		molehill_internal var _y2:Number = 0;
		/**
		 * Y Top-Right
		 **/
		molehill_internal var _y3:Number = 1;
		
		molehill_internal var _z0:Number = 0;
		molehill_internal var _z1:Number = 0;
		molehill_internal var _z2:Number = 0;
		molehill_internal var _z3:Number = 0;
		
		molehill_internal var _vertexX0:Number = 0;
		molehill_internal var _vertexX1:Number = 0;
		molehill_internal var _vertexX2:Number = 0;
		molehill_internal var _vertexX3:Number = 0;
		
		molehill_internal var _vertexY0:Number = 0;
		molehill_internal var _vertexY1:Number = 0;
		molehill_internal var _vertexY2:Number = 0;
		molehill_internal var _vertexY3:Number = 0;
		
		molehill_internal var _blankOffsetX:Number = 0;
		molehill_internal var _blankOffsetY:Number = 0;
		
		molehill_internal var _width:Number = 0;
		molehill_internal var _height:Number = 0;
		
		molehill_internal var _scene:Scene3D;
		public function get scene():Scene3D
		{
			return _scene;
		}
		
		molehill_internal function setScene(value:Scene3D):void
		{
			_scene = value;
			mask = _mask;
			cutout = _cutout;
			
			if (_scene != null)
			{
				onAddedToScene();
			}
			else
			{
				onRemovedFromScene();
			}
		}
		
		protected function onRemovedFromScene():void
		{
			// TODO Auto Generated method stub
			
		}
		
		protected function onAddedToScene():void
		{
			
		}
		
		public function Sprite3D()
		{
			super(this);
			
			resetSprite();
		}
		
		molehill_internal var _blendMode:String;

		public function get blendMode():String
		{
			return _blendMode;
		}

		public function set blendMode(value:String):void
		{
			if (value == BlendMode.NORMAL)
			{
				value = null;
			}
			
			_blendMode = value;
		}

		
		public function get x():Number
		{
			return _shiftX;
		}
		
		public function set x(value:Number):void
		{
			_shiftX = value;
			
			markChanged(true);
		}
		
		public function get y():Number
		{
			return _shiftY;
		}
		
		public function set y(value:Number):void
		{
			_shiftY = value;
			
			markChanged(true);
		}
		
		public function get z():Number
		{
			return _shiftZ;
		}
		
		public function get layerIndex():int
		{
			return 0;
		}
		
		private var _snapToPixels:Boolean = false;
		public function get snapToPixels():Boolean
		{
			return _snapToPixels;
		}
		
		public function set snapToPixels(value:Boolean):void
		{
			_snapToPixels = value;
		}
		
		molehill_internal var _parent:Sprite3DContainer;
		public function get parent():Sprite3DContainer
		{
			return _parent;
		}
		
		molehill_internal var _alpha:Number = 1;
		public function get alpha():Number
		{
			return _alpha;
		}
		
		public function set alpha(value:Number):void
		{
			/*
			if (value > 1)
			{
				value = 1;
			}
			*/
			if (value < 0)
			{
				value = 0;
			}
			
			if (_alpha == value)
			{
				return;
			}
			
			_alpha = value;
			
			_colorChanged = true;
			
			markChanged(true);
		}
		
		molehill_internal var _colorChanged:Boolean = true;
		
		private var _darkenColor:uint = 0xFFFFFF;
		public function get darkenColor():uint
		{
			return _darkenColor;
		}
		
		public function set darkenColor(value:uint):void
		{
			_darkenColor = value;
			
			_redMultiplier = (value >>> 16) / 0xFF;
			_greenMultiplier = ((value & 0xFFFF) >>> 8) / 0xFF;
			_blueMultiplier = (value & 0xFF) / 0xFF;
			
			_colorChanged = true;
			
			markChanged(true);
		}
		
		molehill_internal var _redMultiplier:Number = 1;
		public function get redMultiplier():Number
		{
			return _redMultiplier;
		}
		
		public function set redMultiplier(value:Number):void
		{
			if (value < 0)
			{
				value = 0;
			}
			
			if (_redMultiplier == value)
			{
				return;
			}
			
			_redMultiplier = value;
			_colorChanged = true;
			
			markChanged(true);
		}
		
		molehill_internal var _greenMultiplier:Number = 1;
		public function get greenMultiplier():Number
		{
			return _greenMultiplier;
		}
		
		public function set greenMultiplier(value:Number):void
		{
			if (value < 0)
			{
				value = 0;
			}
			
			if (_greenMultiplier == value)
			{
				return;
			}
			
			_greenMultiplier = value;
			_colorChanged = true;
			
			markChanged(true);
		}
		
		molehill_internal var _blueMultiplier:Number = 1;
		public function get blueMultiplier():Number
		{
			return _blueMultiplier;
		}
		
		public function set blueMultiplier(value:Number):void
		{
			if (value < 0)
			{
				value = 0;
			}
			
			if (_blueMultiplier == value)
			{
				return;
			}
			
			_blueMultiplier = value;
			_colorChanged = true;
			
			markChanged(true);
		}
		
		private var _textureID:String;
		public function get textureID():String
		{
			return _textureID;
		}
		
		public function get hasTexture():Boolean
		{
			return _textureID != "" && _textureID != null;
		}
		
		molehill_internal var currentAtlasData:TextureAtlasData;
		public function setTexture(value:String):void
		{
			if (_textureID != value || currentAtlasData == null)
			{
				var newAtlasData:TextureAtlasData = TEXTURE_MANAGER.getAtlasDataByTextureID(value);
				
				_textureID = value;
				
				if (_parent != null && currentAtlasData !== newAtlasData)
				{
					_parent.textureAtlasChanged = true;
					if (_scene != null)
					{
						_scene.needUpdateBatchers = true;
					}
				}
				
				currentAtlasData = newAtlasData;
			}
			
			if (currentAtlasData == null)
			{
				this.textureRegion = null;
				return;
			}
			
			var textureData:TextureData = currentAtlasData.getTextureData(_textureID);
			if (textureData == null)
			{
				return;
			}
			
			var textureRegion:Rectangle = currentAtlasData.getTextureRegion(_textureID);
			this.textureRegion = textureRegion;
			
			_blankOffsetX = textureData.blankOffsetX;
			_blankOffsetY = textureData.blankOffsetY;
			
			_width = textureData.width;
			_height = textureData.height;
			
			_croppedWidth = textureData.croppedWidth;
			_croppedHeight = textureData.croppedHeight;
			
			_cachedWidth = 0;
			_cachedHeight = 0;
			
			_cachedWidth = 0;
			_cachedHeight = 0;
			setSize(textureData.width * _scaleX, textureData.height * _scaleY);
		}
		
		private var _name:String;
		public function get name():String
		{
			return _name;
		}
		
		public function set name(value:String):void
		{
			_name = value;
		}
		
		molehill_internal var _parentShiftX:Number = 0;
		molehill_internal function set parentShiftX(value:Number):void
		{
			_parentShiftX = value;
			_valuesUpdated = false;
		}

		molehill_internal var _parentShiftY:Number = 0;
		molehill_internal function set parentShiftY(value:Number):void
		{
			_parentShiftY = value;
			_valuesUpdated = false;
		}

		molehill_internal var _parentShiftZ:Number = 0;
		molehill_internal function set parentShiftZ(value:Number):void
		{
			_parentShiftZ = value;
			_valuesUpdated = false;
		}

		
		molehill_internal var _parentScaleX:Number = 1;
		molehill_internal function set parentScaleX(value:Number):void
		{
			_parentScaleX = value;
			_valuesUpdated = false;
		}

		molehill_internal var _parentScaleY:Number = 1;
		molehill_internal function set parentScaleY(value:Number):void
		{
			_parentScaleY = value;
			_valuesUpdated = false;
		}

		molehill_internal var _parentRed:Number = 1;
		molehill_internal function set parentRed(value:Number):void
		{
			_parentRed = value;
			_colorChanged = true;
		}

		molehill_internal var _parentGreen:Number = 1;
		molehill_internal function set parentGreen(value:Number):void
		{
			_parentGreen = value;
			_colorChanged = true;
		}
		
		molehill_internal var _parentBlue:Number = 1;
		molehill_internal function set parentBlue(value:Number):void
		{
			_parentBlue = value;
			_colorChanged = true;
		}
		
		molehill_internal var _parentAlpha:Number = 1;
		molehill_internal function set parentAlpha(value:Number):void
		{
			_parentAlpha = value;
			_colorChanged = true;
		}
		
		molehill_internal var _parentRotation:Number = 0;
		molehill_internal var _parentRotationSin:Number = 0;
		molehill_internal var _parentRotationCos:Number = 0;
		molehill_internal function set parentRotation(value:Number):void
		{
			_parentRotation = value;
			
			_parentRotationSin = Math.sin(_parentRotation / 180 * Math.PI);
			_parentRotationCos = Math.cos(_parentRotation / 180 * Math.PI);
			_totalRotationSin = Math.sin((_rotation + _parentRotation) / 180 * Math.PI);
			_totalRotationCos = Math.cos((_rotation + _parentRotation) / 180 * Math.PI);
			
			_valuesUpdated = false;
		}
		
		molehill_internal function updateValues():void
		{
			if (_valuesUpdated)
			{
				return;

			}
			
			var scaledWidth:Number;
			var scaledHeight:Number;
			var cos:Number;
			var sin:Number;
			var parentCos:Number;
			var parentSin:Number;
			var dx0:Number;
			var dy0:Number;
			var dx:Number;
			var dy:Number;
		
			scaledWidth = _width * _parentScaleX * _scaleX;
			scaledHeight = _height * _parentScaleY * _scaleY;
			
			cos = _totalRotationCos;
			sin = _totalRotationSin;
			
			parentCos = _parentRotationCos;
			parentSin = _parentRotationSin;
			
			dx0 = _shiftX * _parentScaleX;
			dy0 = _shiftY * _parentScaleY;
			
			dx = _parentShiftX + dx0 * parentCos - dy0 * parentSin;
			dy = _parentShiftY + dx0 * parentSin + dy0 * parentCos;
			
			var x0:Number = -scaledHeight * sin + dx;
			var y0:Number = scaledHeight * cos + dy;
			
			var x1:Number = dx;
			var y1:Number = dy;
			
			var x2:Number = scaledWidth * cos + dx;
			var y2:Number = scaledWidth * sin + dy;
			
			var x3:Number = scaledWidth * cos - scaledHeight * sin + dx;
			var y3:Number = scaledWidth * sin + scaledHeight * cos + dy;
			
			_x0 = x0
			_y0 = y0;
			
			_x1 = x1;
			_y1 = y1;
			
			_x2 = x2;
			_y2 = y2;
			
			_x3 = x3;
			_y3 = y3;

			if (_croppedWidth == _width && _croppedHeight == _height)
			{
				if (_snapToPixels)
				{
					_vertexX0 = Math.round(x0);
					_vertexY0 = Math.round(y0);
					
					_vertexX1 = Math.round(x1);
					_vertexY1 = Math.round(y1);
					
					_vertexX2 = Math.round(x2);
					_vertexY2 = Math.round(y2);
					
					_vertexX3 = Math.round(x3);
					_vertexY3 = Math.round(y3);
				}
				else
				{
					_vertexX0 = x0;
					_vertexY0 = y0;
					
					_vertexX1 = x1;
					_vertexY1 = y1;
					
					_vertexX2 = x2;
					_vertexY2 = y2;
					
					_vertexX3 = x3;
					_vertexY3 = y3;
				}
			}
			else
			{
				var scaledCroppedWidth:Number = _croppedWidth * _parentScaleX * _scaleX;
				var scaledCroppedHeight:Number = _croppedHeight * _parentScaleY * _scaleY;
				
				var dx0Cropped:Number = dx0 + _blankOffsetX * _parentScaleX * _scaleX;
				var dy0Cropped:Number = dy0 + _blankOffsetY * _parentScaleY * _scaleY;
				
				var dxCropped:Number = _parentShiftX + dx0Cropped * parentCos - dy0Cropped * parentSin;
				var dyCropped:Number = _parentShiftY + dx0Cropped * parentSin + dy0Cropped * parentCos;
				
				if (_snapToPixels)
				{
					_vertexX0 = Math.round(-scaledCroppedHeight * sin + dxCropped);
					_vertexY0 = Math.round(scaledCroppedHeight * cos + dyCropped);
					
					_vertexX1 = Math.round(dxCropped);
					_vertexY1 = Math.round(dyCropped);
					
					_vertexX2 = Math.round(scaledCroppedWidth * cos + dxCropped);
					_vertexY2 = Math.round(scaledCroppedWidth * sin + dyCropped);
					
					_vertexX3 = Math.round(scaledCroppedWidth * cos - scaledCroppedHeight * sin + dxCropped);
					_vertexY3 = Math.round(scaledCroppedWidth * sin + scaledCroppedHeight * cos + dyCropped);
				}
				else
				{
					_vertexX0 = -scaledCroppedHeight * sin + dxCropped;
					_vertexY0 = scaledCroppedHeight * cos + dyCropped;
					
					_vertexX1 = dxCropped;
					_vertexY1 = dyCropped;
					
					_vertexX2 = scaledCroppedWidth * cos + dxCropped;
					_vertexY2 = scaledCroppedWidth * sin + dyCropped;
					
					_vertexX3 = scaledCroppedWidth * cos - scaledCroppedHeight * sin + dxCropped;
					_vertexY3 = scaledCroppedWidth * sin + scaledCroppedHeight * cos + dyCropped;
				}
			}
			
			_z0 = _shiftZ; 
			_z1 = _shiftZ; 
			_z2 = _shiftZ; 
			_z3 = _shiftZ;
			
			_valuesUpdated = true;
		}
		
		molehill_internal function updateParent(needUpdateParent:Boolean = true):void
		{
			if (_parent != null)
			{
				_parent.updateDimensions(this, needUpdateParent);
			}
		}
		
		molehill_internal var _shiftX:Number = 0;
		molehill_internal var _shiftY:Number = 0;
		molehill_internal var _shiftZ:Number = 0;
		public function moveTo(x:Number, y:Number, z:Number = 0):void
		{
			if (_shiftX == x && _shiftY == y && _shiftZ == z)
			{
				return;
			}
			
			_shiftX = x;
			_shiftY = y;
			_shiftZ = z;
			
			markChanged(true);
		}
		
		molehill_internal var _rotation:Number = 0;
		molehill_internal var _rotationSin:Number = 0;
		molehill_internal var _rotationCos:Number = 1;
		molehill_internal var _totalRotationSin:Number = 0;
		molehill_internal var _totalRotationCos:Number = 1;
		public function get rotation():Number
		{
			return _rotation;
		}
		
		public function set rotation(value:Number):void
		{
			if (_rotation == value)
			{
				return;
			}
			
			_rotation = value;
			
			_rotationSin = Math.sin(_rotation / 180 * Math.PI);
			_rotationCos = Math.cos(_rotation / 180 * Math.PI);
			_totalRotationSin = Math.sin((_rotation + _parentRotation) / 180 * Math.PI);
			_totalRotationCos = Math.cos((_rotation + _parentRotation) / 180 * Math.PI);
			
			markChanged(true);
		}
	
		protected var _croppedWidth:Number;
		molehill_internal var _cachedWidth:Number = 0;
		public function get width():Number
		{
			if (_cachedWidth == 0)
			{
				_cachedWidth = _width * _scaleX;
			}
			
			return _cachedWidth;
		}
		
		public function set width(value:Number):void
		{
			if (_cachedWidth == value)
			{
				return;
			}
			
			_scaleX = value / _width; 
			_cachedWidth = _width * _scaleX;
			
			markChanged(true);
		}
		
		protected var _croppedHeight:Number;
		molehill_internal var _cachedHeight:Number = 0;
		public function get height():Number
		{
			if (_cachedHeight == 0)
			{
				_cachedHeight = _height * _scaleY;
			}
			
			return _cachedHeight;
		}
		
		public function set height(value:Number):void
		{
			if (_cachedHeight == value)
			{
				return;
			}
			
			_scaleY = value / _height;
			_cachedHeight = _height * _scaleY;
			
			markChanged(true);
		}
		
		molehill_internal var _visible:Boolean = true;
		molehill_internal var _parentVisible:Boolean = true;
		molehill_internal function set parentVisible(value:Boolean):void
		{
			var currentVisibility:Boolean = visible;
			_parentVisible = value;
			_visibilityChanged ||= currentVisibility != visible;
		}
		
		public function get visible():Boolean 
		{
			return _visible && _parentVisible;
		}
		
		public function set visible(value:Boolean):void 
		{
			if (_visible == value)
			{
				return;
			}
			
			var currentVisibility:Boolean = visible;
			_visible = value;
			
			_visibilityChanged ||= currentVisibility != visible;
			
			_colorChanged &&= _visible;
			_textureChanged &&= _visible;
			_hasChanged &&= _visible;
		}
		
		public function setSize(w:Number, h:Number):void
		{
			if (_cachedWidth == w && _cachedHeight == h)
			{
				return;
			}
			
			if (_width == 0 || _height == 0 || _textureID == null)
			{
				_width = w;
				_height = h;
				
				_croppedWidth = w;
				_croppedHeight = h;
			}
			
			_scaleX = w / _width;
			_scaleY = h / _height;
			
			_cachedWidth = _width * _scaleX;
			_cachedHeight = _height * _scaleY;
			
			markChanged(true);
		}
		
		molehill_internal var _scaleX:Number = 1;
		public function get scaleX():Number
		{
			return _scaleX;
		}

		public function set scaleX(value:Number):void
		{
			if (_scaleX == value)
			{
				return;
			}
			
			_scaleX = value;
			_cachedWidth = _width * _scaleX;
			
			markChanged(true);
		}
		
		molehill_internal var _scaleY:Number = 1;
		public function get scaleY():Number
		{
			return _scaleY;
		}

		public function set scaleY(value:Number):void
		{
			if (_scaleY == value)
			{
				return;
			}
			
			_scaleY = value;
			_cachedHeight = _height * _scaleY;
			
			markChanged(true);
		}
		
		public function setScale(scaleX:Number, scaleY:Number):void
		{
			if (_scaleX == scaleX && _scaleY == scaleY)
			{
				return;
			}
			
			_scaleX = scaleX;
			_scaleY = scaleY;
			
			_cachedWidth = _width * _scaleX;
			_cachedHeight = _height * _scaleY;
			
			markChanged(true);
		}
		
		/**
		 * Resets all sprite's properties.
		 **/
		public function resetSprite():void
		{
			_shiftX = 0;
			_shiftY = 0;
			_croppedWidth = 1;
			_croppedHeight = 1;
			_scaleX = 1;
			_scaleY = 1;
			
			_x0 = 0;
			_x1 = 0;
			_x2 = 1;
			_x3 = 1;
			
			_y0 = 1;
			_y1 = 0;
			_y2 = 0;
			_y3 = 1;
			
			_z0 = 0;
			_z1 = 0;
			_z2 = 0;
			_z3 = 0;
			
			_redMultiplier = 1;
			_greenMultiplier = 1;
			_blueMultiplier = 1;
			_alpha = 1;
			
			_textureU0 = 0;
			_textureU1 = 0;
			_textureU2 = 1;
			_textureU3 = 1;
			
			_textureW0 = 1;
			_textureW1 = 0;
			_textureW2 = 0;
			_textureW3 = 1;
			
			_textureID = null;
			
			_cachedWidth = 0;
			_cachedHeight = 0;
			
			_width = 0;
			_height = 0;
			
			_visibilityChanged = !_visible;
			_visible = true;
			
			_mask = null;
			_cutout = null;
			
			_camera = null;
			
			_shader = null;
			_parentShader = null;
			_parentShaderChanged = true;
			
			_updateOnRender = false;
			//_notifyParentOnChange = true;
			
			_textureRegion = null;
			currentAtlasData = null;
			
			markChanged(true);
		}
		
		/**
		 * Method sets texture region from assigned texture data.
		 **/
		public function updateTextureRegion():void
		{
			textureRegion = TextureManager.getInstance().getTextureRegion(_textureID);
		}
		
		protected var _textureRegion:Rectangle;
		/**
		 * Defines rectangular texture region for sprite.
		 **/
		public function get textureRegion():Rectangle
		{
			return _textureRegion;
		}
		
		molehill_internal var _textureU0:Number = 0;
		molehill_internal var _textureU1:Number = 0;
		molehill_internal var _textureU2:Number = 0;
		molehill_internal var _textureU3:Number = 0;
		
		molehill_internal var _textureW0:Number = 0;
		molehill_internal var _textureW1:Number = 0;
		molehill_internal var _textureW2:Number = 0;
		molehill_internal var _textureW3:Number = 0;
		
		public function set textureRegion(value:Rectangle):void
		{
			if (_textureRegion != null &&
				value != null &&
				_textureRegion.equals(value))
			{
				return;
			}
			
			if (_textureRegion == null && value == null)
			{
				return;
			}
			
			if (_textureRegion == null)
			{
				_textureRegion = new Rectangle();
			}
			
			if (value == null)
			{
				_textureRegion.x = 0;
				_textureRegion.y = 0;
				_textureRegion.width = 0;
				_textureRegion.height = 0;
			}
			else
			{
				_textureRegion.x = value.x;
				_textureRegion.y = value.y;
				_textureRegion.width = value.width;
				_textureRegion.height = value.height;
			}
				
			_textureU0 = _textureRegion.x;
			_textureU1 = _textureRegion.x;
			_textureU2 = _textureRegion.x + _textureRegion.width;
			_textureU3 = _textureRegion.x + _textureRegion.width;
			
			_textureW0 = _textureRegion.y + _textureRegion.height;
			_textureW1 = _textureRegion.y;
			_textureW2 = _textureRegion.y;
			_textureW3 = _textureRegion.y + _textureRegion.height;
			
			_blankOffsetX = 0;
			_blankOffsetY = 0;
			
			_croppedWidth = _width;
			_croppedHeight = _height;
			
			_textureChanged = true;
		}
		
		/**
		 * Method to set non-rectangular texture region.
		 **/
		public function setCustomTextureRegion(x1:Number, y1:Number, x2:Number, y2:Number, x3:Number, y3:Number, x4:Number, y4:Number):void
		{
			_textureU0 = x1;
			_textureW0 = y1;
			_textureU1 = x2;
			_textureW1 = y2;
			_textureU2 = x3;
			_textureW2 = y3;
			_textureU3 = x4;
			_textureW3 = y4;
			
			_textureChanged = true;
		}
		/*
		public function moveVertex(vertexID:int, x:int, y:int, z:int = 0):void
		{
			switch (vertexID)
			{
				case 0:
					_x0 = x;
					_y0 = y;
					_z0 = z;
					break;
				case 1:
					_x1 = x;
					_y1 = y;
					_z1 = z;
					break;
				case 2:
					_x2 = x;
					_y2 = y;
					_z2 = z;
					break;
				case 3:
					_x3 = x;
					_y3 = y;
					_z3 = z;
					break;
			}
		}
		*/
		private var _mouseEnabled:Boolean = false;
		/**
		 * Determines if sprite collide with mouse or not.
		 **/
		public function get mouseEnabled():Boolean
		{
			return _mouseEnabled;
		}
		
		public function set mouseEnabled(value:Boolean):void
		{
			_mouseEnabled = value;
		}
		
		/**
		 * Basic function to check if point is inside sprite rect.
		 **/
		public function hitTestPoint(point:Point):Boolean
		{
			if (_scene == null)
			{
				return false;
			}
			
			var localX:Number = point.x - _parentShiftX;
			var localY:Number = point.y - _parentShiftY;
			
			var minX:Number = Math.min(
				_x0 < _x1 ? _x0 : _x1,
				_x2 < _x3 ? _x2 : _x3
			);
			var minY:Number = Math.min(
				_y0 < _y1 ? _y0 : _y1,
				_y2 < _y3 ? _y2 : _y3
			);
			var maxX:Number = Math.max(
				_x0 > _x1 ? _x0 : _x1,
				_x2 > _x3 ? _x2 : _x3
			);
			var maxY:Number = Math.max(
				_y0 > _y1 ? _y0 : _y1,
				_y2 > _y3 ? _y2 : _y3
			);
			
			minX -= _parentShiftX;
			maxX -= _parentShiftX;
			minY -= _parentShiftY;
			maxY -= _parentShiftY;
			
			if (_ignoreTransparentPixels)
			{
				if (isPixelTransparent(localX - _shiftX, localY - _shiftY))
				{
					return false;
				}
			}
			
			return	(minX <= localX) &&
				(maxX >= localX) &&
				(minY <= localY) &&
				(maxY >= localY);
		}
		
		molehill_internal function hitTestCoords(globalX:Number, globalY:Number):Boolean
		{
			if (_scene == null)
			{
				return false;
			}
			
			var localX:Number = globalX - _parentShiftX;
			var localY:Number = globalY - _parentShiftY;
			
			var minX:Number = Math.min(
				_x0 < _x1 ? _x0 : _x1,
				_x2 < _x3 ? _x2 : _x3
			);
			var minY:Number = Math.min(
				_y0 < _y1 ? _y0 : _y1,
				_y2 < _y3 ? _y2 : _y3
			);
			var maxX:Number = Math.max(
				_x0 > _x1 ? _x0 : _x1,
				_x2 > _x3 ? _x2 : _x3
			);
			var maxY:Number = Math.max(
				_y0 > _y1 ? _y0 : _y1,
				_y2 > _y3 ? _y2 : _y3
			);
			
			minX -= _parentShiftX;
			maxX -= _parentShiftX;
			minY -= _parentShiftY;
			maxY -= _parentShiftY;
			
			if (_ignoreTransparentPixels)
			{
				var rad:Number = (_rotation + _parentRotation) / 180 * Math.PI;
				
				var cos:Number;
				var sin:Number;
				var dx0:Number;
				var dy0:Number;
				var dx:Number;
				var dy:Number;
				
				cos = Math.cos(rad);
				sin = Math.sin(rad);
				
				dx0 = localX / _parentScaleX / _scaleX - _shiftX;
				dy0 = localY / _parentScaleY / _scaleY - _shiftY;
				
				dx = dx0 * cos - dy0 * sin;
				dy = dx0 * sin + dy0 * cos;
				
				if (isPixelTransparent(dx, dy))
				{
					return false;
				}
			}
			
			return	(minX <= localX) &&
				(maxX >= localX) &&
				(minY <= localY) &&
				(maxY >= localY);
		}
		
		/**
		 * If set to true, mouse won't be detected over transparent pixels 
		 **/
		private var _ignoreTransparentPixels:Boolean = false;
		public function get ignoreTransparentPixels():Boolean
		{
			return _ignoreTransparentPixels;
		}
		
		public function set ignoreTransparentPixels(value:Boolean):void
		{
			_ignoreTransparentPixels = value;
		}
		
		public function isPixelTransparent(localX:int, localY:int):Boolean
		{
			var rad:Number
			
			var totalRotation:Number = -_rotation - _parentRotation;
			rad = totalRotation == 0 ? 0 : totalRotation / 180 * Math.PI;
			
			var cos:Number;
			var sin:Number;
			var dx0:Number;
			var dy0:Number;
			var dx:Number;
			var dy:Number;
			
			cos = rad == 0 ? 1 : Math.cos(rad);
			sin = rad == 0 ? 0 : Math.sin(rad);
			
			if (_parentScaleX != 1 || _scaleX != 1)
			{
				dx0 = localX / _parentScaleX / _scaleX;
				
				if (dx0 < 0)
				{
					dx0 = _width + dx0;
				}
			}
			else
			{
				dx0 = localX;
			}
			
			if (_parentScaleY != 1 || _scaleY != 1)
			{
				dy0 = localY / _parentScaleY / _scaleY;
				
				if (dy0 < 0)
				{
					dy0 = _height + dy0;
				}
			}
			else
			{
				dy0 = localY;
			}
			
			dx = dx0 * cos - dy0 * sin;
			dy = dx0 * sin + dy0 * cos;
			
			if (currentAtlasData == null)
			{
				return dx < 0 || dy < 0 || dx > _width || dy > _height;
			}
			
			var textureData:TextureData = currentAtlasData.getTextureData(textureID);
			if (dx < textureData.blankOffsetX ||
				dy < textureData.blankOffsetY ||
				dx > textureData.blankOffsetX + textureData.croppedWidth ||
				dy > textureData.blankOffsetY + textureData.croppedHeight) 
			{
				return true;
			}
			
			var alphaData:NormalizedAlphaChannel = textureData.getNormalizedAlpha();
			if (alphaData == null)
			{
				var bitmapData:BitmapData = TextureManager.getInstance().getTextureBitmap(textureID);
				if (bitmapData == null)
				{
					return false;
				}
				
				var alphaValue:uint = bitmapData.getPixel32(textureData.left + dx, textureData.top + dy) >>> 24;
				
				return alphaValue == 0;
			}
			
			return !alphaData.hitTestPoint(dx, dy);
		}
		
		molehill_internal var _textureChanged:Boolean = false;
		
		molehill_internal var _visibilityChanged:Boolean = false;
		molehill_internal function resetVisibilityChanged():void
		{
			_visibilityChanged = false;
			
			var currentParent:Sprite3DContainer = _parent;
			while (currentParent != null && currentParent._visibilityChanged)
			{
				currentParent._visibilityChanged = false;
				currentParent = currentParent._parent;
			}
		}
	
		/*
		molehill_internal function get hasChanged():Boolean
		{
			return _hasChanged;
		}
		*/
		private var _updateOnRender:Boolean;
		molehill_internal var updateOnRenderChanged:Boolean = false;
		public function get updateOnRender():Boolean
		{
			return _updateOnRender;
		}
		
		public function set updateOnRender(value:Boolean):void
		{
			_updateOnRender = value;
			
			updateOnRenderChanged = true;
		}
		/*
		private var _notifyParentOnChange:Boolean;
		molehill_internal var notifyParentChanged:Boolean = false;
		public function get notifyParentOnChange():Boolean
		{
			return _notifyParentOnChange;
		}
		
		public function set notifyParentOnChange(value:Boolean):void
		{
			_notifyParentOnChange = value;
			
			notifyParentChanged = true;
		}
		*/
		private var _hasChanged:Boolean = true;
		molehill_internal function get hasChanged():Boolean
		{
			return _hasChanged;
		}
		
		private var _valuesUpdated:Boolean = false;
		molehill_internal function markChanged(value:Boolean, needUpdateParent:Boolean = true):void
		{
			_hasChanged = value;
			
			_valuesUpdated &&= !value;
			if (_updateOnRender)
			{
				return;
			}
			
			if (_hasChanged)
			{
				updateValues();
				
				updateParent(needUpdateParent);
			}
		}
		
		molehill_internal var addedToScene:Boolean = false;
		molehill_internal var syncedInUIComponent:Boolean = false;
		molehill_internal var _parentShaderChanged:Boolean = false;
		molehill_internal function set parentShaderChanged(value:Boolean):void
		{
			_parentShaderChanged = value;
		}
		
		private var _shader:Shader3D;
		private var _parentShader:Shader3D;
		/**
		 * Shader program to be used with this sprite.
		 **/
		public function get shader():Shader3D
		{
			if (_parentShaderChanged)
			{
				_parentShader == null;
				var currentParent:Sprite3D = parent;
				while (currentParent != null)
				{
					if (currentParent.shader != null)
					{
						_parentShader = currentParent.shader;
					}
					
					currentParent = currentParent.parent;
				}
				
				_parentShaderChanged = false;
			}
			
			return _parentShader != null ? _parentShader : _shader;
		}

		public function set shader(value:Shader3D):void
		{
			if (_shader !== value && _scene != null)
			{
				_scene.needUpdateBatchers = true;
			}
			
			_shader = value;
		}
		private var _mask:Sprite3D;
		/**
		 * Object to be used as normal mask. Pixels where mask alpha == 0 won't be drawn.
		 **/
		public function get mask():Sprite3D
		{
			return _mask;
		}
		
		public function set mask(value:Sprite3D):void
		{
			if (_scene != null)
			{
				if (_mask != null)
				{
					_mask.shader = null;
				}
				
				if (value != null)
				{
					value.shader = Shader3DFactory.getInstance().getShaderInstance(MaskAlphaCutoutShader);
					shader = Shader3DFactory.getInstance().getShaderInstance(MaskedObjectShader);
				}
			}
			
			if (value == null && _mask != null)
			{
				_mask.shader = null;
				shader = null;
			}
			
			_mask = value;
		}
		
		private var _cutout:Sprite3D;
		/**
		 * Object to be used as cutout mask. Pixels where mask alpha > 0 won't be drawn.
		 **/
		public function get cutout():Sprite3D
		{
			return _cutout;
		}
		
		public function set cutout(value:Sprite3D):void
		{
			if (_scene != null)
			{
				if (_cutout != null)
				{
					_cutout.shader = null;
				}
				
				if (value != null && Scene3DManager.getInstance().renderEngine != null)
				{
					value.shader = Shader3DFactory.getInstance().getShaderInstance(MaskAlphaCutoutShader);
					shader = Shader3DFactory.getInstance().getShaderInstance(CutoutObjectShader);
				}
			}
			
			if (value == null && _cutout != null)
			{
				_cutout.shader = null;
				shader = null;
			}
			
			_cutout = value;
		}
		
		molehill_internal var parentMinXNode:BinarySearchTreeNode;
		molehill_internal var parentMinYNode:BinarySearchTreeNode;
		molehill_internal var parentMaxXNode:BinarySearchTreeNode;
		molehill_internal var parentMaxYNode:BinarySearchTreeNode;
		
		private var _camera:CustomCamera = null;
		/**
		 * Scale factor applyed while rendering sprite
		 **/
		public function get camera():CustomCamera
		{
			return _camera;
		}
		
		molehill_internal var cameraChanged:Boolean = false;
		public function set camera(value:CustomCamera):void
		{
			if (_camera == null)
			{
				_camera = value;
				if (_scene != null)
				{
					cameraChanged = true;
					_scene.needUpdateBatchers = true;
				}
			}
			else if (value == null)
			{
				_camera = null;
				if (_scene != null)
				{
					cameraChanged = true;
					_scene.needUpdateBatchers = true;
				}
			}
			else
			{
				_camera.scale = value.scale;
				_camera.scrollX = value.scrollX;
				_camera.scrollY = value.scrollY;
			}
		}
		
		override public function toString():String
		{
			var className:String = getQualifiedClassName(this);
			return className + " @ " + StringUtils.getObjectAddress(this) + " texture: " + textureID + "; shader: " + shader;
		}
		
		/**
		 * Translates coordinates from local to global coordinate system.
		 * <b>Modifies passed parameter!</b>
		 * 
		 * @param point Point from local coordinate space to be transfered into global space
		 **/
		public function localToGlobal(point:Point):void
		{
			point.x *= _scaleX;
			point.y *= _scaleY;
			
			point.offset(
				_parentShiftX + _shiftX * _parentScaleX,
				_parentShiftY + _shiftY * _parentScaleY
			);
			
			var cameraOwner:Sprite3D = this;
			while (cameraOwner != null)
			{
				if (cameraOwner.camera != null)
				{
					point.x *= cameraOwner.camera.scale;
					point.y *= cameraOwner.camera.scale;
					
					point.offset(-cameraOwner.camera.scrollX, -cameraOwner.camera.scrollY);
				}
				cameraOwner = cameraOwner.parent;
			}
		}
		
		/**
		 * Translates coordinates from global to local coordinate system.
		 * <b>Modifies passed parameter!</b>
		 * 
		 * @param point Point from global coordinate space to be transfered into local space
		 **/
		public function globalToLocal(point:Point):void
		{
			globalToLocalCoords(point.x, point.y);
			
			point.x = _localPointX;
			point.y = _localPointY;
		}
		
		private var _localPointX:Number;
		private var _localPointY:Number;
		
		private var _listParents:Vector.<Sprite3D>;
		//private var _listParents:Object;
		private function globalToLocalCoords(globalX:Number, globalY:Number):void
		{
			var numParents:int = 0;
			var listLength:int = _listParents != null ? _listParents.length : 10;
			var spriteParent:Sprite3D = this;
			while (spriteParent.parent != null)
			{
				if (_listParents == null)
				{
					_listParents = new Vector.<Sprite3D>(10);
					_listParents.fixed = true;
					//_listParents = new Object();
				}
				
				if (numParents == listLength)
				{
					_listParents.fixed = false;
					_listParents.length += 10;
					_listParents.fixed = true;
				}
				
				_listParents[numParents] = spriteParent;
				
				spriteParent = spriteParent.parent;
				numParents++;
			}
			
			var rad:Number;
			
			var cos:Number;
			var sin:Number;
			var dx0:Number;
			var dy0:Number;
			var dx:Number;
			var dy:Number;
			
			if (_listParents != null)
			{
				for (var i:int = numParents - 1; i >= 0; i--)
				{
					spriteParent = _listParents[i];
					
					var currentCamera:CustomCamera = spriteParent.camera;
					if (currentCamera != null)
					{
						globalX += currentCamera.scrollX;
						globalY += currentCamera.scrollY;
						
						globalX /= currentCamera.scale;
						globalY /= currentCamera.scale;
					}
					
					globalX -= spriteParent._shiftX;
					globalY -= spriteParent._shiftY;
					
					rad = -spriteParent._rotation / 180 * Math.PI;
					
					
					cos = rad == 0 ? 1 : Math.cos(rad);
					sin = rad == 0 ? 0 : Math.sin(rad);
					
					dx0 = globalX / spriteParent._scaleX;
					dy0 = globalY / spriteParent._scaleY;
					
					globalX = dx0 * cos - dy0 * sin;
					globalY = dx0 * sin + dy0 * cos;
				}
			}
			/*
			globalX -= _shiftX;
			globalY -= _shiftY;
			
			rad = -_rotation / 180 * Math.PI;
			
			cos = rad == 0 ? 1 : Math.cos(rad);
			sin = rad == 0 ? 0 : Math.sin(rad);
			
			dx0 = globalX / _scaleX;
			dy0 = globalY / _scaleY;
			
			globalX = dx0 * cos - dy0 * sin;
			globalY = dx0 * sin + dy0 * cos;
			*/
			_localPointX = globalX;
			_localPointY = globalY;
		}
		
		molehill_internal function get isOnScreen():Boolean
		{
			var renderEngine:RenderEngine = Scene3DManager.getInstance().renderEngine;
			
			globalToLocalCoords(0, 0);
			if (_localPointX > width || _localPointY > height)
			{
				return false;
			}
			
			globalToLocalCoords(renderEngine.getViewportWidth(), renderEngine.getViewportHeight());
			if (_localPointX < 0 || _localPointY < 0)
			{
				return false;
			}
			
			return true;
		}
	}
}