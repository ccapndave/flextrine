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

package org.davekeen.flextrine.orm.collections {
	import mx.collections.ArrayCollection;
	import mx.collections.IViewCursor;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.EntityProxy;
	import org.davekeen.flextrine.util.ClassUtil;

	/**
	 * 
	 * @private
	 * @author Dave Keen
	 */
	public class EntityCollection extends ArrayCollection {
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		private var entityTimeToLive:int;
		
		public function EntityCollection(source:Array = null, entityTimeToLive:int = 0) {
			super(source);
			
			this.entityTimeToLive = entityTimeToLive;
		}
		
		override public function set source(value:Array):void {
			super.source = value;
		}
		
		public function findOneBy(findObj:Object):Object {
			var results:Array = findBy(findObj);
			return (results && results.length > 0) ? results[0] : null;
		}
		
		public function findBy(findObj:Object):Array {
			var matches:Array = [];
			var match:Boolean;
			
			var cursor:IViewCursor = createCursor();
			while (!cursor.afterLast) {
				var entity:Object = cursor.current;
				match = true;
				
				for (var key:String in findObj) {
					if (!entity || entity[key] != findObj[key]) {
						match = false;
						break;
					}
				}
				
				if (match) matches.push(entity);
				
				cursor.moveNext();
			}
			
			return matches;
		}
		
		/**
		 * Note that addItem internally calls addItemAt so there is no need to implement a seperate override to maintain the index (in fact if we do
		 * the index gets created twice throwing an exception the second time)
		 * 
		 * @param	item
		 * @param	idx
		 */
		override public function addItemAt(item:Object, idx:int):void {
			var itemProxy:Object = new EntityProxy(item, entityTimeToLive);
			
			super.addItemAt(itemProxy, idx);
		}
		
		public override function getItemAt(index:int, prefetch:int=0):Object {
			var entity:Object = (super.getItemAt(index, prefetch) as EntityProxy).flextrine::object;
			
			if (!entity) {
				log.info("Noticed {0} was garbage collected in getItemAt()", (super.getItemAt(index, prefetch) as EntityProxy).flextrine::objectToString);
				
				// This is a bit dodgy, but seems to work ok so far...
				removeItemAt(index);
			}
			
			return entity;
		}
		
		/**
		 * Maintain the index when removeAll is called.
		 */
		override public function removeAll():void {	
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