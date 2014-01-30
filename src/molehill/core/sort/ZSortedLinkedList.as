package molehill.core.sort
{	
	import flash.utils.Dictionary;

	public class ZSortedLinkedList
	{
		private var _head:ZSortedLinkedListNode = null;
		
		private var _tail:ZSortedLinkedListNode = null;
		
		public function ZSortedLinkedList()
		{
			
		}
		
		private var _dictNodeByChild:Dictionary = new Dictionary();
		
		private function updateNodePlace(node:ZSortedLinkedListNode):Boolean
		{
			var child:IZSortDisplayObject = node.child;
			var childLayerIndex:int = child is IZSortDisplayObject ? (child as IZSortDisplayObject).layerIndex : 0;
			
			var x:int = child.x;
			var y:int = child.y;
			
			var currentNode:ZSortedLinkedListNode;
			var currentChild:IZSortDisplayObject;
			var currentChildLayerIndex:int;
			var currentX:int;
			var currentY:int;
			
			// Просматриваем список назад
			
			var isMoved:Boolean = false;
			
			currentNode = node.prev;
			while (currentNode != null)
			{
				currentChild = currentNode.child;
				currentChildLayerIndex = currentChild is IZSortDisplayObject ? (currentChild as IZSortDisplayObject).layerIndex : 0;
				
				//if (isCurrentChildGround && !isChildGround)
				//	break;
				
				if (childLayerIndex < currentChildLayerIndex)
				{
					// сдвигаем объект "земли" безоговорочно вниз
				}
				else if (childLayerIndex == currentChildLayerIndex)//типы слоев объектов совпадают
				{
					currentX = currentChild.x;
					currentY = currentChild.y;
					if (currentY < y || currentY == y && currentX < x)
						break;
				}
				else
				{
					//граница разных типов слоев объектов
					break;
				}
				
				isMoved = true;
				currentNode = currentNode.prev;
			}
			if (isMoved)
			{
				removeNode(node);
				
				if (currentNode == null)
				{
					addNodeToHead(node);
				}
				else
				{
					addNodeAfter(currentNode, node);
				}
				
				return true;
			}
			
			// Просматриваем список вперед
			
			isMoved = false;
			currentNode = node.next;
			while (currentNode != null)
			{
				currentChild = currentNode.child;
				currentChildLayerIndex = currentChild is IZSortDisplayObject ? (currentChild as IZSortDisplayObject).layerIndex : 0;
				
				//if (isChildGround && (!isCurrentChildGround))
				//	break;
				
				if (childLayerIndex > currentChildLayerIndex)
				{
					// сдвигаем объект "земли" безоговорочно вниз
				}
				else if (childLayerIndex == currentChildLayerIndex)//типы слоев объектов совпадают
				{
					currentX = currentChild.x;
					currentY = currentChild.y;				
					if (currentY > y || currentY == y && currentX > x)
						break;
				}
				else
				{
					//граница разных типов слоев объектов
					break;
				}
				
				isMoved = true;
				currentNode = currentNode.next;
			}
			if (isMoved)
			{
				removeNode(node);
				
				if (currentNode == null)
				{
					addNodeToTail(node);
				}
				else
				{
					addNodeBefore(currentNode, node);
				}
				return true;
			}
			
			return false;
		}
		
		private function addNodeAfter(prev:ZSortedLinkedListNode, node:ZSortedLinkedListNode):void
		{
			var next:ZSortedLinkedListNode = prev.next;
			prev.next = node;
			
			node.prev = prev;
			node.next = next;
			
			if (next != null)
			{
				next.prev = node;
			}
			else
			{
				_tail = node;
			}
		}
		
		private function addNodeBefore(next:ZSortedLinkedListNode, node:ZSortedLinkedListNode):void
		{
			var prev:ZSortedLinkedListNode = next.prev;
			next.prev = node;
			
			node.prev = prev;
			node.next = next;
			
			if (prev != null)
			{
				prev.next = node;
			}
			else
			{
				_head = node;
			}
		}
		
		private function removeNode(node:ZSortedLinkedListNode):void
		{
			var prev:ZSortedLinkedListNode = node.prev;
			var next:ZSortedLinkedListNode = node.next;
			
			if (prev != null)
			{
				prev.next = next;
				if (next == null)
				{
					_tail = prev;
					_tail.next = null;
				}	
				else
				{
					next.prev = prev;
				}			
			}
			else
			{				
				_head = next;			
				
				if (_head != null)
				{
					_head.prev = null;
				}	
			}
			
			node.prev = null;
			node.next = null;
		}
		
		private function addNodeToHead(node:ZSortedLinkedListNode):void
		{	
			if (_head == null)
			{
				node.prev = null;
				node.next = null;
				_tail = _head = node;
			}
			else
			{
				_head.prev = node;
				node.prev = null;
				node.next = _head;
				_head = node;
			}
		}
		
		private function addNodeToTail(element:ZSortedLinkedListNode):void
		{
			if (_tail == null)
			{
				element.prev = null;
				element.next = null;
				_tail = _head = element;
			}
			else
			{
				_tail.next = element;
				element.prev = _tail;
				element.next = null;
				_tail = element;
			}
		}
		
		/*** ------------------------ ***/
		/***       Public methods     ***/
		/*** ------------------------ ***/
		
		public function add(child:IZSortDisplayObject):Boolean
		{
			var node:ZSortedLinkedListNode = _dictNodeByChild[child];
			if (node == null)
			{
				node = new ZSortedLinkedListNode();
				node.child = child;
				_dictNodeByChild[child] = node;
				addNodeToHead(node);
			}
			
			return updateNodePlace(node);
		}
		
		public function updatePlace(child:IZSortDisplayObject):Boolean
		{
			var node:ZSortedLinkedListNode = _dictNodeByChild[child];
			return node != null && updateNodePlace(node);
		}
		
		public function getNextOf(child:IZSortDisplayObject):IZSortDisplayObject
		{
			var node:ZSortedLinkedListNode = _dictNodeByChild[child];
			var next:ZSortedLinkedListNode = node.next;
			return next != null ? next.child : null;
		}
		
		public function remove(child:IZSortDisplayObject):void
		{
			var node:ZSortedLinkedListNode = _dictNodeByChild[child];
			if (node != null)
			{
				removeNode(node);
				delete _dictNodeByChild[child];
			}
		}
		
		public function get head():ZSortedLinkedListNode
		{
			return _head;
		}
	}
}