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
	
	import mx.rpc.events.ResultEvent;
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class FlextrineResultEvent extends Event {
		
		public static const LOAD_COMPLETE:String = "load_complete";
		public static const FLUSH_COMPLETE:String = "flush_complete";
		
		private var _data:Object;
		
		private var _resultEvent:ResultEvent;
		
		private var _detachedEntity:Object;
		
		public function FlextrineResultEvent(type:String, data:Object = null, resultEvent:ResultEvent = null, detachedEntity:Object = null, bubbles:Boolean=false, cancelable:Boolean=false) { 
			super(type, bubbles, cancelable);
			
			this._data = data;
			this._resultEvent = resultEvent;
			this._detachedEntity = detachedEntity;
		}

		public function get data():Object {
			return _data;
		}
		
		public function get resultEvent():ResultEvent {
			return _resultEvent;
		}
		
		public function get detachedEntity():Object {
			return _detachedEntity;
		}
		
		public override function clone():Event { 
			return new FlextrineResultEvent(type, data, resultEvent, detachedEntity, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("FlextrineResultEvent", "type", "data", "resultEvent", "detachedEntity", "bubbles", "cancelable", "eventPhase");
		}
		
	}
	
}