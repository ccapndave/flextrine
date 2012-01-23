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
	
	import mx.collections.errors.ItemPendingError;
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class EntityEvent extends Event {
		
		public static const INITIALIZE_ENTITY:String = "initialize_entity";
		public static const INITIALIZE_COLLECTION:String = "initialize_collection";
		
		public var itemPendingError:ItemPendingError;
		public var property:String;
		
		public function EntityEvent(type:String, property:String, itemPendingError:ItemPendingError = null, bubbles:Boolean=false, cancelable:Boolean=false) { 
			super(type, bubbles, cancelable);
			
			this.itemPendingError = itemPendingError;
			this.property = property;
		} 
		
		public override function clone():Event { 
			return new EntityEvent(type, property, itemPendingError, bubbles, cancelable);
		} 
		
		public override function toString():String { 
			return formatToString("FlextrineEvent", "type", "property", "itemPendingError", "bubbles", "cancelable", "eventPhase"); 
		}
		
	}
	
}