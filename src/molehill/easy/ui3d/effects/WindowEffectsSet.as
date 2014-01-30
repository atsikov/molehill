package molehill.easy.ui3d.effects
{
	public class WindowEffectsSet
	{
		public function WindowEffectsSet(
			show:Effect = null,
			showModalBG:Effect = null,
			close:Effect = null,
			closeModalBG:Effect = null
		)
		{
			_show = show;
			_showModalBG = showModalBG;
			_close = close;
			_closeModalBG = closeModalBG;
		}
		
		private var _show:Effect;
		
		public function get show():Effect
		{
			return _show;
		}
		
		private var _showModalBG:Effect;
		
		public function get showModalBG():Effect
		{
			return _showModalBG;
		}
		
		private var _close:Effect;
		
		public function get close():Effect
		{
			return _close;
		}
		
		private var _closeModalBG:Effect;
		
		public function get closeModalBG():Effect
		{
			return _closeModalBG;
		}
	}
}