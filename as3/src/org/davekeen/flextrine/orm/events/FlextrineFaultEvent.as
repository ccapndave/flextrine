/**
 * Copyright (C) 2012 Dave Keen http://www.actionscriptdeveloper.co.uk
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

package org.davekeen.flextrine.orm.events {
	import flash.events.Event;
	
	import mx.rpc.events.FaultEvent;
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class FlextrineFaultEvent extends Event {
		
		public static const LOAD_FAULT:String = "load_fault";
		public static const FLUSH_FAULT:String = "flush_fault";
		
		private var _data:Object;
		
		private var _faultEvent:FaultEvent;
		
		public function FlextrineFaultEvent(type:String, data:Object = null, faultEvent:FaultEvent = null, bubbles:Boolean=false, cancelable:Boolean=false) { 
			super(type, bubbles, cancelable);
			
			this._data = data;
			this._faultEvent = faultEvent;
		}
		
		public function get data():Object {
			return _data;
		}
		
		public function get faultEvent():FaultEvent {
			return _faultEvent;
		}
		
		public override function clone():Event { 
			return new FlextrineFaultEvent(type, data, faultEvent, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("FlextrineFaultEvent", "type", "data", "faultEvent", "bubbles", "cancelable", "eventPhase");
		}
		
	}
	
}