package net.wonderfl.editor.livecoding 
{
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.external.ExternalInterface;
	import mx.effects.easing.Quadratic;
	import net.wonderfl.editor.AS3Viewer;
	import net.wonderfl.utils.removeFromParent;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	[Event(name = 'close', type = 'flash.events.Event')]
	[Event(name = 'LiveCodingEvent_JOINED', type = 'net.wonderfl.editor.livecoding.LiveCodingEvent')]
	public class LiveCodingViewerPanel extends LiveCodingPanel
	{
		[Embed(source = '../../../../../assets/on_live.png')]
		private var _onClass:Class;
		private var _onImage:Bitmap = new _onClass;
		private var _isSync:Boolean = true;
		private const BLINK_PERIOD:int = 48;
		private var _blink_count:int = 0;
		//private var _syncButton:CheckBox;
		private var _commandList:Array = [];
		
		private var _viewer:AS3Viewer;
		private var _source:String = '';
		
		public function LiveCodingViewerPanel($viewer:AS3Viewer) {
			_viewer = $viewer;
		}
		
		override public function init($chatWindowOpen:Boolean = false):void 
		{
			super.init($chatWindowOpen);
			
			addChild(_onImage);
			_socket.addEventListener(LiveCodingEvent.RELAYED, relayed);
		}
		
		private function relayed(e:LiveCodingEvent):void 
		{
			trace("viewer : " + e);
			if (!_isLive) {
				start();
			}
			var method:Function;
			switch (e.data.command) {
			case LiveCoding.REPLACE_TEXT:
				method = replaceText;
				break;
			case LiveCoding.SET_SELECTION:
				method = setSelection;
				break;
			case LiveCoding.SEND_CURRENT_TEXT:
				method = sendCurrentText;
				break;
			case LiveCoding.SWF_RELOADED:
				method = SWFReloaded;
				break;
			case LiveCoding.CLOSED:
				method = closed;
				break;
			case LiveCoding.SCROLL_V:
				method = scrollV;
				break;
			case LiveCoding.SCROLL_H:
				method = scrollH;
				break;
			}
			
			if (method != null) {
				var args:Array = e.data.args;
				method.apply(null, args);
			}
		}
		
		
		private function replaceText($beginIndex:int, $endIndex:int, $newText:String):void 
		{
			if ($beginIndex == $endIndex && $newText.length == 0) return;
			
			_viewer.slowDownParser();
			_source = _source.substring(0, $beginIndex) + $newText + substring($endIndex);
			_viewer.onReplaceText($beginIndex, $endIndex, $newText);
			_viewer.updateLineNumbers();
		}
		
		private function setSelection($selectionBeginIndex:int, $selectionEndIndex:int):void
		{
			if (_viewer.selectionBeginIndex == $selectionBeginIndex && _viewer.selectionEndIndex == $selectionEndIndex)
				return;
			
			_viewer.onSetSelection($selectionBeginIndex, $selectionEndIndex);
		}
		
		private function substring($begin:int, $end:int = 0x7fffffff):String {
			var str:String = _source.substring($begin, $end);
			
			return (str) ? str : '';
		}
		
		private function closed():void
		{
			stop();
			
			removeFromParent(this);
			_isLive = false;
			dispatchEvent(new Event(Event.CLOSE));
		}
		
		private function sendCurrentText($text:String):void 
		{
			_viewer.text = _source = $text;
		}		
		
		override public function start():void 
		{
			super.start();
			
			dispatchEvent(new LiveCodingEvent(LiveCodingEvent.JOINED, null));
			addEventListener(Event.ENTER_FRAME, update);
		}
		
		override public function stop():void 
		{
			super.stop();
			removeEventListener(Event.ENTER_FRAME, update);
		}
		
		private function scrollH($scrollH:int):void
		{
			if (_isSync) _viewer.scrollH = $scrollH;
		}
		
		private function scrollV($scrollV:int):void
		{
			if (_isSync) _viewer.scrollY = $scrollV;
		}
		
		private function SWFReloaded():void
		{
			if (ExternalInterface.available)
				ExternalInterface.call('Wonderfl.Codepage.reload_swf');
		}
		
		private function update(e:Event):void 
		{
			_onImage.alpha = Quadratic.easeOut((_blink_count > BLINK_PERIOD) ? 2 * BLINK_PERIOD - _blink_count : _blink_count,
											  0, 1, BLINK_PERIOD);
			_blink_count++;
			_blink_count %= 2 * BLINK_PERIOD;
		}
		
		public function get isSync():Boolean { return _isSync; }

		
	}

}