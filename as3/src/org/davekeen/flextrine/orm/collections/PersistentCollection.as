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
	import mx.collections.ArrayList;
	import mx.collections.IList;
	import mx.collections.ListCollectionView;
	import mx.collections.errors.ItemPendingError;
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.FlextrineError;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	/**
	 *
	 * @author Dave Keen
	 */
	[RemoteClass(alias="org.davekeen.flextrine.orm.collections.PersistentCollection")]
	public class PersistentCollection extends ListCollectionView {
		
		public static const TO_ONE:String = "1";
		
		public static const TO_MANY:String = "*";
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		public var isInitialized__:Boolean;
		
		private var owner:Object;
		
		private var associationName:String;
		
		private var itemPendingError:ItemPendingError;
		
		private var savedState:Array;
		
		public function PersistentCollection(source:Array = null, initialize:Boolean = false, associationName:String = null, owner:Object = null) {
			super();
			this.source = source;
			this.associationName = associationName;
			this.owner = owner;
			if (initialize) this.isInitialized__ = true;
		}
		
		public function setOwner(owner:Object):void {
			// TODO: I think this may be preventing garbage collection...
			this.owner = owner;
		}
		
		public function setAssociationName(associationName:String):void {
			this.associationName = associationName;
		}
		
		public function getAssociationName():String {
			return associationName;
		}
		
		public function getOwner():Object {
			return owner;
		}
		
		private function get oppositeAssociation():String {
			var associationMetaData:XMLList = EntityUtil.getMetaDataForAttributeAndTag(owner, associationName, MetaTags.ASSOCIATION);
			return associationMetaData.arg.(@key == "oppositeAttribute").@value;
		}
		
		private function get oppositeCardinality():String {
			var associationMetaData:XMLList = EntityUtil.getMetaDataForAttributeAndTag(owner, associationName, MetaTags.ASSOCIATION);
			return associationMetaData.arg.(@key == "oppositeCardinality").@value;
		}
		
		private function initialize():void {
			if (!itemPendingError) {
				itemPendingError = new ItemPendingError("Initializing persistent collection");
				dispatchEvent(new EntityEvent(EntityEvent.INITIALIZE_COLLECTION, associationName, itemPendingError));
			}
			
			throw itemPendingError;
		}
		
		[Transient]
		public override function get filterFunction():Function {
			return super.filterFunction;
		}
		
		[Transient]
		public override function get list():IList {
			return super.list;
		}

		public function get source():Array {
			if (list && (list is ArrayList)) {
				return ArrayList(list).source;
			}
			return null;
		}
		
		/**
		 *  @private
		 */
		public function set source(s:Array):void {
			list = new ArrayList(s);
		}
		
		/**
		 * If the collection is uninitialized and loadCollectionsOnDemand is set automatically initialize it.  intialize() will throw an
		 * ItemPendingError for any Flex components listening.
		 *  
		 * @param index
		 * @param prefetch
		 * @return 
		 * 
		 */
		public override function getItemAt(index:int, prefetch:int=0):Object {
			if (!isInitialized__) {
				initialize();
				return null;
			}
			
			return super.getItemAt(index, prefetch);
		}
		
		/**
		 * If the collection is uninitialized and loadCollectionsOnDemand is set then automatically initialize it.  intialize() will throw an
		 * ItemPendingError for any Flex components listening.
		 * 
		 * @return 
		 * 
		 */
		[Bindable("collectionChange")]
		public override function get length():int {
			if (!isInitialized__) {
				initialize();
				return 0;
			}
			
			return super.length;
		}
		
		public override function refresh():Boolean {
			checkIsInitialized("refresh");
			return super.refresh();
		}
		
		public override function addItem(item:Object):void {
			checkIsInitialized("addItem");
			
			if (!contains(item)) {
				super.addItem(item);
				
				switch (oppositeCardinality) {
					case TO_ONE:
						item.flextrine::setValue(oppositeAssociation, owner);
						break;
					case TO_MANY:
						item.flextrine::addValue(oppositeAssociation, owner);
						break;
				}
			}
		}
		
		public override function removeItemAt(index:int):Object {
			checkIsInitialized("removeItemAt");
			
			var removedItem:Object = super.removeItemAt(index);
			
			if (removedItem) {
				switch (oppositeCardinality) {
					case TO_ONE:
						removedItem.flextrine::setValue(oppositeAssociation, null);
						break;
					case TO_MANY:
						removedItem.flextrine::removeValue(oppositeAssociation, owner);
						break;
				}
			}
			
			return removedItem;
		}
		
		flextrine function addItemNonRecursive(item:Object):void {
			if (isInitialized__ && !contains(item))
				super.addItem(item);
		}
		
		flextrine function removeItemNonRecursive(item:Object):Object {
			if (isInitialized__) {
				var foundItemIdx:int = getItemIndex(item);			
				if (foundItemIdx >= 0) return removeItemAt(foundItemIdx);	
			}
			
			return null;
		}
		
		flextrine function removeAllNonRecursive():void {
			super.removeAll();
		}
		
		public override function addItemAt(item:Object, index:int):void {
			// TODO: This method should probably not be available to PersistentCollections...
			checkIsInitialized("addItemAt");
			if (!contains(item)) super.addItemAt(item, index);
		}
		
		public override function removeAll():void {
			checkIsInitialized("removeAll");
			
			if (oppositeAssociation == "") {
				// If there is no bidirectional relationship we can just use the normal removeAll()
				super.removeAll();
			} else {
				// Otherwise we have to remove items one at a time in order to ensure the relationship remains symmetric
				for (var n:int = length - 1; n >= 0; n--)
					removeItemAt(n);
			}
		}
		
		/**
		 * I have no idea why this method isn't in the IList interface, but anyway, here is a simple implementation of it.
		 * 
		 * @param item The item to remove
		 * @return The item removed, or null if it was not found
		 */
		public function removeItem(item:Object):Object {
			var foundItemIdx:int = getItemIndex(item);			
			if (foundItemIdx >= 0) return removeItemAt(foundItemIdx);
			return null;
		}
		
		public override function setItemAt(item:Object, index:int):Object {
			checkIsInitialized("setItemAt");
			return super.setItemAt(item, index);
		}
		
		private function checkIsInitialized(operation:String):void {
			if (!isInitialized__)
				throw new FlextrineError("Attempt to execute " + operation + " on an uninitialized collection.", FlextrineError.ACCESSED_UNINITIALIZED_COLLECTION);
		}
		
		/**
		 * Save the state of this PersistentCollection to an array
		 * 
		 * @return 
		 */
		flextrine function saveState():Array {
			return source;
		}
		
		/**
		 * Restore the state of this PersistentCollection from an array
		 * 
		 * @param source 
		 */
		flextrine function restoreState(source:Array):void {
			this.source = source;
		}
		
	}

}