package model
{
	import components.prefab_editor.TextureExplorerComponent;
	
	import molehill.core.sprite.Sprite3DContainer;

	public interface IPrefabEditorPluginHost
	{
		function get content():Sprite3DContainer;
		function get textureExplorer():TextureExplorerComponent;
	}
}