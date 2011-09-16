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
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class FlextrineEvent extends Event {
		
		public static const LOADING:String = "loading";
		public static const FLUSHING:String = "flushing";
		
		public function FlextrineEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false) { 
			super(type, bubbles, cancelable);
		}
		
		public override function clone():Event { 
			return new FlextrineEvent(type, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("FlextrineEvent", "type", "bubbles", "cancelable", "eventPhase");
		}
		
	}
	
}