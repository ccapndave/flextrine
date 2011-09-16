/**
 * Copyright 2010 Dave Keen
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

package org.davekeen.collections.index {
	import mx.events.PropertyChangeEvent;
	
	/**
	 * @private
	 * @author Dave Keen
	 */
	public class Index {
		
		// An ordered array of the fields we are indexing against
		private var indexFields:Array;
		
		// The index object itself
		private var index:Object;
		
		public function Index(indexFields:Array) {
			this.indexFields = indexFields;
			
			clear();
		}
		
		/**
		 * Return an ordered list of the fields we are indexing so that the IndexedArrayCollection can decide which index to use for a particular
		 * query.
		 * 
		 * @return
		 */
		public function getIndexFields():Array {
			return indexFields;
		}
		
		/**
		 * Add an item to the index
		 * 
		 * @param	item
		 */
		public function add(item:Object):void {
			var targetObject:Object = index;
			for (var n:uint; n < indexFields.length; n++) {
				// Get the key name and value for this depth
				var indexField:String = indexFields[n];
				var indexValue:String = item[indexField];
				
				// If an index value is null then don't add it to the index (as it is unindexable at this point), but do add an index listener so if the
				// object does get an index at some point we can then add it to the index.
				if (indexValue == null) {
					addIndexListenersToItem(item);
					return;
				}
				
				// If this is the final node of the tree set the actual object, otherwise create an empty object
				if (n == indexFields.length - 1) {
					if (targetObject[indexValue])
						throw new Error("Index '" + indexValue + "' already exists for " + item + " (indexed on " + indexField + ") - " + targetObject[indexValue]);
						
					targetObject[indexValue] = item;
					
					// Add an event listener to the item so we are notified if an indexed property changes
					addIndexListenersToItem(item);
					return;
				} else {
					if (!targetObject[indexValue]) targetObject[indexValue] = new Node();
					targetObject = targetObject[indexValue];
				}
			}
		}
		
		/**
		 * Replace an item in the index.  This is identical to add except that it doesn't throw an exception if the item already exists.
		 * 
		 * @param	item
		 */
		public function replace(item:Object):void {
			throw new Error("Replace may not currently maintain index integrity.  Use EntityUtil.merge instead.");
			
			var targetObject:Object = index;
			for (var n:uint; n < indexFields.length; n++) {
				// Get the key name and value for this depth
				var indexField:String = indexFields[n];
				var indexValue:String = item[indexField];
				
				// If this is the final node of the tree set the actual object, otherwise create an empty object
				if (n == indexFields.length - 1) {
					// TODO: Need to check that this maintains the index.  Perhaps an add followed by a delete or something?
					targetObject[indexValue] = item;
					return;
				} else {
					if (!targetObject[indexValue]) targetObject[indexValue] = new Node();
					targetObject = targetObject[indexValue];
				}
			}
		}
		
		/**
		 * Remove an item from the index
		 * 
		 * @param	item
		 * @param	replaceField An optional index field to replace during the lookup
		 * @param	replaceValue The value to replace the index field with
		 */
		public function remove(item:Object, replaceField:String = null, replaceValue:Object = null):void {
			var targetObject:Object = index;
			for (var n:uint; n < indexFields.length; n++) {
				// Get the key name and value for this depth
				var indexField:String = indexFields[n];
				var indexValue:String = item[indexField];
				
				// If a replace field/value has been specified then change the value in item to the value in replaceValue
				if (replaceField && indexField == replaceField)
					indexValue = String(replaceValue);
				
				// If this is the final node of the tree set the actual object, otherwise create an empty object
				if (n == indexFields.length - 1) {
					// Remove the event listener to the item so we are no longer notified if an indexed property changes
					removeIndexListenersToItem(item);
					
					// TODO: This might need to remove orphaned nodes but that could be a waste of time
					targetObject[indexValue] = null;
					delete targetObject[indexValue];
					return;
				} else {
					targetObject = targetObject[indexValue];
				}
			}
		}
		
		private function addIndexListenersToItem(item:Object):void {
			item.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange, false, 0, true);
		}
		
		private function removeIndexListenersToItem(item:Object):void {
			item.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange);
		}
		
		/**
		 * The index needs to listen for property changes on its members.  Specifically it need to know if the value of an indexed field has changed in which
		 * case it need to remove the old index entry and add a new one.
		 * @param	e
		 */
		private function onPropertyChange(e:PropertyChangeEvent):void {
			if (indexFields.indexOf(e.property) > -1) {
				var item:Object = e.currentTarget;
				
				// Remove the old index.  Since the index value has changed we can't use a straight remove (as it searches on the index which has just been
				// changed), so we need to specify property and old value so the field can be found.
				remove(item, e.property as String, e.oldValue);
				
				// Re-index the item
				add(item);
			}
		}
		
		/**
		 * Reset the index
		 */
		public function clear():void {
			index = new Object();
		}
		
		/**
		 * Search the index.
		 * @param	findObj
		 * @return
		 */
		public function findBy(findObj:Object):Array {
			var indexFieldCount:uint = 0;
			for (var s:String in findObj)
				indexFieldCount++;
			
			var targetObject:Object = index;
			for (var n:uint; n < indexFieldCount; n++) {
				// Get the key name and value for this depth
				var indexField:String = indexFields[n];
				var indexValue:String = findObj[indexField];
				
				// If this is the final node of the tree get the actual object
				if (n == indexFieldCount - 1) {
					return (targetObject) ? resultToArray(targetObject[indexValue]) : null;
				} else {
					targetObject = targetObject[indexValue];
				}
			}
			
			return null;
		}
		
		private function resultToArray(obj:Object):Array {
			if (!obj) return null;
			
			var array:Array = [];
			
			if (obj is Node) {
				for (var s:String in obj)
					array = array.concat(resultToArray(obj[s]));
			} else {
				array.push(obj);
			}
			
			return array;
		}
		
	}

}

dynamic class Node extends Object {

}