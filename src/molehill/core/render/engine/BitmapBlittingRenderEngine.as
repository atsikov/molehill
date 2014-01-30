package molehill.core.render.engine
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.Stage;
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import molehill.core.texture.TextureManager;
	import molehill.core.render.Sprite3D;
	
	public class BitmapBlittingRenderEngine implements IRenderEngine
	{
		private var _renderTarget:DisplayObjectContainer;
		private var _renderBitmap:Bitmap;
		public function BitmapBlittingRenderEngine(renderTarget:Stage)
		{
			_renderBitmap = new Bitmap();
			
			_renderTarget = renderTarget;
			_renderTarget.addChildAt(_renderBitmap, 0);
		}
		
		private var _verticesOffset:int = 0;
		private var _colorOffset:int = 0;
		private var _textureOffset:int = 0;
		private var _dataPerVertex:int = 0;
		public function configureVertexBuffer(verticesOffset:int, colorOffset:int, textureOffset:int, dataPerVertex:int):void
		{
			_verticesOffset = verticesOffset;
			_colorOffset = colorOffset;
			_textureOffset = textureOffset;
			_dataPerVertex = dataPerVertex;
		}
		
		private var _backBufferBitmapData:BitmapData;
		private var _backBufferRect:Rectangle;
		private var _viewportWidth:int = 0;
		private var _viewportHeight:int = 0;
		public function getViewportWidth():int
		{
			return _viewportWidth;
		}
		
		public function getViewportHeight():int
		{
			return _viewportHeight;
		}
		
		public function get isReady():Boolean
		{
			return true;
		}
		
		public function setViewportSize(width:int, height:int):void
		{
			if (_viewportWidth == width && _viewportHeight == height)
			{
				return;
			}
			
			_viewportWidth = width;
			_viewportHeight = height;
			
			if (_backBufferRect == null)
			{
				_backBufferRect = new Rectangle();
			}
			_backBufferRect.width = width;
			_backBufferRect.height = height;
			
			if (_backBufferBitmapData != null)
			{
				_backBufferBitmapData.dispose();
			}
			_backBufferBitmapData = new BitmapData(width, height, true, 0xFF808080);
			_renderBitmap.bitmapData = _backBufferBitmapData;
		}
		
		private var _vertexBufferData:Vector.<Number>;
		public function setVertexBufferData(data:Vector.<Number>):void
		{
			_vertexBufferData = data;
		}
		
		private var _indexBufferData:Vector.<uint>;
		public function setIndexBufferData(data:Vector.<uint>):void
		{
			_indexBufferData = data;
		}
		
		private var _textureAtlasID:String;
		public function bindTexture(textureAtlasID:String):void
		{
			_textureAtlasID = textureAtlasID;
		}
		
		private var _cameraPosition:Point = new Point();
		public function setCameraPosition(position:Point):void
		{
			_cameraPosition.x = position.x;
			_cameraPosition.y = position.y;
		}
		
		public function clear():void
		{
			_backBufferBitmapData.fillRect(
				_backBufferRect,
				0xFF808080
			);
		}
		
		public function present():void
		{
			
		}
		
		private var _vertexBuffer:VertexBuffer3D;
		private var _indexBuffer:IndexBuffer3D;
		public function drawTriangles(numSprites:int):void
		{
			// TODO: vector coords checking
			
			_backBufferBitmapData.lock();
			
			var rect:Rectangle = new Rectangle();
			var textureRect:Rectangle = new Rectangle();
			var texture:BitmapData = TextureManager.getInstance().getAtlasByID(_textureAtlasID);
			for (var i:int = 0; i < numSprites / 2; i++)
			{
				var vertexShift:int = i * 4 * _dataPerVertex;
				rect.x = _vertexBufferData[vertexShift + _dataPerVertex];
				rect.y = _vertexBufferData[vertexShift + _dataPerVertex + 1];
				rect.width = _vertexBufferData[vertexShift + 2 * _dataPerVertex] - rect.x;
				rect.height = _vertexBufferData[vertexShift + 1] - rect.y;
				
				textureRect.x = _vertexBufferData[vertexShift + _dataPerVertex + _textureOffset] * texture.width;
				textureRect.y = _vertexBufferData[vertexShift + _dataPerVertex + _textureOffset + 1] * texture.height;
				textureRect.width = _vertexBufferData[vertexShift + _textureOffset + 2 * _dataPerVertex] * texture.width - textureRect.x;
				textureRect.height = _vertexBufferData[vertexShift + _textureOffset + 1] * texture.height - textureRect.y;
				
				if (textureRect.width == rect.width && textureRect.height == rect.height)
				{
					_backBufferBitmapData.copyPixels(
						texture,
						textureRect,
						new Point(rect.x, rect.y).add(_cameraPosition),
						null,
						null,
						true
					);
				}
				else
				{
					var m:Matrix = new Matrix();
					m.scale(rect.width / textureRect.width, rect.height / textureRect.height);
					
					m.translate(rect.x - textureRect.x, rect.y - textureRect.y);
					
					textureRect.x = rect.x;
					textureRect.y = rect.y;
					
					textureRect.width = textureRect.width * rect.width / textureRect.width;
					textureRect.height = textureRect.height * rect.height / textureRect.height;
					
					_backBufferBitmapData.draw(
						texture,
						m,
						null,
						null,
						textureRect,
						true
					);
				}
				
			}
			
			_backBufferBitmapData.unlock();
		}
	}
}