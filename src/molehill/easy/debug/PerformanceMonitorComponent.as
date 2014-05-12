package molehill.easy.debug
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.system.System;
	import flash.utils.getTimer;
	
	import molehill.core.render.UIComponent3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.render.shader.species.base.ColorFillShader;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.text.TextField3D;
	import molehill.core.text.TextField3DAlign;
	import molehill.core.text.TextField3DFormat;
	
	import utils.CachingFactory;
	
	public class PerformanceMonitorComponent extends UIComponent3D
	{
		private var _lastTimer:uint;
		private var _tfFps:TextField3D;
		private var _tfMemory:TextField3D;
		private var _maxMemory:int = 10 * 1024 * 1024;
		
		private var _tfTriangles:TextField3D;
		private var _tfDrawCalls:TextField3D;
		
		private var _containerMemoryGraph:Sprite3DContainer;
		private var _enterFrameDispatcher:Sprite;
		
		public function PerformanceMonitorComponent()
		{
			var bgMemoryMonitor:Sprite3D = new Sprite3D();
			bgMemoryMonitor.shader = Shader3DFactory.getInstance().getShaderInstance(ColorFillShader);
			bgMemoryMonitor.setSize(150, 150);
			bgMemoryMonitor.darkenColor = 0x2f2f2f;
			addChild(bgMemoryMonitor);
			
			_containerMemoryGraph = new Sprite3DContainer();
			_containerMemoryGraph.moveTo(150, 0);
			addChild(_containerMemoryGraph);
			
			_tfFps = new TextField3D();
			_tfFps.x = 147;
			_tfFps.y = -3;
			_tfFps.defaultTextFormat = new TextField3DFormat("Officina", 10, 0xFFFFFF, TextField3DAlign.RIGHT);
			_tfFps.text = "0 FPS";
			addChild(_tfFps);
			
			_tfMemory = new TextField3D();
			_tfMemory.x = 3;
			_tfMemory.y = -3;
			_tfMemory.defaultTextFormat = new TextField3DFormat("Officina", 10 ,0xFFFFFF);
			_tfMemory.text = "0/0 Mb";
			addChild(_tfMemory);
			
			_tfDrawCalls = new TextField3D();
			_tfDrawCalls.x = 3;
			_tfDrawCalls.y = 125;
			_tfDrawCalls.defaultTextFormat = new TextField3DFormat("Officina", 10 ,0xFFFFFF);
			_tfDrawCalls.text = "Draw calls: 0";
			addChild(_tfDrawCalls);
			
			_tfTriangles = new TextField3D();
			_tfTriangles.x = 3;
			_tfTriangles.y = 136;
			_tfTriangles.defaultTextFormat = new TextField3DFormat("Officina", 10 ,0xFFFFFF);
			_tfTriangles.text = "Triangles: 0";
			addChild(_tfTriangles);
			
			_enterFrameDispatcher = new Sprite();
			_enterFrameDispatcher.addEventListener(Event.ENTER_FRAME, onEnterFrame);
			
			_lastTimer = getTimer();
			
			_cacheSprites = new CachingFactory(Sprite3D, 150);
			
			updateOnRender = true;
		}
		
		private var _lastPoint:Sprite3D;
		private var _framesPassed:int = 0;
		private var _cacheSprites:CachingFactory;
		private function onEnterFrame(event:Event):void
		{
			var timePast:uint = getTimer() - _lastTimer;
			if (timePast > 1000)
			{
				_tfFps.text = _framesPassed + " FPS";
				_lastTimer = getTimer();
				_framesPassed = 0;
			}
			else
			{
				_framesPassed++;
			}
			
			if (_framesPassed % 5 != 0)
			{
				return;
			}
			
			var numGraphPieces:uint = _containerMemoryGraph.numChildren;
			
			var currentConsumedMemory:int = System.totalMemory;
			var needScaleDown:Boolean = false;
			var scaleFactor:int = 1;
			while (currentConsumedMemory > _maxMemory)
			{
				_maxMemory *= 2;
				scaleFactor *= 2;
				needScaleDown = true;
			}
			
			if (!needScaleDown)
			{
				var needScaleUp:Boolean;
				if (currentConsumedMemory <= _maxMemory / 2)
				{
					var j:int = 0;
					for (var i:int = 0; i < numGraphPieces; i++)
					{
						var piece:Sprite3D = _containerMemoryGraph.getChildAt(i);
						if (piece.y < 75)
						{
							needScaleUp = false;
							break;
						}
						
						needScaleUp = true;
					}
				}
				
				if (needScaleUp)
				{
					_maxMemory /= 2;
					
					for (i = 0; i < numGraphPieces; i++)
					{
						piece = _containerMemoryGraph.getChildAt(i);
						piece.y = 2 * piece.y - 150;
					}
				}
			}
			else
			{
				for (i = 0; i < numGraphPieces; i++)
				{
					piece = _containerMemoryGraph.getChildAt(i);
					
					piece.y = 150 - (150 - piece.y) / scaleFactor;
				}
			}
			
			_containerMemoryGraph.x -= 1;
			
			var pointY:int = 150 - (currentConsumedMemory / _maxMemory * 150);
			var graphUpdated:Boolean = false;
			
			if (numGraphPieces > 0)
			{
				var firstPiece:Sprite3D = _containerMemoryGraph.getChildAt(0);
				if (firstPiece.x + _containerMemoryGraph.x < 0)
				{
					firstPiece.width += firstPiece.x + _containerMemoryGraph.x;
					firstPiece.x -= firstPiece.x + _containerMemoryGraph.x;
					
					if (firstPiece.width <= 0)
					{
						_containerMemoryGraph.removeChild(firstPiece);
						_cacheSprites.storeInstance(firstPiece);
						
						numGraphPieces--;
					}
				}
			
				var lastPiece:Sprite3D = _containerMemoryGraph.getChildAt(numGraphPieces - 1);
				if (lastPiece.y == pointY)
				{
					lastPiece.width += 1;
					graphUpdated = true;
				}
			}
			
			if (!graphUpdated)
			{
				piece = _cacheSprites.newInstance();
				piece.darkenColor = 0x00FF00;
				piece.shader = Shader3DFactory.getInstance().getShaderInstance(ColorFillShader);
				piece.setSize(1, 1);
				piece.moveTo(150 - _containerMemoryGraph.x, pointY);
				_containerMemoryGraph.addChild(piece);
			}
			
			_tfMemory.text = int(currentConsumedMemory / 1024 / 1024) + "/" + int(_maxMemory / 1024 / 1024) + " Mb";
			//_tfMemory.appendText("\nCPU: " + System.processCPUUsage.toFixed(2));
			
			if (scene != null)
			{
				var renderInfo:Object = scene.renderInfo;
				_tfDrawCalls.text = "Draw calls: " + renderInfo.drawCalls;
				_tfTriangles.text = "Triangles: " + renderInfo.totalTris;
			}
		}
	}
}