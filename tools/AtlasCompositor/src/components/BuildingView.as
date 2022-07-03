package components
{
	import animation_data.BuildingAnimationData;
	import animation_data.WorldEntryAnimationInfo;
	
	import com.adobe.images.PNGEncoder;
	
	import easy.ui.RasterizedSprite;
	
	import fl.motion.easing.Linear;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.InteractiveObject;
	import flash.display.Loader;
	import flash.display.MovieClip;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	import molehill.core.animation.SpriteAnimationData;
	import molehill.core.sprite.AnimatedSprite3D;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.SpriteSheet;
	import molehill.core.texture.SpriteSheetData;
	
	import org.opentween.OpenTween;
	
	import resources.Resource;
	import resources.events.ResourceEvent;
	import resources.species.SWFResource;
	
	import utils.StringUtils;
	
	public class BuildingView extends Sprite3DContainer
	{
		private var _url:String;

		public function get url():String
		{
			return _url;
		}

		public function BuildingView(buildingSWF:MovieClip, itemID:Object, workState:Boolean = false)
		{
			_url = "/001/" + StringUtils.prepend(itemID.toString(), '0', 6) + "_" + (workState ? "work" : "i") + ".swf";
			
			_resInstance = buildingSWF;
			addResInstanceToStage();
		}
		
		protected function onResourceInaccessible(event:ResourceEvent):void
		{
			dispatchEvent(
				event.clone()
			);
		}
		
		protected var _res:SWFResource;
		protected var _resInstance:DisplayObject;
		protected var _resSprite:Sprite3D;
		protected var _resSpriteHighlight:Sprite3D;
		
		private var _peopleAnimation:Sprite3DContainer;
		private var _peopleAnimationTimeout:int;

		public var hashPNGs:Object = new Object();
		private function upload(data:ByteArray, fileName:String):void
		{
			if (hashPNGs == null)
			{
				hashPNGs = new Object();
			}
			
			// _url.match(/\/((\d{6}|\dx\d).*)\.swf/)[1]
			
			hashPNGs[fileName] = data;
		}
		
		protected function addResInstanceToStage():void
		{
			if (_resInstance is InteractiveObject)
			{
				(_resInstance as InteractiveObject).mouseEnabled = false;
			}
			if (_resInstance is DisplayObjectContainer)
			{
				(_resInstance as DisplayObjectContainer).mouseChildren = false;
			}
			
			var movie:MovieClip = _resInstance as MovieClip;
			if (movie != null)
			{
				movie.gotoAndStop(1);
			}
			
			var textureID:String = entryTextureID;
			var buildingAnimationData:BuildingAnimationData;
			if (hashPNGs[_url.match(/\/((\d{6}|\dx\d|\w*)_.*)\.swf/)[1] + ".png"] == null)
			{
				if (_resInstance is DisplayObjectContainer)
				{
					var light:DisplayObject = (_resInstance as DisplayObjectContainer).getChildByName("light");
					var mcBliki:DisplayObject = (_resInstance as DisplayObjectContainer).getChildByName("bliki");
					var mcBlikiNight:DisplayObject = (_resInstance as DisplayObjectContainer).getChildByName("bliki_night");
					var mcPeople:DisplayObject = (_resInstance as DisplayObjectContainer).getChildByName("people");
					
					if (mcPeople != null)
					{
						processPeople(mcPeople as MovieClip);
						
						buildingAnimationData = WorldEntryAnimationInfo.getInstance().getAnimationInfo(entryTextureID) as BuildingAnimationData;
						if (buildingAnimationData == null)
						{
							buildingAnimationData = new BuildingAnimationData();
							WorldEntryAnimationInfo.getInstance().addAnimationInfo(textureID, buildingAnimationData);
						}
						for (var key:Object in _hashSpriteSheets)
						{
							var animationData:SpriteAnimationData = key as SpriteAnimationData;
							if (hashPNGs[animationData.animationName + ".png"] == null)
							{
								var spriteSheet:SpriteSheet = _hashSpriteSheets[key];
								hashSpriteSheetDatas[animationData.animationName] = spriteSheet.spriteSheetData;
								upload(PNGEncoder.encode(spriteSheet), animationData.animationName + ".png");
								spriteSheet.dispose();
							}
							
							buildingAnimationData.addPeopleAnimation(
								animationData,
								animationData.animationName
							);
								
						}
					}
					
					if (mcBliki != null)
					{
						getShiningAnimation(mcBliki as MovieClip);
						getTechnicalAnimation(mcBliki as MovieClip);				
					}
				}
				
				if (light != null)
				{
					light.visible = false;
				}
				
				if (mcBliki != null)
				{
					mcBliki.visible = false;
				}
				
				if (mcBlikiNight != null)
				{
					mcBlikiNight.visible = false;
				}
				
				if (mcPeople != null)
				{
					mcPeople.visible = false;
				}
				
				var bitmapData:BitmapData = new BitmapData(resWidth, resHeight, true, 0x00000000);
				bitmapData.draw(_resInstance);
				upload(PNGEncoder.encode(bitmapData), _url.match(/\/((\d{6}|\dx\d|\w*)_.*)\.swf/)[1] + ".png");
				bitmapData.dispose();
				
				bitmapData = new BitmapData(resWidth * 0.3, resHeight * 0.3, true, 0x00000000);
				bitmapData.draw(
					_resInstance,
					new Matrix(0.25, 0, 0, 0.25, resWidth * 0.025, resHeight * 0.025)
				);
				bitmapData.applyFilter(
					bitmapData,
					bitmapData.rect,
					new Point(),
					new GlowFilter(0xFFFFFF, 1, 2, 2, 4, 3)
				);
				bitmapData.applyFilter(
					bitmapData,
					bitmapData.rect,
					new Point(),
					new ColorMatrixFilter([
						1, 1, 1, 0, 0,
						1, 1, 1, 0, 0,
						1, 1, 1, 0, 0,
						0, 0, 0, 1, 0
					])
				);
				upload(PNGEncoder.encode(bitmapData), _url.match(/\/((\d{6}|\dx\d|\w*)_.*)\.swf/)[1] + "hl.png");
				bitmapData.dispose();
			}
			
			if (_resSprite == null)
			{
				_resSprite = new Sprite3D();
			}
			
			buildingAnimationData = WorldEntryAnimationInfo.getInstance().getAnimationInfo(textureID) as BuildingAnimationData;
			if (buildingAnimationData != null)
			{
				if (_peopleAnimation == null)
				{
					_peopleAnimation = new Sprite3DContainer();
					_peopleAnimation.mouseEnabled = false;
					addChild(_peopleAnimation);
				}
				
				for (key in buildingAnimationData.hashPeopleAnimations)
				{
					animationData = buildingAnimationData.hashPeopleAnimations[key][BuildingAnimationData.ANIMATION_DATA] as SpriteAnimationData;
					var spriteSheetData:SpriteSheetData = hashSpriteSheetDatas[buildingAnimationData.hashPeopleAnimations[key][BuildingAnimationData.TEXTURE_ID]];
					
					var sprite:AnimatedSprite3D = new AnimatedSprite3D();
					sprite.setTexture(animationData.animationName);
					sprite.setSize(spriteSheetData.frameWidth, spriteSheetData.frameHeight);
					sprite.animationData = animationData;
					_peopleAnimation.addChild(sprite);
				}
				
			}
			
			dispatchEvent(
				new Event(Event.ADDED)
			);
		}
		
		private static const SHOW_PEOPLE_TIMEOUT_MIN:uint = 25000;
		private static const SHOW_PEOPLE_TIMEOUT_MAX:uint = 40000;
		private static const HIDE_PEOPLE_TIMEOUT_MIN:uint = 30000;
		private static const HIDE_PEOPLE_TIMEOUT_MAX:uint = 45000;
		private function showPeopleAnimation():void
		{
			for (var i:int = 0; i < _peopleAnimation.numChildren; i++)
			{
				var child:AnimatedSprite3D = _peopleAnimation.getChildAt(i) as AnimatedSprite3D;
				if (child != null)
				{
					child.play();
				}
			}
			
			_peopleAnimation.visible = true;
			_peopleAnimation.alpha = 0;
			OpenTween.go(
				_peopleAnimation,
				{
					'alpha': 1
				},
				1,
				0,
				Linear.easeNone
			);
			
			_peopleAnimationTimeout = setTimeout(hidePeopleAnimation, SHOW_PEOPLE_TIMEOUT_MIN + Math.random() * (SHOW_PEOPLE_TIMEOUT_MAX - SHOW_PEOPLE_TIMEOUT_MIN));
		}
		
		private function hidePeopleAnimation():void
		{
			if (_peopleAnimation == null)
			{
				return;
			}
			
			OpenTween.go(
				_peopleAnimation,
				{
					'alpha': 0
				},
				1,
				0,
				Linear.easeNone,
				onPeopleAnimationHid
			);
			
			_peopleAnimationTimeout = setTimeout(showPeopleAnimation, HIDE_PEOPLE_TIMEOUT_MIN + Math.random() * (HIDE_PEOPLE_TIMEOUT_MAX - HIDE_PEOPLE_TIMEOUT_MIN));
		}
		
		private function onPeopleAnimationHid():void
		{
			if (_peopleAnimation == null)
			{
				return;
			}
			
			_peopleAnimation.visible = false;
		}
		
		private var _listPeopleAnimationSource:Array;
		private var _processedAnimations:Object;
		private var _hashSpriteSheets:Dictionary;
		private var _maskBitmapData:BitmapData;
		private function processPeople(movie:MovieClip):void
		{
			_listPeopleAnimationSource = new Array();
			_processedAnimations = new Object();
			_hashSpriteSheets = new Dictionary();
			
			getPeopleAnimations(movie);
			
			for (var i:int = 0; i < _listPeopleAnimationSource.length; i++)
			{
				movie.gotoAndStop(_processedAnimations[_listPeopleAnimationSource[i]]);
				var animation:MovieClip = movie.getChildByName(_listPeopleAnimationSource[i]) as MovieClip;
				
				if (animation == null)
				{
					trace("!!!!!! Failed to export animation " + _listPeopleAnimationSource[i]);
					continue;
				}
				
				var animData:SpriteAnimationData = new SpriteAnimationData(movie, animation);
				
				movie.gotoAndStop(_processedAnimations[_listPeopleAnimationSource[i]]);
				
				var spriteSheet:SpriteSheet = new SpriteSheet(movie.getChildByName(_listPeopleAnimationSource[i]) as MovieClip, 512, 1);
				_hashSpriteSheets[animData] = spriteSheet;
			}
		}
		
		private function getPeopleAnimations(container:MovieClip):void
		{
			for (var i:int = 0; i < container.totalFrames; i++)
			{
				container.gotoAndStop(i + 1);
				var numElements:int = container.numChildren;
				for (var j:int = 0; j < numElements; j++)
				{
					var child:DisplayObject = container.getChildAt(j);
					if (child is MovieClip)
					{
						if (child.name.indexOf("animation___") == 0)
						{
							if (_processedAnimations[child.name] == null)
							{
								_processedAnimations[child.name] = i + 1;
								_listPeopleAnimationSource.push(child.name);
							}
							//container.removeChild(child);
						}
					}
				}
			}
			
			_maskBitmapData = null;
			
			for (i = 0; i < container.totalFrames; i++)
			{
				container.gotoAndStop(i + 1);
				if (container.numChildren == 0)
				{
					continue;
				}
				
				var tempSprite:Sprite = new Sprite();
				for (j = 0; j < container.numChildren; j)
				{
					container.getChildAt(0).mask = null;
					if (container.getChildAt(0).name.indexOf("animation___") != 0)
					{
						tempSprite.addChild(container.getChildAt(0));
					}
					else
					{
						j++;
					}
				}
				
				if (tempSprite.numChildren == 0)
				{
					continue;
				}
				
				var rect:Rectangle = tempSprite.getBounds(tempSprite);
				_maskBitmapData = new BitmapData(rect.width + 2, rect.height + 2, true, 0x66000000);
				var m:Matrix = new Matrix();
				m.translate(-rect.x + 1, -rect.y + 1);
				_maskBitmapData.draw(tempSprite, m);
				
				break;
			}
		}
		
		private var _shiningAnimation:Sprite3DContainer;
		private function getShiningAnimation(movie:MovieClip):void
		{
			var maskPosition:Point;
			for (var i:int = 0; i < movie.totalFrames; i++)
			{
				movie.gotoAndStop(i + 1);
				var shining:DisplayObject = movie.getChildByName("shine");
				if (shining != null)
				{
					trace("shine found");
					
					for (var j:int = 0; j < movie.numChildren; j++)
					{
						var child:DisplayObject = movie.getChildAt(j);
						if (child is Shape)
						{
							trace("shape");
							
							child.parent.removeChild(child);
							child.mask = null;
							
							var rect:Rectangle = child.getBounds(child);
							_maskBitmapData = new BitmapData(rect.width + 2, rect.height + 2, true, 0x00000000);
							var m:Matrix = new Matrix();
							m.translate(-rect.x + 1, -rect.y + 1);
							_maskBitmapData.draw(child, m);
							
							maskPosition = new Point(rect.x - 1, rect.y - 1);
							
							break;
							
						}
					}
					
					break;
				}
			}
			
			if (maskPosition == null)
			{
				return;
			}
			
			var lightAnimationData:SpriteAnimationData = new SpriteAnimationData(movie, shining);
			
			movie.gotoAndStop(i + 1);
			shining = movie.getChildByName("shine");
			
			rect = shining.getBounds(shining);
			var bitmapData:BitmapData = new BitmapData(rect.width + 2, rect.height + 2, true, 0x00000000);
			m = new Matrix();
			m.translate(-rect.x + 1, -rect.y + 1);
			bitmapData.draw(shining, m);
			
			bitmapData.dispose();
			
			var buildingAnimation:BuildingAnimationData = WorldEntryAnimationInfo.getInstance().getAnimationInfo(entryTextureID) as BuildingAnimationData;
			if (buildingAnimation == null)
			{
				buildingAnimation = new BuildingAnimationData();
				WorldEntryAnimationInfo.getInstance().addAnimationInfo(entryTextureID, buildingAnimation);
			}
			
			buildingAnimation.addShineAnimationData(maskPosition, lightAnimationData);
		}
		
		private var _technicalAnimation:Sprite3DContainer;
		public var hashSpriteSheetDatas:Object = new Object();
		private function getTechnicalAnimation(movie:MovieClip):void
		{
			var bdTemp:BitmapData;
			var hashAnimations:Object = new Object();
			for (var i:int = 0; i < movie.totalFrames; i++)
			{
				movie.gotoAndStop(i + 1);
				for (var j:int = 0; j < movie.numChildren; j++)
				{
					var child:DisplayObject = movie.getChildAt(j);
					var childName:String = child.name;
					if (childName == null || childName == "")
					{
						continue;
					}
					
					var matches:Array = childName.match(/(\S*)\$(\d)/);
					if (matches == null || matches.length == 0)
					{
						continue;
					}
					
					var animationName:String = entryTextureID + '_' + matches[1];
					var animationIndex:int = matches[2];
					
					if (hashPNGs[animationName + ".png"] == null)
					{
						if (child is MovieClip && (child as MovieClip).totalFrames > 1)
						{
							var spriteSheet:SpriteSheet = new SpriteSheet(child as MovieClip);
							hashSpriteSheetDatas[animationName] = spriteSheet.spriteSheetData;
							
							upload(PNGEncoder.encode(spriteSheet), animationName + ".png");
							spriteSheet.dispose();
						}
						else
						{
							bdTemp = new RasterizedSprite(child).bitmapData;
							upload(PNGEncoder.encode(bdTemp), animationName + ".png");
							bdTemp.dispose();
						}
					}
					
					var spriteSheetData:SpriteSheetData = hashSpriteSheetDatas[animationName];
					if (hashAnimations[childName] == null)
					{
						var spriteAnimation:SpriteAnimationData = new SpriteAnimationData(movie, child);
						spriteAnimation.animationName = entryTextureID + '_' + childName;
						hashAnimations[childName] = spriteAnimation;
						var buildingAnimation:BuildingAnimationData = WorldEntryAnimationInfo.getInstance().getAnimationInfo(entryTextureID) as BuildingAnimationData;
						if (buildingAnimation == null)
						{
							buildingAnimation = new BuildingAnimationData();
							WorldEntryAnimationInfo.getInstance().addAnimationInfo(entryTextureID, buildingAnimation);
							
							buildingAnimation.technicalAnimationX = movie.x;
							buildingAnimation.technicalAnimationY = movie.y;
						}
						
						buildingAnimation.addTechincalAnimation(hashAnimations[childName], animationName);
					}
					
					//trace(matches);
					//trace(childName);
				}
			}
		}
		
		private var _offsetX:int = 0;
		public function get offsetX():int
		{
			return _offsetX;
		}
		
		private var _offsetY:int = 0;
		public function get offsetY():int
		{
			return _offsetY;
		}
		
		public function offsetTo(offsetX:int, offsetY:int, silent:Boolean = false):void
		{
			_offsetX = offsetX;
			_offsetY = offsetY;
			
			updatePosition();
		}
		
		private function updatePosition():void
		{
			moveTo(
				300,
				300
			);
		}
		
		protected function disposeResource():void
		{
			clearTimeout(_peopleAnimationTimeout);
			
			if (_resInstance != null)
			{
				/*if (_resInstance is Loader)
				{
				(_resInstance as Loader).contentLoaderInfo.removeEventListener(Event.COMPLETE, onResInstanceLoaderComplete);
				}*/
				Resource.collectFreeContentInstance(_resInstance);
				_resInstance = null;
			}
			
			if (_res != null)
			{
				_res.dispose();
				_res = null;
			}
			
			if (_resSprite != null && contains(_resSprite))
			{
				removeChild(_resSprite);
			}
			_resSprite = null;
			
			if (_resSpriteHighlight != null && contains(_resSpriteHighlight))
			{
				removeChild(_resSpriteHighlight);
			}
			_resSpriteHighlight = null;
			
			if (_peopleAnimation != null && contains(_peopleAnimation))
			{
				removeChild(_peopleAnimation);
				while (_peopleAnimation.numChildren > 0)
				{
					_peopleAnimation.removeChildAt(0);
				}
			}
			_peopleAnimation = null;
			
			if (_technicalAnimation != null && contains(_technicalAnimation))
			{
				removeChild(_technicalAnimation);
				while (_technicalAnimation.numChildren > 0)
				{
					_technicalAnimation.removeChildAt(0);
				}
			}
			_technicalAnimation = null;
		}
		
		private var _blockInformer:Boolean = false;
		public function get blockInformer():Boolean
		{
			return _blockInformer;
		}

		public function set blockInformer(value:Boolean):void
		{
			_blockInformer = value;
		}

		protected var _disposed:Boolean = false;
		public function dispose():void
		{
			_disposed = true;
			disposeResource();
		}
		
		public function get entryTextureID():String
		{
			if (_url == "")
			{
				return "";
			}
			else
			{
				var base:String = "";
				var suffix:String = "";
				var matches:Array = _url.match(/\/(\d{6}.*)\.swf/);
				if (matches != null)
				{
					base = matches[1];
				}
				else
				{
					matches = _url.match(/\/(\dx\d.*)\.swf/);
					if (matches != null)
					{
						base = matches[1];
					}
					else
					{
						matches = _url.match(/.*\/(\S*)_\S+.swf/);
						base = matches[1];
					}
				}
				
				return base + suffix;
			}
		}
		
		protected function get resWidth():uint
		{
			if (_resInstance == null)
				return 0;
			
			if (_resInstance is Loader)
			{
				var loader:Loader = _resInstance as Loader;
				
				return loader.contentLoaderInfo.width;
			}
			else if (_resInstance is MovieClip)
			{
				var movie:MovieClip = _resInstance as MovieClip;
				
				return movie.loaderInfo.width;
			}
			else
			{
				return _resInstance.width;
			}
		}
		
		protected function get resHeight():uint
		{
			if (_resInstance == null)
				return 0;
			
			if (_resInstance is Loader)
			{
				var loader:Loader = _resInstance as Loader;
				
				return loader.contentLoaderInfo.height;
			}
			else if (_resInstance is MovieClip)
			{
				var movie:MovieClip = _resInstance as MovieClip;
				
				return movie.loaderInfo.height;
			}
			else
			{
				return _resInstance.height;
			}
		}
		
		protected function onResourceReadyCallback(res:Resource, resInstance:DisplayObject):void
		{
			if (_res !== res || _disposed)
			{
				Resource.collectFreeContentInstance(resInstance);
				return;
			}
			
			_resInstance = resInstance;	
			if (_resInstance == null)
				return;
			
			//if (_resInstance is Loader)
			//{
			//	(_resInstance as Loader).contentLoaderInfo.addEventListener(Event.COMPLETE, onResInstanceLoaderComplete);
			//	return;
			//}
			
			addResInstanceToStage();
		}
		
		protected function onResInstanceLoaderComplete(event:Event):void
		{
			addResInstanceToStage();
		}
		
	}
}