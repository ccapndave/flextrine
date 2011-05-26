package org.davekeen.flextrine.orm.operations {
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	
	import org.davekeen.flextrine.orm.RemoteEntityFactory;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.operations.CollectionChangeOperation")]
	public class CollectionChangeOperation extends RemoteOperation {
		
		public static const ADD:String = "add"; // add the item(s)
		public static const REMOVE:String = "remove"; // remove the item(s)
		//public static const RESET:String = "reset"; // replace the entire collection with the items
		
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
				default:
					throw new Error("unsupported collection change kind " + e.kind);
			}
			
			return null;
		}
		
		/*public static function createResetFromCollection(persistentCollection:PersistentCollection):CollectionChangeOperation {
			return create(persistentCollection, RESET, persistentCollection.source);
		}*/
		
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
