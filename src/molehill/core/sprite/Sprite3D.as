package molehill.core.sprite
{
	import avmplus.getQualifiedClassName;
	
	import easy.collections.BinarySearchTreeNode;
	
	import flash.events.EventDispatcher;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.Scene3DManager;
	import molehill.core.molehill_internal;
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.mask.CutoutObjectShader;
	import molehill.core.render.shader.species.mask.MaskAlphaCutoutShader;
	import molehill.core.render.shader.species.mask.MaskedObjectShader;
	import molehill.core.sort.IZSortDisplayObject;
	import molehill.core.texture.TextureAtlasData;
	import molehill.core.texture.TextureManager;
	
	import utils.StringUtils;
	import molehill.core.render.BlendMode;
	import molehill.core.render.Scene3D;
	
	use namespace molehill_internal;
	
	public class Sprite3D extends EventDispatcher implements IZSortDisplayObject
	{
		public static function createFromTexture(textureID:String):Sprite3D
		{
			var sprite:Sprite3D = new Sprite3D();
			sprite.textureID = textureID;
			sprite.textureRegion = TextureManager.getInstance().getTextureRegion(textureID);
			
			var rect:Rectangle = TextureManager.getInstance().getBitmapRectangleByID(textureID);
			sprite.setSize(rect.width, rect.height);
			
			return sprite;
		}
		
		public static const NUM_VERTICES_PER_SPRITE:uint = 4;
		
		public static const VERTICES_OFFSET:uint = 0;
		public static const COLOR_OFFSET:uint = 3;
		public static const TEXTURE_OFFSET:uint = 7;
		
		public static const NUM_ELEMENTS_PER_VERTEX:uint = 9;
		
		public static const NUM_ELEMENTS_PER_SPRITE:uint = NUM_ELEMENTS_PER_VERTEX * NUM_VERTICES_PER_SPRITE;
		
		private static var SCENE_MANAGER:Scene3DManager = Scene3DManager.getInstance();
		
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
		
		molehill_internal var _scene:Scene3D;
		public function getScene():Scene3D
		{
			return _scene;
		}
		
		molehill_internal function setScene(value:Scene3D):void
		{
			_scene = value;
			mask = _mask;
			cutout = _cutout;
			
			_parent
			
			if (_scene != null)
			{
				onAddedToScene();
			}
		}
		
		protected function onAddedToScene():void
		{
			
		}
		
		public function Sprite3D()
		{
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
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		public function get y():Number
		{
			return _shiftY;
		}
		
		public function set y(value:Number):void
		{
			_shiftY = value;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		public function get z():Number
		{
			return _shiftZ;
		}
		
		public function get layerIndex():int
		{
			return 0;
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
			
			hasChanged = true;
		}
		
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
			
			hasChanged = true;
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
			
			hasChanged = true;
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
			
			hasChanged = true;
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
			
			hasChanged = true;
		}
		
		private var _textureID:String;
		public function get textureID():String
		{
			return _textureID;
		}
		
		public function set textureID(value:String):void
		{
			if (_textureID == value)
			{
				return;
			}
			
			var prevAtlasData:TextureAtlasData = TextureManager.getInstance().getAtlasDataByTextureID(_textureID);
			_textureID = value;
			
			if (_scene != null)
			{
				_scene._needUpdateBatchers = true;
			}
			
			if (_parent != null && prevAtlasData !== TextureManager.getInstance().getAtlasDataByTextureID(_textureID))
			{
				_parent.textureAtlasChanged = true;
			}
		}
		
		public function get hasTexture():Boolean
		{
			return _textureID != "" && _textureID != null;
		}
		
		molehill_internal var _parentShiftX:Number = 0;
		molehill_internal function set parentShiftX(value:Number):void
		{
			_parentShiftX = value;
		}

		molehill_internal var _parentShiftY:Number = 0;
		molehill_internal function set parentShiftY(value:Number):void
		{
			_parentShiftY = value;
		}

		molehill_internal var _parentShiftZ:Number = 0;
		molehill_internal function set parentShiftZ(value:Number):void
		{
			_parentShiftZ = value;
		}

		
		molehill_internal var _parentScaleX:Number = 1;
		molehill_internal function set parentScaleX(value:Number):void
		{
			_parentScaleX = value;
		}

		molehill_internal var _parentScaleY:Number = 1;
		molehill_internal function set parentScaleY(value:Number):void
		{
			_parentScaleY = value;
		}

		molehill_internal var _parentRed:Number = 1;
		molehill_internal function set parentRed(value:Number):void
		{
			_parentRed = value;
		}

		molehill_internal var _parentGreen:Number = 1;
		molehill_internal function set parentGreen(value:Number):void
		{
			_parentGreen = value;
		}
		
		molehill_internal var _parentBlue:Number = 1;
		molehill_internal function set parentBlue(value:Number):void
		{
			_parentBlue = value;
		}
		
		molehill_internal var _parentAlpha:Number = 1;
		molehill_internal function set parentAlpha(value:Number):void
		{
			_parentAlpha = value;
		}
		
		molehill_internal var _parentRotation:Number = 0;
		molehill_internal function set parentRotation(value:Number):void
		{
			_parentRotation = value;
		}
		
		molehill_internal function updateParentShiftAndScale():void
		{
			if (_parent == null || !_parent._hasChanged)
			{
				return;
			}
			
			_parentShiftX += _parent._shiftX;
			_parentShiftY += _parent._shiftY;
			_parentShiftZ += _parent._shiftZ;
			
			_parentScaleX *= _parent._scaleX;
			_parentScaleY *= _parent._scaleY;
			
			_parentRed *= _parent._redMultiplier;
			_parentGreen *= _parent._greenMultiplier;
			_parentBlue *= _parent._blueMultiplier;
			_parentAlpha *= _parent._alpha;
			
			_parentRotation += _parent._rotation;
			
			_parent.updateDimensions(this);
		}
		
		molehill_internal function updateValues():void
		{
			//updateParentShiftAndScale();
			
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
			
			var scaledWidth:Number;
			var scaledHeight:Number;
			var cos:Number;
			var sin:Number;
			var dx:Number;
			var dy:Number;
			if (!_fromMatrix)
			{
				scaledWidth = _width * _parentScaleX * _scaleX;
				scaledHeight = _height * _parentScaleY * _scaleY;
				
				var rad:Number = (_rotation + _parentRotation) / 180 * Math.PI;
				cos = Math.cos(rad);
				sin = Math.sin(rad);
				
				dx = _parentShiftX + _shiftX * _parentScaleX;
				dy = _parentShiftY + _shiftY * _parentScaleY;
				
				_x0 = -scaledHeight * sin + dx;
				_y0 = scaledHeight * cos + dy;
				
				_x1 = dx;
				_y1 = dy;
				
				_x2 = scaledWidth * cos + dx;
				_y2 = scaledWidth * sin + dy;
				
				_x3 = scaledWidth * cos - scaledHeight * sin + dx;
				_y3 = scaledWidth * sin + scaledHeight * cos + dy;
			}
			else
			{
				dx = _matrix.tx;
				dy = _matrix.ty;
				
				_x0 = -_height * _matrix.c + dx;
				_y0 = _height * _matrix.d + dy;
				
				_x1 = dx;
				_y1 = dy;
				
				_x2 = _width * _matrix.a + dx;
				_y2 = _width * _matrix.b + dy;
				
				_x3 = _width * _matrix.a - _height * _matrix.c + dx;
				_y3 = _width * _matrix.b + _height * _matrix.d + dy;
			}
			
			_z0 = _shiftZ; 
			_z1 = _shiftZ; 
			_z2 = _shiftZ; 
			_z3 = _shiftZ;
		}
		
		public function applySize():void
		{
			updateValues();
			if (_parent != null)
			{
				_parent.updateDimensions(this);
			}
		}
		
		private var _matrix:Object = {'a': 1, 'b': 0, 'c': 0, 'd': 1, 'tx': 0, 'ty': 0};
		private var _fromMatrix:Boolean = false;
		public function applyMatrix(a:Number, b:Number, c:Number, d:Number, tx:Number, ty:Number):void
		{
			_matrix.a = a;
			_matrix.b = b;
			_matrix.c = c;
			_matrix.d = d;
			_matrix.tx = tx;
			_matrix.ty = ty;
			
			_fromMatrix = true;
		}
		
		molehill_internal var _shiftX:Number = 0;
		molehill_internal var _shiftY:Number = 0;
		molehill_internal var _shiftZ:Number = 0;
		public function moveTo(x:Number, y:Number, z:Number = 0):void
		{
			_shiftX = x;
			_shiftY = y;
			_shiftZ = z;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		molehill_internal var _rotation:Number = 0;
		public function get rotation():Number
		{
			return _rotation;
		}
		
		public function set rotation(value:Number):void
		{
			_fromMatrix = false;
			
			_rotation = value;
			
			hasChanged = true;
		}
	
		protected var _width:Number;
		molehill_internal var _cachedWidth:Number = 0;
		public function get width():Number
		{
			return _cachedWidth;
		}
		
		public function set width(value:Number):void
		{
			_width = value;
			_cachedWidth = _width * _scaleX;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		protected var _height:Number;
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
			_height = value;
			_cachedHeight = _height * _scaleY;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		molehill_internal var _visible:Boolean = true;
		public function get visible():Boolean 
		{
			var currentParent:Sprite3DContainer = _parent;
			while (currentParent != null)
			{
				if (!currentParent._visible)
				{
					return false;
				}
				
				currentParent = currentParent._parent;
			}
			
			return _visible;
		}
		
		public function set visible(value:Boolean):void 
		{
			if (_visible == value)
			{
				return;
			}
			
			_visible = value;
			
			_visibilityChanged = true;
		}
		
		public function setSize(w:Number, h:Number):void
		{
			_width = w;
			_height = h;
			
			_cachedWidth = _width * _scaleX;
			_cachedHeight = _height * _scaleY;
			
			hasChanged = true;
		}
		
		molehill_internal var _scaleX:Number = 1;
		public function get scaleX():Number
		{
			return _scaleX;
		}

		public function set scaleX(value:Number):void
		{
			_scaleX = value;
			_cachedWidth = _width * _scaleX;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		molehill_internal var _scaleY:Number = 1;
		public function get scaleY():Number
		{
			return _scaleY;
		}

		public function set scaleY(value:Number):void
		{
			_scaleY = value;
			_cachedHeight = _height * _scaleY;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		public function setScale(scaleX:Number, scaleY:Number):void
		{
			_scaleX = scaleX;
			_scaleY = scaleY;
			
			_cachedWidth = _width * _scaleX;
			_cachedHeight = _height * _scaleY;
			
			_fromMatrix = false;
			
			hasChanged = true;
		}
		
		public function resetSprite():void
		{
			_shiftX = 0;
			_shiftY = 0;
			_width = 1;
			_height = 1;
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
			
			hasChanged = true;
		}
		
		public function updateTextureRegion():void
		{
			textureRegion = TextureManager.getInstance().getTextureRegion(_textureID);
		}
		
		protected var _textureRegion:Rectangle;
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
			
			_textureRegion.x = value.x;
			_textureRegion.y = value.y;
			_textureRegion.width = value.width;
			_textureRegion.height = value.height;
			
			_textureU0 = _textureRegion.x;
			_textureU1 = _textureRegion.x;
			_textureU2 = _textureRegion.x + _textureRegion.width;
			_textureU3 = _textureRegion.x + _textureRegion.width;
			
			_textureW0 = _textureRegion.y + _textureRegion.height;
			_textureW1 = _textureRegion.y;
			_textureW2 = _textureRegion.y;
			_textureW3 = _textureRegion.y + _textureRegion.height;
			
			_textureChanged = true;
		}
		
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
		public function get mouseEnabled():Boolean
		{
			return _mouseEnabled;
		}
		
		public function set mouseEnabled(value:Boolean):void
		{
			_mouseEnabled = value;
		}
		
		public function hitTestPoint(point:Point):Boolean
		{
			var localMouseX:Number = point.x;
			var localMouseY:Number = point.y;
			var a:int = Math.min(_shiftX, _shiftX + _cachedWidth);
			var b:int = Math.max(_shiftX, _shiftX + _cachedWidth);
			var c:int = Math.min(_shiftY, _shiftY + _cachedHeight);
			var d:int = Math.max(_shiftY, _shiftY + _cachedHeight);
			return	(a <= localMouseX) &&
				(b >= localMouseX) &&
				(c <= localMouseY) &&
				(d >= localMouseY);
		}
		
		molehill_internal function hitTestCoords(localX:Number, localY:Number):Boolean
		{
			if (_scene == null)
			{
				return false;
			}
			
			var localMouseX:Number = localX;
			var localMouseY:Number = localY;
			var a:int = Math.min(_shiftX, _shiftX + _cachedWidth);
			var b:int = Math.max(_shiftX, _shiftX + _cachedWidth);
			var c:int = Math.min(_shiftY, _shiftY + _cachedHeight);
			var d:int = Math.max(_shiftY, _shiftY + _cachedHeight);
			return	(a <= localMouseX) &&
				(b >= localMouseX) &&
				(c <= localMouseY) &&
				(d >= localMouseY);
		}
		
		molehill_internal var _textureChanged:Boolean = false;
		
		molehill_internal var _visibilityChanged:Boolean = false;
		molehill_internal function resetVisibilityChanged():void
		{
			_visibilityChanged = false;
			
			var currentParent:Sprite3DContainer = _parent;
			while (currentParent != null)
			{
				currentParent._visibilityChanged = false;
				currentParent = currentParent._parent;
			}
		}
	
		molehill_internal var _hasChanged:Boolean = true;
		/*
		molehill_internal function get hasChanged():Boolean
		{
			return _hasChanged;
		}
		*/
		molehill_internal function set hasChanged(value:Boolean):void
		{
			_hasChanged = value;
			
			updateValues();
		}
		
		molehill_internal var addedToScene:Boolean = false;
		private var _shader:Shader3D;
		public function get shader():Shader3D
		{
			var currentParent:Sprite3DContainer = parent;
			var shader:Shader3D;
			while (currentParent != null)
			{
				if (currentParent.shader != null)
				{
					shader = currentParent.shader;
				}
				
				currentParent = currentParent.parent;
			}
			return shader != null ? shader : _shader;
		}

		public function set shader(value:Shader3D):void
		{
			_shader = value;
		}
		private var _mask:Sprite3D;
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
				
				if (value != null && SCENE_MANAGER.renderEngine != null)
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
		
		molehill_internal var parentX0Node:BinarySearchTreeNode;
		molehill_internal var parentY0Node:BinarySearchTreeNode;
		molehill_internal var parentX1Node:BinarySearchTreeNode;
		molehill_internal var parentY1Node:BinarySearchTreeNode;
		molehill_internal var parentX2Node:BinarySearchTreeNode;
		molehill_internal var parentY2Node:BinarySearchTreeNode;
		molehill_internal var parentX3Node:BinarySearchTreeNode;
		molehill_internal var parentY3Node:BinarySearchTreeNode;
		
		protected var _boundRect:Rectangle;
		public function get boundRect():Rectangle
		{
			if (_boundRect == null)
			{
				_boundRect = new Rectangle();
			}
			
			return _boundRect;
		}
		
		/**
		 * 
		 * While located in UIComponent3D container sprites with isBackground set to true will be moved to the bottom while rendering.
		 * This can help to batch UI textures and present UI component with less draw calls. 
		 * 
		 **/
		private var _isBackground:Boolean = false;
		public function get isBackground():Boolean
		{
			return _isBackground;
		}
		
		public function set isBackground(value:Boolean):void
		{
			_isBackground = value;
		}
		
		override public function toString():String
		{
			var className:String = getQualifiedClassName(this);
			return className + " @ " + StringUtils.getObjectAddress(this) + " texture: " + textureID;
		}
	}
}