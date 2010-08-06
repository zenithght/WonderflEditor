﻿package net.wonderfl.editor.livecoding 
{
	import net.wonderfl.editor.ITextArea;
	/**
	 * @author kobayashi-taro
	 */
	public class LiveCoding
	{
		public static const REPLACE_TEXT:String = 'replaceText';
		public static const SET_SELECTION:String = 'setSelection';
		public static const SEND_CURRENT_TEXT:String = 'sendCurrentText';
		public static const SWF_RELOADED:String = 'swfReloaded';
		public static const CLOSED:String = 'closed';
		public static const SCROLL_V:String = 'scrollV';
		public static const SCROLL_H:String = 'scrollH';
		
		public static var isLive:Boolean = true;
		private var _text:String = '';
		private var _prevText:String = '';
		static private var _broadCaster:LiveCodingBroadcaster;
		static private var _this:LiveCoding;
		static private var _onJoin:Function;
		
		public function LiveCoding() 
		{
			_this = this;
		}
		
		public function setSocket($socket:SocketBroadCaster):void {
			_broadCaster = new LiveCodingBroadcaster($socket);
		}
		
		public static function getInstance():LiveCoding {
			return _this ||= new LiveCoding;
		}
		
		public function setEditor(value:ITextArea):void {
			_broadCaster.editor = value;
		}
		
		public static function start():void {
			_broadCaster.startLiveCoding();
			_broadCaster.sendCurrentText();
		}
		
		public static function stop():void {
			_broadCaster.endLiveCoding();
		}
		
		public function pushCurrentSelection($selectionBeginIndex:int, $selectionEndIndex:int):void {
			_broadCaster.setSelection($selectionBeginIndex, $selectionEndIndex);
		}
		
		public function pushReplaceText($startIndex:int, $endIndex:int, $text:String):void {
			trace("LiveCoding.pushReplaceText > s : " + $startIndex + ", e : " + $endIndex + ", text : [" + $text + "]");
			_broadCaster.replaceText($startIndex, $endIndex, $text);
		}
		
		public function pushSWFReloaded():void {
			_broadCaster.onSWFReloaded();
		}
		
		public function pushClosing():void {
			_broadCaster.closeLiveCoding();
		}
		
		public function pushScrollV($scrollV:int):void {
			_broadCaster.setScrollV($scrollV);
		}
		
		public function pushScrollH($scrollH:int):void {
			_broadCaster.setScrollH($scrollH);
		}
		
		public function get text():String { return _text; }
		
		public function set text(value:String):void 
		{
			_prevText = _text;
			_text = value;
		}
		
		public function get prevText():String { return _prevText; }
		
		public function set onJoin(value:Function):void 
		{
			_broadCaster.onJoin = value;
		}
		
		public function set onMemberUpdate(value:Function):void {
			_broadCaster.onMemberUpdate = value;
		}
		
	}

}