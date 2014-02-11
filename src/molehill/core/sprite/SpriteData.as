package molehill.core.sprite
{
	import flash.display.DisplayObject;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	
	
	import utils.ObjectUtils;

	public class SpriteData
	{
		public static function fromRawData(rawData:Object):SpriteData
		{
			if (rawData == null)
			{
				return null;
			}
			
			var spriteData:SpriteData = new SpriteData(null);
			for (var i:int = 0; i < spriteData._params.length; i++)
			{
				if (rawData[spriteData._params[i]] != null)
				{
					spriteData._values[spriteData._params[i]] = rawData[spriteData._params[i]];
				}
			}
			
			return spriteData;
		}
		
		private var _params:Array = ['x', 'y', 'alpha', 'scaleX', 'scaleY', 'rotation', 'matrix'];
		private var _values:Object;
		public function SpriteData(displayObject:DisplayObject)
		{
			_values = {};
			if (displayObject == null)
			{
				return;
			}
			
			for (var i:int = 0; i < _params.length; i++)
			{
				var param:String = _params[i];
				if (displayObject.hasOwnProperty(param))
				{
					_values[param] = displayObject[param];
				}
				else
				{
					_values[param] = undefined;
				}
			}
			/*
			_values['matrix'] = displayObject.transform.matrix;
			
			var spriteRect:Rectangle = displayObject.getBounds(displayObject);
			_values['matrix'].tx += spriteRect.x;
			_values['matrix'].ty += spriteRect.y;
			*/
			var m:Matrix = displayObject.transform.matrix;
			if (m.a != m.d)
			{
				var r:Number = displayObject.rotation;
				if (Math.abs(r) == 180)
				{
					r = 3;
				}
				else
				{
					r /= 90;
					r += 2;
					r = int(r);
				}
				
				switch (r)
				{
					case 0:
						if (m.a > 0 && _values['scaleX'] > 0)
						{
							_values['scaleX'] = -_values['scaleX'];
						}
						if (m.d > 0 && _values['scaleY'] > 0)
						{
							_values['scaleY'] = -_values['scaleY'];
						}
						break;
					case 1:
						if (m.a < 0 && _values['scaleX'] > 0)
						{
							_values['scaleX'] = -_values['scaleX'];
						}
						if (m.d < 0 && _values['scaleY'] > 0)
						{
							_values['scaleY'] = -_values['scaleY'];
						}
						break;
					case 2:
						if (m.a < 0 && _values['scaleX'] > 0)
						{
							_values['scaleX'] = -_values['scaleX'];
						}
						if (m.d < 0 && _values['scaleY'] > 0)
						{
							_values['scaleY'] = -_values['scaleY'];
						}
						break;
					case 3:
						if (m.a > 0 && _values['scaleX'] > 0)
						{
							_values['scaleX'] = -_values['scaleX'];
						}
						if (m.d > 0 && _values['scaleY'] > 0)
						{
							_values['scaleY'] = -_values['scaleY'];
						}
						break;
				}
			}
			
			var spriteRect:Rectangle = displayObject.getBounds(displayObject);
			m.tx = spriteRect.x;
			m.ty = spriteRect.y;
			m.rotate(displayObject.rotation / 180 * Math.PI);
			
			_values['x'] += m.tx;
			_values['y'] += m.ty;
		}
		
		private var _parentScaleX:Number = 1;
		private var _parentScaleY:Number = 1;
		public function applyScale(scaleX:Number, scaleY:Number):void
		{
			_parentScaleX = scaleX;
			_parentScaleY = scaleY;
		}
		
		public function init(rawData:Object):void
		{
			for (var i:int = 0; i < _params.length; i++)
			{
				var param:String = _params[i];
				_values[param] = rawData[param];
			}
		}
		
		public function getRawData():Object
		{
			var rawData:Object = {};
			for (var i:int = 0; i < _params.length; i++)
			{
				var param:String = _params[i];
				rawData[param] = _values[param];
			}
			
			return rawData;
		}
		
		public function applyValues(sprite:Sprite3D):void
		{
			
			sprite.moveTo(
				_values['x'] * _parentScaleX,
				_values['y'] * _parentScaleY
			);
			
			sprite.setScale(
				_values['scaleX'],
				_values['scaleY']
			);
			
			sprite.rotation = _values['rotation'];
			
			sprite.alpha = _values['alpha'];
			/*
			sprite.applyMatrix(
				_values['matrix'].a,
				_values['matrix'].b,
				_values['matrix'].c,
				_values['matrix'].d,
				_values['matrix'].tx,
				_values['matrix'].ty
			);
			*/
		}
		
		public function toString():String
		{
			var paramsString:String = "";
			for (var param:String in _values)
			{
				paramsString += "\"" + param + "\"=" + _values[param] + ", ";
			}
			if (paramsString.length > 2)
			{
				paramsString = paramsString.substr(0, paramsString.length - 2);
			}
			
			return "[SpriteData (" + paramsString + ")]";
		}
	}
}