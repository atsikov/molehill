package model
{
	import molehill.core.sprite.Sprite3DContainer;
	
	import mx.core.IVisualElement;

	public interface IPrefabEditorPlugin
	{
		function createPrefab(textureID:String, parentContainer:Sprite3DContainer):void
		
		function get pluginPanel():IVisualElement;
	}
}