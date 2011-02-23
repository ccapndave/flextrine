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
 * If not, see <http://www.gnu.org/licenses/>.
 * 
 */

package org.davekeen.collections {
	import mx.collections.ArrayCollection;
	
	import org.davekeen.flextrine.orm.EntityProxy;
	import org.davekeen.collections.index.Index;
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.EntityProxy;

	/**
	 * An IndexedArrayCollection extends an ArrayCollection such that we can specify fields within the contained objects as indexes and from then on
	 * perform O(1) lookup against those indexes.
	 * 
	 * For now this will only work with a single index.
	 * 
	 * @private
	 * @author Dave Keen
	 */
	public class IndexedArrayCollection extends ArrayCollection {
		
		private var indexes:Array;
		
		public function IndexedArrayCollection(source:Array = null) {
			super(source);
			
			indexes = [];
		}
		
		override public function set source(value:Array):void {
			super.source = value;
			
			refreshAllIndexes();
		}
		
		public function addIndex(indexFields:Array):void {
			var index:Index;
			
			index = new Index(indexFields);
			
			indexes.push(index);
			refreshIndex(index);
		}
		
		private function refreshAllIndexes():void {
			for each (var index:Index in indexes)
				refreshIndex(index);
		}
		
		private function refreshIndex(index:Index):void {
			index.clear();
			for each (var obj:Object in source)
				index.add(obj);
		}
		
		public function findOneBy(findObj:Object):Object {
			var results:Array = findBy(findObj);
			return (results && results.length > 0) ? results[0] : null;
		}
		
		public function findBy(findObj:Object):Array {
			var results:Array;
			
			// First select the most appropriate index (the one with the most of the keys in findObj)
			var index:Index = getBestIndexForFindObj(findObj);
			
			if (index) {
				// We found a matching index so use that to filter the data
				var indexFindObj:Object = getFindObjForIndex(findObj, index);
				results = index.findBy(indexFindObj);
				
				// Remove the bits we have already filtered on from the findObj
				for (var indexField:String in indexFindObj)
					delete findObj[indexField];
					
			} else {
				// There was no matching index so we start with the complete dataset
				results = source;
			}
			
			// We now need to refine the dataset manually (if required)
			for (var s:String in findObj)
				throw new Error("Non index searching is not yet implemented (" + s + "=" + findObj[s] + ")");
			
			return results;
		}
		
		/**
		 * Goes through the indexes selected the most appopriate (if any) to use for this query.
		 * 
		 * @param	findObj
		 * @return  
		 */
		private function getBestIndexForFindObj(findObj:Object):Index {
			var indexKeyMatches:int = -1;
			var bestIndexForSearch:Index;
			for each (var index:Index in indexes) {
				var indexKeys:Array = index.getIndexFields();
				
				// Now go through the index keys one at a time checking if they are in the findObj
				for (var n:uint = 0; n < indexKeys.length; n++) {
					if (findObj[indexKeys[n]] != undefined) {
						// Founda matching index; based on its score possibly set this as the 'best' index to use
						if (n > indexKeyMatches) {
							indexKeyMatches = n;
							bestIndexForSearch = index;
						}
						continue;
					} else {
						break;
					}
				}
			}
			
			return bestIndexForSearch;
		}
		
		private function getFindObjForIndex(findObj:Object, index:Index):Object {
			var indexFindObj:Object = new Object();
			for each (var indexField:String in index.getIndexFields())
				if (findObj[indexField] != undefined) indexFindObj[indexField] = findObj[indexField];
				
			return indexFindObj;
		}
		
		/**
		 * Note that addItem internally calls addItemAt so there is no need to implement a seperate override to maintain the index (in fact if we do
		 * the index gets created twice throwing an exception the second time)
		 * 
		 * @param	item
		 * @param	idx
		 */
		override public function addItemAt(item:Object, idx:int):void {
			var itemProxy:Object = new EntityProxy(item);
			
			for each (var index:Index in indexes)
				index.add(itemProxy);
				
			super.addItemAt(itemProxy, idx);
		}
		
		public override function getItemAt(index:int, prefetch:int=0):Object {
			return (super.getItemAt(index, prefetch) as EntityProxy).flextrine::object;
		}
		
		/**
		 * Maintain the index when removeAll is called.
		 */
		override public function removeAll():void {
			for each (var index:Index in indexes)
				index.clear();
				
			super.removeAll();
		}
		
		/**
		 * Maintain the index when removeItemAt is called.
		 * 
		 * @param	idx
		 * @return
		 */
		override public function removeItemAt(idx:int):Object {
			// This could actually use the index find function once it works properly
			var item:Object = super.getItemAt(idx);
			for each (var index:Index in indexes)
				index.remove(item);
			
			return super.removeItemAt(idx);
		}
		
		/**
		 * Maintain the index when setItemAt is called.
		 * 
		 * @param	item
		 * @param	index
		 * @return
		 */
		override public function setItemAt(item:Object, idx:int):Object {
			// This could actually use the index find function once it works properly
			var obj:Object = super.getItemAt(idx);
			for each (var index:Index in indexes)
				index.replace(item);
			
			return super.setItemAt(item, idx);
		}
		
		override public function getItemIndex(item:Object):int {
			var n:int = source.length;
			for (var i:int = 0; i < n; i++) {
				if (source[i].flextrine::object === item)
					return i;
			}
			
			return -1;          
		}
		
		/**
		 * A convenience method for replacing an existing item.  For the moment this uses getItemIndex() which as far as I can tell searches through the
		 * array collection until it finds a match; in the future this might be better served by maintaining a Dictionary of item->idx allowing O(1) lookups.
		 * 
		 * @param	item
		 * @return
		 */
		public function replaceItem(item:Object):Object {
			var idx:int = getItemIndex(item);
			
			if (idx == -1)
				throw new Error("Unable to find item in order to replace it [" + item + "]");
				
			return setItemAt(item, idx);
		}
		
		public function removeItem(item:Object):Object {
			var idx:int = getItemIndex(item);
			
			if (idx == -1)
				throw new Error("Unable to find item in order to remove it [" + item + "]");
				
			return removeItemAt(idx);
		}
		
	}

}