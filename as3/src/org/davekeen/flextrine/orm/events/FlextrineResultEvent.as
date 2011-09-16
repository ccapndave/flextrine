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
 * If not, see http://www.gnu.org/licenses/.
 * 
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