package net.wonderfl.editor.core 
{
	import flash.desktop.Clipboard;
	import flash.desktop.ClipboardFormats;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFieldType;
	import flash.ui.Keyboard;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	import net.wonderfl.editor.IEditor;
	import net.wonderfl.editor.we_internal;
	import net.wonderfl.editor.manager.KeyDownProxy;
	/**
	 * ...
	 * @author kobayashi-taro
	 */
	public class UIFTETextField extends FTETextField implements IEditor
	{
		internal var lastCol:int = 0;
		private var extChar:int;
		private var prevMouseUpTime:int = 0;
		private var _downKey:int = -1;
		private var _keyIntervalID:uint;
		private var _keyTimeOut:uint;
		private var _keyWatcher:Function;
		private var _this:UIFTETextField;
		protected var _preventDefault:Boolean;
		
		use namespace we_internal;
		
		public function UIFTETextField() 
		{
			super();
			focusRect = false;
			
			_this = this;
			
			new KeyDownProxy(this, onKeyDown, [Keyboard.DOWN, Keyboard.UP, Keyboard.PAGE_DOWN, Keyboard.PAGE_UP, Keyboard.LEFT, Keyboard.RIGHT, 66, 70]);
			addEventListener(FocusEvent.KEY_FOCUS_CHANGE, function(e:FocusEvent):void {
				e.preventDefault();
				e.stopImmediatePropagation();
			});
			addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			
			
			addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			
			
			addEventListener(Event.COPY, onCopy);
			//addEventListener(Event.PASTE, onPaste);
			addEventListener(Event.SELECT_ALL, onSelectAll);
			
			addEventListener(MouseEvent.ROLL_OVER, function(e:MouseEvent):void {
				//Mouse.cursor = MouseCursor.IBEAM;
			});
			addEventListener(MouseEvent.ROLL_OUT, function(e:MouseEvent):void {
				//Mouse.cursor = MouseCursor.AUTO;
			});
		}
		
		public function setScrollYByBar($value:int):void {
			_igonoreCursor = true;
			scrollY = $value;
		}
		
		private function onDoubleClick():void {
			var pos:int = getIndexForPoint(new Point(mouseX, mouseY));
			_setSelection(findWordBound(pos, true), findWordBound(pos, false), true);
		}
		
		public function findWordBound(start:int, left:Boolean):int
		{
			if (left)
			{
				while (/\w/.test(_text.charAt(start))) start--;
				return start + 1;
			}
			else
			{ 
				while (/\w/.test(_text.charAt(start))) start++;
				return start;
			}
		}
		
		private function onMouseWheel(e:MouseEvent):void
		{
			setScrollYByBar(_scrollY - e.delta);
		}
				
		public function onCopy(e:Event=null):void
		{
			if (_selStart != _selEnd)
				Clipboard.generalClipboard.setData(ClipboardFormats.TEXT_FORMAT, _text.substring(_selStart, _selEnd));
		}
		
		public function onSelectAll(e:Event):void
		{
			trace('select all '+ _text.length);
			_setSelection(0, _text.length, true);
		}
		
		public function onMouseDown(e:MouseEvent):void
		{
			var p:Point = new Point;
			
			p.x = mouseX; p.y = mouseY;
			var dragStart:int;
			if (e.shiftKey)
			{
				dragStart = _caret;
				_setSelection(dragStart, getIndexForPoint(p), true);
			}
			else
			{
				dragStart = getIndexForPoint(p);
				_setSelection(dragStart, dragStart, true);
			}
			
			stage.addEventListener(Event.ENTER_FRAME, onMouseMove);
			stage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			
			//var IID:int = setInterval(intervalScroll, 30);
			var scrollDelta:int = 0;
			var prevMouse:Point = new Point(NaN);
			
			function onMouseMove(e:Event):void
			{
				if (mouseY < 0)
					scrollDelta = -1;
				else if (mouseY > height)
					scrollDelta = 1;
				else
					scrollDelta = 0;
					
				if (scrollDelta != 0) {
					scrollY += scrollDelta;
				}
				
				p.x = mouseX; p.y = mouseY;
				if (!p.equals(prevMouse)) {
					_setSelection(dragStart, getIndexForPoint(p));
					prevMouse = p.clone();
				}
			}
			
			function onMouseUp(e:MouseEvent):void
			{
				stage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
				stage.removeEventListener(Event.ENTER_FRAME, onMouseMove);
				
				var t:int = getTimer();
				if (t - prevMouseUpTime < 250) {
					onDoubleClick();
					prevMouseUpTime = t;
					return;
				}
				prevMouseUpTime = t;
				p.x = mouseX; p.y = mouseY;
				_setSelection(dragStart, getIndexForPoint(p), true);
				//clearInterval(IID);
				saveLastCol();
			}
			
			function intervalScroll():void
			{
				if (scrollDelta != 0)
				{
					scrollY += scrollDelta;
					p.x = mouseX; p.y = mouseY;
					_setSelection(dragStart, getIndexForPoint(p));
				}
			}
		}
		
		protected function onKeyDown(e:KeyboardEvent):void
		{
			var c:String = String.fromCharCode(e.charCode);
			var k:int = e.keyCode;
			var i:int;
			if (k == Keyboard.INSERT && e.ctrlKey)
			{
				onCopy();
			}
			//else if (k == Keyboard.INSERT && e.shiftKey)
			//{
				//onPaste();
			//}
			//
			//else if (String.fromCharCode(e.charCode) == 'z' && e.ctrlKey)
			//{
				//undo();
				//dipatchChange();
				//return;
			//}
			//else if (String.fromCharCode(e.charCode) == 'y' && e.ctrlKey)
			//{
				//redo();
				//dipatchChange();
				//return;
			//}
			
			
			if (k == Keyboard.CONTROL || k == Keyboard.SHIFT || e.keyCode==3/*ALT*/ || e.keyCode==Keyboard.ESCAPE)
				return;
				
			//debug(e.charCode+' '+e.keyCode);
				
			//var line:TextLine = getLineAt(_caret);
			var re:RegExp;
			var pos:int;
			
			if (k == Keyboard.RIGHT)
			{
				if (e.ctrlKey)
				{
					re = /\b/g;
					re.lastIndex = _caret+1;
					re.exec(_text);
					_caret = re.lastIndex;
					if (e.shiftKey) extendSel(false);
				}
				else
				{
					//if we have a selection, goto end of selection
					if (!e.shiftKey && _selStart != _selEnd)
						_caret = _selEnd; 
					else if (_caret < length) {
						_caret += 1;
						if (e.shiftKey) extendSel(false);
					}
				}
			}
			else if (k == Keyboard.DOWN)
			{
				//look for next NL
				i = _text.indexOf(NL, _caret);
				if (i != -1)
				{ 
					_caret = i+1;
				
					//line = lines[line.index+1];
					
					i = _text.indexOf(NL, _caret);
					if (i==-1) i = _text.length;
					
					
					//restore col
					if (i - _caret > lastCol)
						_caret += lastCol;
					else
						_caret = i;
						
					if (e.shiftKey) extendSel(false);
				}
			}
			else if (k == Keyboard.UP)
			{
				i = _text.lastIndexOf(NL, _caret-1);
				var lineBegin:int = i;
				if (i != -1)
				{
					i = _text.lastIndexOf(NL, i-1);
					if (i != -1) _caret = i+1;
					else _caret = 0;
					
					//line = lines[line.index - 1];
					//_caret = line.start;
					
					//restore col
					if (lineBegin - _caret > lastCol)
						_caret += lastCol;
					else
						_caret = lineBegin;
						
					if (e.shiftKey) extendSel(true);
				}
			}
			else if (k == Keyboard.PAGE_UP)
			{
				for (i = 0, pos = _caret; i <= visibleRows; i++) 
				{
					pos = _text.lastIndexOf(NL, pos-1);
					if (pos == -1)
					{
						_caret = 0;
						break;
					}
					_caret = pos+1;
				}
			}
			else if (k == Keyboard.PAGE_DOWN)
			{
				for (i = 0, pos = _caret; i <= visibleRows; i++) 
				{
					pos = _text.indexOf(NL, pos+1);
					if (pos == -1)
					{
						_caret = _text.length;
						break;
					}
					_caret = pos+1;
				}
			}
			else if (k == Keyboard.LEFT)
			{
				if (e.ctrlKey)
				{
					_caret = Math.max(0, findWordBound(_caret-2, true));
					if (e.shiftKey) extendSel(true);
				}
				else
				{
					//if we have a selection, goto begin of selection
					if (!e.shiftKey && _selStart != _selEnd) 
						_caret = _selStart;
					else if (_caret > 0) {
						_caret -= 1;
						if (e.shiftKey) extendSel(true);
					}
				}
			}
			else if (k == Keyboard.HOME)
			{
				if (e.ctrlKey)
					_caret = 0;
				else
				{
					var start:int = i = _text.lastIndexOf(NL, _caret-1) + 1;
					var ch:String;
					while ((ch=_text.charAt(i))=='\t' || ch==' ') i++;
					_caret = _caret == i ? start : i;
				}
				if (e.shiftKey) extendSel(true);
			}
			else if (k == Keyboard.END)
			{
				if (e.ctrlKey)
					_caret = _text.length;
				else
				{
					i = _text.indexOf(NL, _caret);
					_caret = i == -1 ? _text.length : i;
				}
				if (e.shiftKey) extendSel(false);
			}
			else return;

			if (!e.shiftKey && k!=Keyboard.TAB)
				_setSelection(_caret, _caret);
			
			//save last column
			if (k!=Keyboard.UP && k!=Keyboard.DOWN && k!=Keyboard.TAB)
				saveLastCol();
			
			checkScrollToCursor();
			//e.updateAfterEvent();
			//captureInput();
			
			//local function
			function extendSel(left:Boolean):void
			{
				if (left)
				{
					if (_caret < _selStart)
						_setSelection(_caret, _selEnd);
					else
						_setSelection(_selStart, _caret);
				}
				else
				{
					if (_caret > _selEnd)
						_setSelection(_selStart, _caret);
					else
						_setSelection(_caret, _selEnd);
				}
			}
		}
		
		override public function _setSelection(beginIndex:int, endIndex:int, caret:Boolean = false):void 
		{
			super._setSelection(beginIndex, endIndex, caret);
			
			stage.focus = this;
		}
		
		
		protected function saveLastCol():void
		{
			lastCol = _caret - _text.lastIndexOf(NL, _caret-1) - 1;
		}
	}

}