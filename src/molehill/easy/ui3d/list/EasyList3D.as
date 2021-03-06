package molehill.easy.ui3d.list
{
	import easy.collections.Collection;
	import easy.collections.ISimpleCollection;
	import easy.collections.events.CollectionEvent;
	import easy.core.IFactory;
	import easy.core.events.ListEvent;
	import easy.ui.EasySprite;
	import easy.ui.IEasyItemRenderer;
	
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import molehill.core.events.Input3DMouseEvent;
	import molehill.core.sprite.Sprite3D;
	import molehill.core.sprite.Sprite3DContainer;
	
	import resources.IDisposable;
	
	public class EasyList3D extends Sprite3DContainer
	{
		public function EasyList3D()
		{
			super();
		}
		
		public function dispose():void
		{
			for each(var itemRenderer:IDisposable in _listFreeItemRenderers)
			{
				if (itemRenderer != null)
					itemRenderer.dispose();
			}
		}
		
		private var _dataSource:*;
		public function get dataSource():*
		{
			return _dataSource;
		}
		public function set dataSource(value:*):void
		{
			if (_dataSource != null)
			{
				if (_dataSource is ISimpleCollection)
				{
					(_dataSource as ISimpleCollection).removeEventListener(CollectionEvent.COLLECTION_CHANGED, onDataSourceChanged);
				}
			}	
			
			_dataSource = value;
			
			if (_dataSource != null)
			{
				if (_dataSource is ISimpleCollection)
				{
					(_dataSource as ISimpleCollection).addEventListener(CollectionEvent.COLLECTION_CHANGED, onDataSourceChanged);
				}
			}
			
			updateOnDataSourceChange();
		}
		
		protected function updateOnDataSourceChange():void
		{
			unselectAll();
			update();
		}
		
		public final function get numItems():int
		{
			return _dataSource != null ? _dataSource['length'] : 0;
		}
		
		protected function getItemData(index:int):*
		{
			return _dataSource[index];
		}
		
		protected function getItemIndex(itemData:*):int
		{
			if (_dataSource == null)
				return -1;
			
			if (_dataSource is Array)
			{
				var dataList:Array = _dataSource as Array;
				return dataList.indexOf(itemData)
			}
			
			if (_dataSource is Collection)
			{
				var dataCollection:Collection = _dataSource as Collection;
				return dataCollection.indexOf(itemData);
			}
			
			return -1;
		}
		
		private var _itemRendererFactory:IFactory;
		public function get itemRendererFactory():IFactory
		{
			return _itemRendererFactory;
		}
		public function set itemRendererFactory(value:IFactory):void
		{
			_itemRendererFactory = value;
		}
		
		private var _emptyItemRendererFactory:IFactory;
		public function get emptyItemRendererFactory():IFactory
		{
			return _emptyItemRendererFactory;
		}
		public function set emptyItemRendererFactory(value:IFactory):void
		{
			_emptyItemRendererFactory = value;
		}
		
		/*** --------------------------------------------------------- ***/
		/***                         Selection                         ***/
		/*** --------------------------------------------------------- ***/
		private var _allowSelection:Boolean = true;
		private var _allowMultipleSelection:Boolean = false;
		
		//private var _selectedIndex:int;
		private var _selectedItem:*;
		
		private var _dictSelectedItems:Array;
		
		public function get allowMultipleSelection():Boolean
		{
			return _allowMultipleSelection;
		}
		public function set allowMultipleSelection(value:Boolean):void
		{
			_allowMultipleSelection = value;
			
			if (_allowMultipleSelection && _dictSelectedItems == null)
				_dictSelectedItems = new Array();
		}

		private var _allowHighlight:Boolean = true;
		public function get allowHighlight():Boolean
		{
			return _allowHighlight;
		}
		public function set allowHighlight(value:Boolean):void
		{
			_allowHighlight = value;
		}
		
		private var _numMaxSelectedItems:int = int.MAX_VALUE;
		public function get numMaxSelectedItems():int
		{
			return _numMaxSelectedItems;
		}
		
		public function set numMaxSelectedItems(value:int):void
		{
			_numMaxSelectedItems = value;
		}
		
		public function get numSelectedItems():int
		{
			return _dictSelectedItems.length;
		}
		
		public function get allowSelection():Boolean
		{
			return _allowSelection;
		}
		public function set allowSelection(value:Boolean):void
		{
			_allowSelection = value;
		}
		
		/*
			TO DO: implement when it will be necessary
		public function get selectedIndex():int
		{
			return -1;
		}
		public function set selectedIndex(value:int):void
		{
			//not implemented
		}
		
		public function get selectedIndices():Array
		{
			return null;//not implemented
		}
		public function set selectedIndices(value:Array):void
		{
			//not implemented
		}
		*/
		
		public function get selectedItem():*
		{
			return _selectedItem;
		}
		public function set selectedItem(value:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				_dictSelectedItems = new Array();
				_dictSelectedItems.push(_selectedItem);
			}
			else
			{
				_selectedItem = value;
				//_selectedIndex = -1;// ?????????????????? ???? get-??????
			}
			update();
			
		}
		
		public function get selectedItems():Array
		{
			var items:Array;
			if (_allowMultipleSelection)
			{
				items = _dictSelectedItems.concat();
			}
			else
			{
				items = _selectedItem != null ? [_selectedItem] : [];
			}
			
			return items;
		}
		public function set selectedItems(value:Array):void
		{
			setSelectedItems(value);
		}	
		
		/**
		 * value:Array or value:Collection
		 */
		protected function setSelectedItems(value:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				_dictSelectedItems = new Array();
				
				if (value != null && value.length > 0)
				{
					_selectedItem = value[0];
					for each(var element:* in value)
					{
						if (_dictSelectedItems.indexOf(element) == -1)
						{
							_dictSelectedItems.push(element);
						}
						
						if (_dictSelectedItems.length >= _numMaxSelectedItems)
						{
							break;
						}
					}
				}
				
				//_selectedIndex = -1;// ?????????????????????? ???? get-??????
			}
			else
			{
				if (value != null && value.length > 0)
				{
					_selectedItem = value[0];
					//_selectedIndex = -1;// ?????????????????????? ???? get-??????
				}
				else
				{
					_selectedItem = null;
					//_selectedIndex = -1;
				}
			}
			update();
			
		}
		
		public function selectAll():void
		{
			setSelectedItems(_dataSource);
		}
		
		public function unselectAll():void
		{
			selectedItems = null;
		}
		
		public function selectItem(itemData:*):void
		{
			if(!_allowSelection)
			{
				return;
			}
			if (_allowMultipleSelection)
			{
				if (numSelectedItems >= _numMaxSelectedItems) 
				{
					return;
				}
				
				if (_dictSelectedItems.indexOf(itemData) == -1)
				{
					_dictSelectedItems.push(itemData);
				}
				
				if (_selectedItem == null)
					_selectedItem = itemData;
				//_selectedIndex =
				// ???????????? ???????????? ???? ????????, ?????? ?????????????????????????? ?????????????????????? ???? get-??????
			}
			else
			{
				_selectedItem = itemData;
				//_selectedIndex = -1;
			}
		}
		//---
		protected function unselectItem(itemData:*):void
		{
			if (_allowMultipleSelection)
			{
				var index:int = _dictSelectedItems.indexOf(itemData);
				if (index != -1)
				{
					_dictSelectedItems.splice(index, 1);
				}
			}
			else
			{
				if (_selectedItem == itemData)
				{
					_selectedItem = null;
					//_selectedIndex = -1;
				}
			}
		}
		
		protected function isItemSelected(itemData:*):Boolean
		{
			if(!_allowSelection)
			{
				return false;
			}
			var itemSelected:Boolean = false;
			if (_allowMultipleSelection)
			{
				itemSelected = _dictSelectedItems.indexOf(itemData) != -1;
			}
			else
			{
				itemSelected = _selectedItem === itemData;
			}
			
			return itemSelected;
		}
		//---------------------------------------------------------------------------------------
		
		/*** --------------------------------------------------------- ***/
		/***                 Item's Renderers Management               ***/
		/*** --------------------------------------------------------- ***/
		protected function initItemRenderer(itemRenderer:IEasyItemRenderer):void
		{
			//override
		}
		
		private function createItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:Sprite3D = _itemRendererFactory.newInstance() as Sprite3D;
			itemRenderer.addEventListener(Input3DMouseEvent.CLICK, onItemRendererClick);
			itemRenderer.addEventListener(Input3DMouseEvent.MOUSE_OVER, onItemRendererRollOver);
			itemRenderer.addEventListener(Input3DMouseEvent.MOUSE_OUT, onItemRendererRollOut);
			
			initItemRenderer(itemRenderer as IEasyItemRenderer);
			
			return itemRenderer as IEasyItemRenderer;
		}
		
		private var _listFreeItemRenderers:Array = new Array();
		protected final function getItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:IEasyItemRenderer = null;
			
			while ( _listFreeItemRenderers.length > 0 && itemRenderer == null )
			{
				itemRenderer = _listFreeItemRenderers.pop() as IEasyItemRenderer;
			}
			
			if (itemRenderer == null)
			{
				itemRenderer = createItemRenderer();
			}
			
			addChild(itemRenderer as Sprite3D);
			
			
			return itemRenderer;
		}
		//----
		protected final function freeItemRenderer(itemRenderer:IEasyItemRenderer):void
		{
			itemRenderer.itemData = null;
			itemRenderer.selected = false;
			itemRenderer.highlighted = false;
			
			var displayObject:Sprite3D = itemRenderer as Sprite3D;
			if ( displayObject != null && displayObject.parent != null )
			{
				displayObject.parent.removeChild(displayObject);
			}
			
			_listFreeItemRenderers.push(
				itemRenderer
			);
		}
		
		protected var _dictCurrentStateItemRenderersByData:Dictionary = new Dictionary();
		
		
		private function createEmptyItemRenderer():IEasyItemRenderer
		{
			var factory:IFactory = _emptyItemRendererFactory != null ? _emptyItemRendererFactory : _itemRendererFactory;
			
			var itemRenderer:IEasyItemRenderer = factory.newInstance() as IEasyItemRenderer;
			itemRenderer.itemData = null;
			itemRenderer.selected = false;
			itemRenderer.highlighted = false;
			
			initItemRenderer(itemRenderer);
			itemRenderer.update();
			
			return itemRenderer;
		}
		
		private var _listFreeEmptyItemRenderers:Array = new Array();
		private var _listUsedEmptyItemRenderers:Array;
		
		protected final function getEmptyItemRenderer():IEasyItemRenderer
		{
			var itemRenderer:IEasyItemRenderer = null;
			
			while ( _listFreeEmptyItemRenderers.length > 0 && itemRenderer == null )
			{
				itemRenderer = _listFreeEmptyItemRenderers.pop() as IEasyItemRenderer;
			}
			
			if (itemRenderer == null)
			{
				itemRenderer = createEmptyItemRenderer();
			}
			
			if (_listUsedEmptyItemRenderers == null)
			{
				_listUsedEmptyItemRenderers = new Array();
			}
			_listUsedEmptyItemRenderers.push(itemRenderer);
			addChild(itemRenderer as Sprite3D);
			
			return itemRenderer;
		}
		//----
		protected final function freeAllEmptyItemRenderers():void
		{
			if (_listUsedEmptyItemRenderers != null)
			{
				for each(var itemRenderer:IEasyItemRenderer in _listUsedEmptyItemRenderers)
				{
					var displayObject:Sprite3D = itemRenderer as Sprite3D;
					if ( displayObject != null && contains(displayObject) )
					{
						removeChild(displayObject);
					}
					
					_listFreeEmptyItemRenderers.push(itemRenderer);
				}				
				
				//_listFreeEmptyItemRenderers.splice(_listFreeEmptyItemRenderers.length, 0, _listUsedEmptyItemRenderers);
				_listUsedEmptyItemRenderers = null;
			}
		}
		//---------------------------------------------------------------------------------------
		
		/*** --------------------------------------------------------- ***/
		/***                           Mouse                           ***/
		/*** --------------------------------------------------------- ***/
		private function onItemRendererClick(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			var itemData:* = itemRenderer.itemData;
			
			if (_itemClickEnabled)
			{
				dispatchEvent(
					new ListEvent(ListEvent.ITEM_CLICK, itemData)
				); 
			}
			
			if (!_allowSelection || !itemRenderer.isSelectable)
				return;
			
			if (itemData == null)
				return;
			
			if (_allowMultipleSelection)
			{
				if ( isItemSelected(itemData) )
				{
					unselectItem(itemData);
				}
				else if (numSelectedItems < numMaxSelectedItems)
				{
					selectItem(itemData);
				}
			}
			else
			{
				selectItem(itemData);
			}
			
			update();
		}
		//---
		private function onItemRendererRollOver(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			if(allowHighlight)
			{
				itemRenderer.highlighted = true;
				itemRenderer.update();
			}
		}
		//---
		private function onItemRendererRollOut(event:Input3DMouseEvent):void
		{
			var itemRenderer:IEasyItemRenderer = event.currentTarget as IEasyItemRenderer;
			if (itemRenderer == null)
				return;
			
			if(allowHighlight)
			{
				itemRenderer.highlighted = false;
				itemRenderer.update();
			}
		}		
		//---------------------------------------------------------------------------------------
		private function onDataSourceChanged(event:Event):void
		{
			updateOnDataSourceChange();
		}
		
		private var _delayedUpdate:Boolean = false;
		override protected function onAddedToScene():void
		{
			if (_delayedUpdate)
			{
				doUpdate();
				
				_delayedUpdate = false;
			}
		}
		
		private var _updateAnyway:Boolean = false;
		public function get updateAnyway():Boolean
		{
			return _updateAnyway;
		}
		
		public function set updateAnyway(value:Boolean):void
		{
			_updateAnyway = value;
		}
		
		public function update():void
		{
			if ((scene != null && scene.isActive) || (_updateAnyway))
			{
				doUpdate();
			}
			else
			{
				_delayedUpdate = true;
			}
		}
		
		protected function doUpdate():void
		{
			
		}
		
		private var _itemClickEnabled:Boolean = false;
		public function get itemClickEnabled():Boolean
		{
			return _itemClickEnabled;
		}
		public function set itemClickEnabled(value:Boolean):void
		{
			_itemClickEnabled = value;
		}
	}
}