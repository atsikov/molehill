package components.prefab_editor
{
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filters.ColorMatrixFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	
	import model.IPrefabEditorPlugin;
	import model.IPrefabEditorPluginHost;
	import model.events.TrainPrefabEditorPanelEvent;
	
	import molehill.core.render.shader.Shader3D;
	import molehill.core.render.shader.Shader3DFactory;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	import molehill.core.texture.TextureManager;
	import molehill.core.utils.Sprite3DUtils;
	
	import mx.controls.Alert;
	import mx.core.IVisualElement;
	
	import utils.StringUtils;

	public class TrainPrefabCreator extends EventDispatcher implements IPrefabEditorPlugin
	{
		// список номеров кадров для теней
		protected var _listFramesShadowNums:Array = ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23', '24', '25', '26', '27', '28', '29', '30', '31', '32', '33', '34', '35'];
		// список номеров кадров для вагонов с разными передней и задней частью
		protected var _listFramesAsymmetricNums:Array = ['00', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '27', '28', '29', '30', '31', '32', '33', '34', '35'];
		// список номеров кадров для вагонов с одинаковыми передней и задней частью
		protected var _listFramesSymmetricNums:Array = ['09', '10', '11', '12', '13', '14', '15', '16', '17', '18'];
		
		private var _parent:IPrefabEditorPluginHost;
		public function TrainPrefabCreator(parent:IPrefabEditorPluginHost)
		{
			_pluginPanel = new TrainPrefabEditorPanel();
			_pluginPanel.addEventListener(TrainPrefabEditorPanelEvent.PLACE_ANCHORS, onPlaceAnchors);
			_pluginPanel.addEventListener(TrainPrefabEditorPanelEvent.MIRROR_ANCHORS, onMirrorAnchors);
			_pluginPanel.addEventListener(TrainPrefabEditorPanelEvent.COPY_ANCHORS, onCopyAnchors);
			_pluginPanel.addEventListener(TrainPrefabEditorPanelEvent.PASTE_ANCHORS, onPasteAnchors);
			
			_parent = parent;
		}
		
		private var _baseTextureName:String;
		private var _isSymmetric:Boolean = false;
		public function createPrefab(textureID:String, parentContainer:Sprite3DContainer):void
		{
			_baseTextureName = textureID.match(/(.*)_(body|shadow)_\d{2}$/)[1];
			
			if (!checkTextures())
			{
				return;
			}
			
			createTrainPrefab(parentContainer);
		}
		
		private var _pluginPanel:TrainPrefabEditorPanel;
		public function get pluginPanel():IVisualElement
		{
			return _pluginPanel;
		}
		
		private function checkTextures():Boolean
		{
			var tm:TextureManager = TextureManager.getInstance();
			_isSymmetric = !tm.isTextureCreated(_baseTextureName + '_body_00');
			
			var listMissingTextures:Array = new Array();
			var hasAllTextures:Boolean = true;
			for (var i:int = 0; i < _listFramesShadowNums.length; i++)
			{
				if (!tm.isTextureCreated(_baseTextureName + "_shadow_" + _listFramesShadowNums[i]))
				{
					listMissingTextures.push(_baseTextureName + "_shadow_" + _listFramesShadowNums[i]);
					hasAllTextures = false;
				}
			}
			
			var listFrameNums:Array = _isSymmetric ? _listFramesSymmetricNums : _listFramesAsymmetricNums;
			for (i = 0; i < listFrameNums.length; i++)
			{
				if (!tm.isTextureCreated(_baseTextureName + "_body_" + listFrameNums[i]))
				{
					listMissingTextures.push(_baseTextureName + "_body_" + listFrameNums[i]);
					hasAllTextures = false;
				}
			}
			
			var strMissingTextures:String = listMissingTextures.join('\n');
			
			if (!hasAllTextures)
			{
				Alert.show("Missing textures:\n" + strMissingTextures);
			}
			
			return hasAllTextures;
		}
		
		private function createTrainPrefab(container:Sprite3DContainer):void
		{
			_hashHighlightTextures = new Object();
			
			var listBodyTextures:Array = new Array();
			for (var i:int = 0; i < 360; i+= 10)
			{
				var frame:int = angleToFrame(i);
				var frameScale:Number = frame > 0 ? 1 : -1;
				frame = Math.abs(frame);
				
				var frameString:String = _isSymmetric ? _listFramesSymmetricNums[frame] : _listFramesAsymmetricNums[frame];
				
				var shadowAngle:int = (360 - i) + 90;
				while (shadowAngle >= 360)
				{
					shadowAngle -= 360;
				}
				var shadowFrameString:String = StringUtils.prepend(int(shadowAngle / 10).toString(), '0', 2);
				
				var frameContainer:Sprite3DContainer = new Sprite3DContainer();
				
				var shadowSprite:Sprite3D = Sprite3D.createFromTexture(_baseTextureName + "_shadow_" + shadowFrameString);
				shadowSprite.name = 'shadow';
				shadowSprite.setScale(3, 3);
				frameContainer.addChild(shadowSprite);
				
				var bodySprite:Sprite3D = Sprite3D.createFromTexture(_baseTextureName + "_body_" + frameString);
				bodySprite.name = 'body';
				bodySprite.setScale(frameScale, 1);
				frameContainer.addChild(bodySprite);
				
				frameContainer.name = "train" + shadowFrameString;
				container.addChild(frameContainer);
				
				if (bodySprite.scaleX < 0)
				{
					bodySprite.moveTo(-bodySprite.width, 0);
				}
				
				var bodyTexture:String = _baseTextureName + '_body_' + frameString;
				var highlightTexture:String = bodyTexture + "hl";
				if (!TextureManager.getInstance().isTextureCreated(highlightTexture))
				{
					if (_hashHighlightTextures[bodyTexture] == null)
					{
						_hashHighlightTextures[bodyTexture] = [bodySprite];
					}
					else
					{
						_hashHighlightTextures[bodyTexture].push(bodySprite);
					}
					if (listBodyTextures.indexOf(bodyTexture) == -1)
					{
						listBodyTextures.push(bodyTexture);
					}
				}
				else
				{
					var highlightSprite:Sprite3D = Sprite3D.createFromTexture(highlightTexture);
					highlightSprite.darkenColor = 0xFFFF7A;
					highlightSprite.setScale(4 * bodySprite.scaleX, 4);
					highlightSprite.moveTo(
						bodySprite.x + int((bodySprite.width - highlightSprite.width) / 2),
						bodySprite.y + int((bodySprite.height - highlightSprite.height) / 2)
					);
					var bodyIndex:int = frameContainer.getChildIndex(bodySprite);
					frameContainer.addChildAt(highlightSprite, bodyIndex);
				}
			}
			
			TextureExplorerComponent.prepareBitmapDatasForTetxures(listBodyTextures, onHighlightTextureReady);
		}
		
		private function angleToFrame(angle:int):int
		{
			var frameScale:int = 1;
			
			angle = Math.round(angle / 10) * 10;
			while (angle < 0)
			{
				angle += 360;
			}
			angle = angle % 360;
			
			var frame:int = 0;
			if (!_isSymmetric)
			{
				if (angle >= 0 && angle < 90)
				{
					frame = angle / 10 + 11;
					frameScale = -1;
				}
				else if (angle == 90)
				{
					frame = 0;
					frameScale = 1;
				}
				else if (angle > 90 && angle < 180)
				{
					frame = (180 - angle) / 10 + 11;
					frameScale = 1;
				}
				else if (angle >= 180 && angle < 270)
				{
					frame = (angle - 180) / 10 + 1;
					frameScale = -1;
				}
				else
				{
					frame = (360 - angle) / 10 + 1;
					frameScale = 1;
				}
			}
			else
			{
				frameScale = angle > 0 && angle < 90 || angle > 180 && angle < 270 ? -1 : 1;
				
				if (angle >= 0 && angle < 90)
				{
					frame = angle / 10;
				}
				else if (angle >= 90 && angle < 180)
				{
					frame = (180 - angle) / 10;
				}
				else if (angle >= 180 && angle < 270)
				{
					frame = (angle - 180) / 10;
				}
				else
				{
					frame = (360 - angle) / 10;
				}
			}
			
			return frameScale * frame;
		}
		
		private var _hashHighlightTextures:Object;
		private function onHighlightTextureReady():void
		{
			for (var textureID:String in _hashHighlightTextures)
			{
				if (_hashHighlightTextures[textureID] == null)
				{
					continue;
				}
				
				var highlightTextureID:String = textureID + 'hl';
				var bmd:BitmapData = TextureExplorerComponent.getBitmapDataForTexture(textureID);
				
				var highlightBitmapData:BitmapData = new BitmapData(Math.ceil(bmd.width / 4), Math.ceil(bmd.height / 4), true, 0x00000000);
				highlightBitmapData = new BitmapData(Math.ceil(bmd.width * 0.3), Math.ceil(bmd.height * 0.3), true, 0x00000000);
				highlightBitmapData.draw(
					bmd,
					new Matrix(0.25, 0, 0, 0.25, bmd.width * 0.025, bmd.height * 0.025)
				);
				highlightBitmapData.applyFilter(
					highlightBitmapData,
					highlightBitmapData.rect,
					new Point(),
					new GlowFilter(0xFFFFFF, 1, 2, 2, 4, 3)
				);
				highlightBitmapData.applyFilter(
					highlightBitmapData,
					highlightBitmapData.rect,
					new Point(),
					new ColorMatrixFilter([
						1, 1, 1, 0, 0,
						1, 1, 1, 0, 0,
						1, 1, 1, 0, 0,
						0, 0, 0, 1, 0
					])
				);
				
				TextureManager.createTexture(highlightBitmapData, highlightTextureID);
				
				var listBodySprites:Array = _hashHighlightTextures[textureID];
				for (var i:int = 0; i < listBodySprites.length; i++)
				{
					var bodySprite:Sprite3D = listBodySprites[i];
					var bodyIndex:int = bodySprite.parent.getChildIndex(bodySprite);
					
					var highlightSprite:Sprite3D = Sprite3D.createFromTexture(highlightTextureID);
					highlightSprite.setScale(4 * bodySprite.scaleX, 4);
					highlightSprite.name = 'highlight';
					highlightSprite.darkenColor = 0xFFFF7A;
					highlightSprite.moveTo(
						bodySprite.x + (bodySprite.width - highlightSprite.width) / 2,
						bodySprite.y + (bodySprite.height - highlightSprite.height) / 2
					);
					bodySprite.parent.addChildAt(highlightSprite, bodyIndex);
					_hashHighlightTextures[textureID] = null;
				}
			}
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		protected function onPlaceAnchors(event:Event):void
		{
			var prefabContainer:Sprite3DContainer = _parent.content;
			
			if (prefabContainer == null)
			{
				Alert.show("Need to create prefab first");
				return;
			}
			
			var train0:Sprite3DContainer = prefabContainer.getChildByName("train00") as Sprite3DContainer;
			var train9:Sprite3DContainer = prefabContainer.getChildByName("train09") as Sprite3DContainer;
			
			if (train0 == null || train9 == null)
			{
				Alert.show("Invalid prefab structure. It was reset or some elements were removed.");
				return;
			}
			
			var hashAnchors0:Object;
			for (var i:int = 0; i < train0.numChildren; i++)
			{
				var child:Sprite3D = train0.getChildAt(i);
				if (child.name == null || child.name.indexOf("anchor_") != 0)
				{
					continue;
				}
				
				if (hashAnchors0 == null)
				{
					hashAnchors0 = new Object();
				}
				
				if (hashAnchors0[child.name] != null)
				{
					Alert.show("Duplicate anchor " + child.name + " found in train00. Remove or rename it.");
					return;
				}
				
				hashAnchors0[child.name] = child;
			}
			
			if (hashAnchors0 == null)
			{
				Alert.show("No anchors in train00. Need anchors in train00 and train09 to interpolate them.");
				return;
			}
			
			var hashAnchors9:Object;
			for (i = 0; i < train9.numChildren; i++)
			{
				child = train9.getChildAt(i);
				if (child.name == null || child.name.indexOf("anchor_") != 0)
				{
					continue;
				}
				
				if (hashAnchors9 == null)
				{
					hashAnchors9 = new Object();
				}
				
				if (hashAnchors9[child.name] != null)
				{
					Alert.show("Duplicate anchor " + child.name + " found in train09. Remove or rename it.");
					return;
				}
				
				hashAnchors9[child.name] = child;
			}
			
			if (hashAnchors9 == null)
			{
				Alert.show("No anchors in train09. Need anchors in train00 and train09 to interpolate them.");
				return;
			}
			
			placeAnchors(hashAnchors0, hashAnchors9);
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		protected function onMirrorAnchors(event:Event):void
		{
			mirrorAnchors();
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
		private function placeAnchors(hashAnchors0:Object, hashAnchors9:Object):void
		{
			var hashAnchorsX:Object = new Object();
			var hashAnchorsY:Object = new Object();
			var hashAnchorsX0:Object = new Object();
			var hashAnchorsY0:Object = new Object();
			
			for (var anchorID:String in hashAnchors0)
			{
				var anchor0:Sprite3D = hashAnchors0[anchorID];
				var anchor9:Sprite3D = hashAnchors9[anchorID];
				
				hashAnchorsX[anchorID] = anchor9.x - anchor0.x;
				hashAnchorsY[anchorID] = anchor0.y - anchor9.y;
				hashAnchorsX0[anchorID] = anchor0.x;
				hashAnchorsY0[anchorID] = anchor9.y;
			}
			
			for (var i:int = 0; i < 360; i += 10)
			{
				if (i == 0 || i == 90)
				{
					continue;
				}
				
				var frame:int = (360 - i) + 90;
				while (frame >= 360)
				{
					frame -= 360;
				}
				
				frame /= 10;
				
				var colorFillShader:Shader3D = Shader3DFactory.getInstance().getShaderInstance(null, false, Shader3D.TEXTURE_DONT_USE_TEXTURE);
				
				var frameString:String = StringUtils.prepend(frame.toString(), '0', 2);
				var prefabContainer:Sprite3DContainer = _parent.content;
				var frameView:Sprite3DContainer = prefabContainer.getChildByName("train" + frameString) as Sprite3DContainer;
				for (anchorID in hashAnchors0)
				{
					var anchor:Sprite3D = frameView.getChildByName(anchorID);
					if (anchor == null)
					{
						anchor = new Sprite3D();
						anchor.setSize(3, 3);
						anchor.darkenColor = 0x00FF00;
						anchor.name = anchorID;
						anchor.shader = colorFillShader;
						frameView.addChild(anchor);
					}
					
					anchor.moveTo(
						hashAnchorsX0[anchorID] + Math.round(hashAnchorsX[anchorID] * Math.cos(i / 180 * Math.PI)),
						hashAnchorsY0[anchorID] + Math.round(hashAnchorsY[anchorID] * Math.sin(i / 180 * Math.PI))
					);
				}
				
			}
		}
		
		private function mirrorAnchors():void
		{
			var frame00:Sprite3DContainer = _parent.content.getChildByName("train00") as Sprite3DContainer;
			var isSymmetric:Boolean = frame00.getChildByName("body").textureID.match('_body_18') != null;
			var frameWidth:int = Math.abs(frame00.getChildByName("body").width);
			var frameHeight:int = Math.abs(frame00.getChildByName("body").height);
			
			if (isSymmetric)
			{
				var frame:Sprite3DContainer = _parent.content.getChildByName("train00") as Sprite3DContainer;
				for (var j:int = 0; j < frame.numChildren; j++)
				{
					var child:Sprite3D = frame.getChildAt(j);
					if (child.name != null && child.name.indexOf('water') != -1)
					{
						var frameOpposite:Sprite3DContainer = _parent.content.getChildByName("train18") as Sprite3DContainer;
						var anchor:Sprite3D = frameOpposite.getChildByName(child.name);
						if (anchor == null)
						{
							anchor = Sprite3DUtils.createRect(3, 3, 0x00FF00);
							anchor.name = child.name;
							frameOpposite.addChild(anchor);
						}
						
						anchor.moveTo(child.x, frameHeight - child.y);
					}
				}
				
				frame = _parent.content.getChildByName("train09") as Sprite3DContainer;
				for (j = 0; j < frame.numChildren; j++)
				{
					child = frame.getChildAt(j);
					if (child.name != null && child.name.indexOf('water') != -1)
					{
						frameOpposite = _parent.content.getChildByName("train27") as Sprite3DContainer;
						anchor = frameOpposite.getChildByName(child.name);
						if (anchor == null)
						{
							anchor = Sprite3DUtils.createRect(3, 3, 0x00FF00);
							anchor.name = child.name;
							frameOpposite.addChild(anchor);
						}
						
						anchor.moveTo(frameWidth - child.x, child.y);
					}
				}
			}
			
			for (var i:int = 1; i <= 8; i++)
			{
				frame = _parent.content.getChildByName("train" + StringUtils.prepend(i.toString(), '0', 2)) as Sprite3DContainer;
				for (j = 0; j < frame.numChildren; j++)
				{
					child = frame.getChildAt(j);
					if (child.name != null && child.name.indexOf('water') != -1)
					{
						frameOpposite = _parent.content.getChildByName("train" + StringUtils.prepend((36 - i).toString(), '0', 2)) as Sprite3DContainer;
						anchor = frameOpposite.getChildByName(child.name);
						if (anchor == null)
						{
							anchor = Sprite3DUtils.createRect(3, 3, 0x00FF00);
							anchor.name = child.name;
							frameOpposite.addChild(anchor);
						}
						
						anchor.moveTo(frameWidth - child.x, child.y);
						
						if (isSymmetric)
						{
							frameOpposite = _parent.content.getChildByName("train" + StringUtils.prepend((18 - i).toString(), '0', 2)) as Sprite3DContainer;
							anchor = frameOpposite.getChildByName(child.name);
							if (anchor == null)
							{
								anchor = Sprite3DUtils.createRect(3, 3, 0x00FF00);
								anchor.name = child.name;
								frameOpposite.addChild(anchor);
							}
							
							anchor.moveTo(child.x, frameHeight -  child.y);
						}
					}
				}
			}
			
			for (i = 10; i <= 17; i++)
			{
				frame = _parent.content.getChildByName("train" + StringUtils.prepend(i.toString(), '0', 2)) as Sprite3DContainer;
				for (j = 0; j < frame.numChildren; j++)
				{
					child = frame.getChildAt(j);
					if (child.name != null && child.name.indexOf('water') != -1)
					{
						frameOpposite = _parent.content.getChildByName("train" + StringUtils.prepend((36 - i).toString(), '0', 2)) as Sprite3DContainer;
						anchor = frameOpposite.getChildByName(child.name);
						if (anchor == null)
						{
							anchor = Sprite3DUtils.createRect(3, 3, 0x00FF00);
							anchor.name = child.name;
							frameOpposite.addChild(anchor);
						}
						
						anchor.moveTo(frameWidth - child.x, child.y);
					}
				}
			}
		}
		
		private var _clipboard:Object;
		protected function onCopyAnchors(event:Event):void
		{
			_clipboard = new Array();
			
			for (var i:int = 0; i < 36; i++)
			{
				var frame:Sprite3DContainer = _parent.content.getChildByName("train" + StringUtils.prepend(i.toString(), '0', 2)) as Sprite3DContainer;
				for (var j:int = 0; j < frame.numChildren; j++)
				{
					var child:Sprite3D = frame.getChildAt(j);
					if (child.name != null && child.name.indexOf('water') != -1)
					{
						if (_clipboard[i] == null)
						{
							_clipboard[i] = new Object();
						}
						
						_clipboard[i][child.name] = {
							x: child.x,
							y: child.y
						};
					}
				}
			}
			
		}
		
		protected function onPasteAnchors(event:Event):void
		{
			if (_clipboard == null)
			{
				return;
			}
			
			if (!(_clipboard is Array))
			{
				return;
			}
			
			for (var i:int = 0; i < 36; i++)
			{
				var frame:Sprite3DContainer = _parent.content.getChildByName("train" + StringUtils.prepend(i.toString(), '0', 2)) as Sprite3DContainer;
				var frameAnchorsData:Object = _clipboard[i];
				for (var anchorName:String in frameAnchorsData)
				{
					var child:Sprite3D = frame.getChildByName(anchorName);
					if (child == null)
					{
						child = Sprite3DUtils.createRect(3, 3, 0x00FF00);
						child.name = anchorName;
						frame.addChild(child);
					}
					
					child.moveTo(frameAnchorsData[anchorName].x, frameAnchorsData[anchorName].y);
				}
			}
			
			dispatchEvent(
				new Event(Event.COMPLETE)
			);
		}
		
	}
}