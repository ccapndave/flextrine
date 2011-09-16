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

package org.davekeen.flextrine.orm {
	import flash.utils.Dictionary;
	
	import mx.events.CollectionEvent;
	import mx.events.PropertyChangeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncToken;
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.operations.CollectionChangeOperation;
	import org.davekeen.flextrine.orm.operations.PersistOperation;
	import org.davekeen.flextrine.orm.operations.PropertyChangeOperation;
	import org.davekeen.flextrine.orm.operations.RemoveOperation;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	use namespace flextrine;
	
	/**
	 * The UnitOfWork is a standard enterprise design pattern used to delay writes to the database.  In some senses a UnitOfWork is similar to a database
	 * transaction (and in fact the UnitOfWork is always executed as a transaction on the server).  This design pattern is particularly relevant to an
	 * asynchronous client/server library like Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class UnitOfWork {
		
		/**
		 * The EntityManager
		 */
		private var em:EntityManager;
		
		/**
		 * This maintains a map of temporary uids (for persisted objects without real ids) to the objects themselves
		 */
		public var temporaryUidMap:Object;
		
		/**
		 * Keep a dictionary of persisted entities so we can make sure we don't persist the same entity twice, and also for rollback
		 */
		public var persistedEntities:Dictionary;
		
		/**
		 * Keep a dictionary of dirty entities so we know what to rollback
		 */
		public var dirtyEntities:Dictionary;
		
		/**
		 * Keep a dictionary of removed entities so we know what to add back in on rollback
		 */
		public var removedEntities:Dictionary;
		
		/**
		 * This builds up a list of remote operations which need to be executed against the server  
		 */
		private var remoteOperations:RemoteOperations;
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		/**
		 * @private
		 * @param	em
		 */
		public function UnitOfWork(em:EntityManager) {
			this.em = em;
			
			// Initialize the UoW
			clear();
		}
		
		/**
		 * Clear the unit of work
		 * 
		 * @private 
		 */
		internal function clear():void {
			remoteOperations = new RemoteOperations();
			
			temporaryUidMap = new Object();
			persistedEntities = new Dictionary(false);
			dirtyEntities = new Dictionary(false);
			removedEntities = new Dictionary(false);
		}
		
		/**
		 * Add a persist remote operation to the flush queue.  Persisted objects are assigned temporary UIDs in Flextrine so that they can be matched up
		 * with the created entity when the changeset is returned from the server.
		 * 
		 * @private 
		 * @param	entity
		 */
		internal function persist(entity:Object, temporaryUid:String):void {
			remoteOperations.persists[EntityUtil.getUniqueHash(entity, temporaryUid)] = new PersistOperation(entity, temporaryUid);
		}
		
		/**
		 * This method cancels a persist operation for an entity which has not yet been flushed.  It is used when we remove a persisted entity before calling
		 * flush and just removes the persist operation from the flush queue.
		 * 
		 * @private 
		 * @param	temporaryUid	The temporary uid of the persisted entity
		 * @return
		 */
		internal function undoPersist(temporaryUid:String):Boolean {
			for (var uniqueId:String in remoteOperations.persists) {
				var persistOperation:PersistOperation = remoteOperations.persists[uniqueId] as PersistOperation;
				if (persistOperation.temporaryUid == temporaryUid) {
					delete remoteOperations.persists[uniqueId];
					return true;
				}
			}
			
			return false;
		}
		
		flextrine function propertyChange(e:PropertyChangeEvent):void {
			var propertyChangeOperation:PropertyChangeOperation = PropertyChangeOperation.createFromPropertyChangeEvent(e);
			
			if (!persistedEntities[propertyChangeOperation.entity]) {
				log.info("Detected property change on {0}::{1} - '{2}' => '{3}'", propertyChangeOperation.entity, propertyChangeOperation.property, e.oldValue, e.newValue);
				remoteOperations.propertyChanges[EntityUtil.getUniqueHash(propertyChangeOperation.entity) + "_" + propertyChangeOperation.property] = propertyChangeOperation;
			}
		}
		
		flextrine function collectionChange(e:CollectionEvent):void {
			var collectionChangeOperation:CollectionChangeOperation = CollectionChangeOperation.createFromCollectionChangeEvent(e);
			
			// Dictionary or array?  Not sure how we can write/overwrite stuff, plus we want it ordered.  This one is an array!
			log.info("Detected collection change on {0}::{1} - {2}", collectionChangeOperation.entity, collectionChangeOperation.property, collectionChangeOperation.type);
			
			remoteOperations.collectionChanges.push(collectionChangeOperation);
		}
		
		/**
		 * Add a remove remote operation to the flush queue.
		 * 
		 * @private 
		 * @param	entity	The entity to remove
		 */
		internal function remove(entity:Object):void {
			// If the entity is in the merge queue remove it as there is no point merging an entity that is about to be removed
			// TODO: This will need to change in order to remove it from propertyChanges and collectionChanges instead
			//delete remoteOperations.merges[EntityUtil.getUniqueHash(entity)];
			
			remoteOperations.removes[EntityUtil.getUniqueHash(entity)] = new RemoveOperation(entity);
		}
		
		/**
		 * Flush the queue - all remote operations will be executed on the server in the order they were added.
		 * 
		 * @private 
		 */
		internal function flush(fetchMode:String):AsyncToken {
			// TODO: If size() == 0 this should not call the remote service, but just invoke onResult on the AsyncToken instead
			return em.getDelegate().flush(remoteOperations.toObject(), fetchMode);
		}
		
		/**
		 * Returns the size of the unit of work.  This is the number of remote operations in it.
		 * 
		 * @return The number of operations queued up in the unit of work.
		 */
		public function size():int {
			return remoteOperations.size();
		}
		
		/**
		 * Return all the remote operations in the unit of work as a string.  This is useful for debugging.
		 * 
		 * @return
		 */
		public function toString():String {
			return ObjectUtil.toString(remoteOperations);
		}
		
	}

}

