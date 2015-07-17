package molehill.core.render
{
	import flash.display3D.IndexBuffer3D;
	import flash.display3D.VertexBuffer3D;

	internal class CacheSpriteBatcherBuffers
	{
		private static var _hashCoordsVertexBuffers:Object = new Object();
		private static var _hashColorVertexBuffers:Object = new Object();
		private static var _hashTextureVertexBuffers:Object = new Object();
		private static var _hashIndexBuffers:Object = new Object();
		
		private static function storeBuffer(storage:Object, buffer:Object, numSprites:uint):void
		{
			// cache frequent used buffers only
			if (numSprites > 5 && numSprites != 128)
			{
				buffer.dispose();
				return;
			}
			
			if (storage[numSprites] == null)
			{
				storage[numSprites] = new Array();
			}
			
			storage[numSprites].push(buffer);
		}
		
		private static function getBuffer(storage:Object, numSprites:uint):Object
		{
			var buffer:Object = storage[numSprites] == null || storage[numSprites].length == 0 ? null : storage[numSprites].pop();
			return buffer;
		}
		
		private static function clearBufferStorage(storage:Object):void
		{
			for each (var list:Array in storage)
			{
				while (list.length > 0)
				{
					list.pop().dispose();
				}
			}
		}
		
		// Coords
		public static function storeCoordsVertexBuffer(buffer:VertexBuffer3D, numSprites:uint):void
		{
			storeBuffer(_hashCoordsVertexBuffers, buffer, numSprites);
		}
		
		public static function getCoordsVertexBuffer(numSprites:uint):VertexBuffer3D
		{
			return getBuffer(_hashCoordsVertexBuffers, numSprites) as VertexBuffer3D;
		}
		
		// Color
		public static function storeColorVertexBuffer(buffer:VertexBuffer3D, numSprites:uint):void
		{
			storeBuffer(_hashColorVertexBuffers, buffer, numSprites);
		}
		
		public static function getColorVertexBuffer(numSprites:uint):VertexBuffer3D
		{
			return getBuffer(_hashColorVertexBuffers, numSprites) as VertexBuffer3D;
		}
		
		// Texture
		public static function storeTextureVertexBuffer(buffer:VertexBuffer3D, numSprites:uint):void
		{
			storeBuffer(_hashTextureVertexBuffers, buffer, numSprites);
		}
		
		public static function getTextureVertexBuffer(numSprites:uint):VertexBuffer3D
		{
			return getBuffer(_hashTextureVertexBuffers, numSprites) as VertexBuffer3D;
		}
		
		// Index
		public static function storeIndexBuffer(buffer:IndexBuffer3D, numSprites:uint):void
		{
			storeBuffer(_hashIndexBuffers, buffer, numSprites);
		}
		
		public static function getIndexBuffer(numSprites:uint):IndexBuffer3D
		{
			return getBuffer(_hashIndexBuffers, numSprites) as IndexBuffer3D;
		}
		
		public static function clearCache():void
		{
			clearBufferStorage(_hashCoordsVertexBuffers);
			clearBufferStorage(_hashColorVertexBuffers);
			clearBufferStorage(_hashTextureVertexBuffers);
			clearBufferStorage(_hashIndexBuffers);
		}
	}
}