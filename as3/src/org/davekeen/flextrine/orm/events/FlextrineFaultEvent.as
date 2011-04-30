/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 * 
 * This file is part of Flextrine.
 * 
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 * 
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