import flash.utils.Dictionary;

import org.davekeen.flextrine.orm.RemoteEntityFactory;
import org.davekeen.flextrine.orm.operations.PersistOperation;
import org.davekeen.flextrine.orm.operations.RemoteOperation;
import org.davekeen.flextrine.util.EntityUtil;

class RemoteOperations {
	
	public var persists:Dictionary = new Dictionary(false);
	public var removes:Dictionary = new Dictionary(false);
	
	public var propertyChanges:Dictionary = new Dictionary(false);
	public var collectionChanges:Array = [ ];
	
	/**
	 * Returns the total number of queued remote operations in the RemoteOperations object
	 * 
	 * @return 
	 * 
	 */
	public function size():int {
		return getDictionarySize(persists) + getDictionarySize(removes) + getDictionarySize(propertyChanges) + collectionChanges.length;
	}
	
	/**
	 * Returns the remote operations as a key/value object of types.  This also converts the entities into Flextrine server
	 * friendly copies.
	 *  
	 * @return 
	 * 
	 */	
	public function toObject():Object {
		var remoteEntityFactory:RemoteEntityFactory = new RemoteEntityFactory();
		
		// We need to pass the persists and merges to the remote entity factory so it knows not to uninitialize these top level entities
		for each (var persistOperation:PersistOperation in persists)
			remoteEntityFactory.addTopLevelEntity(persistOperation.entity);
		
		var object:Object = {
			persists: toRemoteArray(persists, remoteEntityFactory),
			removes: toRemoteArray(removes, remoteEntityFactory),
			propertyChanges: toRemoteArray(propertyChanges, remoteEntityFactory),
			collectionChanges: toRemoteArray(collectionChanges, remoteEntityFactory)
		};
		
		return object;
	}
	
	/**
	 * Use the RemoteObjectFactory to convert entities into Flextrine server friendly versions (this replaces associations
	 * with uninitialized versions so that we don't send huge object graphs for little updates).
	 * 
	 * @param dictionary
	 * @param remoteEntityFactory
	 * @return 
	 * 
	 */	
	private function toRemoteArray(dictOrArray:*, remoteEntityFactory:RemoteEntityFactory):Array {
		if (!(dictOrArray is Dictionary || dictOrArray is Array))
			throw new Error("toRemoteArray can only be called on a Dictionary or Array");
		
		var array:Array = [];
		
		for each (var remoteOperation:RemoteOperation in dictOrArray) {	
			// Replace any entities with a remote version
			remoteOperation.transformEntities(remoteEntityFactory);
			
			// Add the operation to the array
			array.push(remoteOperation);
		}
		
		return array;
	}
	
	private static function getDictionarySize(dictionary:Dictionary):int {
		var count:int = 0;
		for (var key:* in dictionary)
			count++;
		
		return count;
	}
	
}