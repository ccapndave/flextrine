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

package org.davekeen.flextrine.orm.operations {
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import org.davekeen.flextrine.orm.RemoteEntityFactory;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.operations.CollectionChangeOperation")]
	public class CollectionChangeOperation extends RemoteOperation {
		
		public static const ADD:String = "add"; // add the item(s)
		public static const REMOVE:String = "remove"; // remove the item(s)
		public static const RESET:String = "reset"; // replace the entire collection with the items
		
		public var type:String;
		
		public var entity:Object;
		
		public var property:String;
		
		public var items:Array;
		
		public function CollectionChangeOperation() {
			
		}
		
		override public function transformEntities(remoteEntityFactory:RemoteEntityFactory):void {
			entity = remoteEntityFactory.getRemoteEntity(entity);
			
			for (var n:uint = 0; n < items.length; n++)
				items[n] = remoteEntityFactory.getRemoteEntity(items[n]);
		}
		
		public static function createFromCollectionChangeEvent(e:CollectionEvent):CollectionChangeOperation {
			var persistentCollection:PersistentCollection = e.target as PersistentCollection;
			
			switch (e.kind) {
				case CollectionEventKind.ADD:
					return create(persistentCollection, ADD, e.items);
				case CollectionEventKind.REMOVE:
					return create(persistentCollection, REMOVE, e.items);
				case CollectionEventKind.RESET:
					// Use map to make a clone of the array so it doesn't change
					return create(persistentCollection, RESET, persistentCollection.source.map(function(e:*, ...r):* { return e; } ));
				default:
					throw new Error("unsupported collection change kind " + e.kind);
			}
			
			return null;
		}
		
		private static function create(persistentCollection:PersistentCollection, type:String, items:Array):CollectionChangeOperation {
			var changeOperation:CollectionChangeOperation = new CollectionChangeOperation();
			
			changeOperation.entity = persistentCollection.getOwner();
			changeOperation.property = persistentCollection.getAssociationName();
			changeOperation.items = items;
			changeOperation.type = type;
			
			return changeOperation;
		}
		
	}
}
