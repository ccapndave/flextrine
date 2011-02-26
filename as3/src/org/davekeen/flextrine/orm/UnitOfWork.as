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
 * If not, see <http://www.gnu.org/licenses/>.
 * 
 */

package org.davekeen.flextrine.orm {
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncToken;
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	/**
	 * The UnitOfWork is a standard enterprise design pattern used to delay writes to the database.  In some senses a UnitOfWork is similar to a database
	 * transaction (and in fact the UnitOfWork is always executed as a transaction on the server).  This design pattern is particularly relevant to an
	 * asynchronous client/server library like Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class UnitOfWork {
		
		private var em:EntityManager;
		
		private var remoteOperations:RemoteOperations;
		
		/**
		 * The unit of work maintains a map of entities that it expects to be removed on the next flush.  When the changeset is received from the server we
		 * check deletions against removedEntitiesMap to work out whether or not to remove them from the repository.  After a flush we would expect this to
		 * be empty, but it must NOT be emptied in clear()!
		 */
		private var removedEntitiesMap:Object;
		
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
			
			remoteOperations = new RemoteOperations();
			removedEntitiesMap = new Object();
		}
		
		/**
		 * Add a persist remote operation to the flush queue.  Persisted objects are assigned temporary UIDs in Flextrine so that they can be matched up
		 * with the created entity when the changeset is returned from the server.
		 * 
		 * @private 
		 * @param	entity
		 */
		internal function persist(entity:Object, temporaryUid:String):void {
			remoteOperations.persists[EntityUtil.getUniqueHash(entity, temporaryUid)] = new RemoteOperation( { entity: entity, temporaryUid: temporaryUid }, RemoteOperation.PERSIST);
		}
		
		/**
		 * This method cancels a persist operation for an entity which has not yet been flushed.  It is used when we remove a persisted entity before calling
		 * flush and just removes the persist from the flush queue.
		 * 
		 * @private 
		 * @param	temporaryUid	The temporary uid of the persisted entity
		 * @return
		 */
		internal function undoPersist(temporaryUid:String):Boolean {
			for (var uniqueId:String in remoteOperations.persists) {
				var remoteOperation:RemoteOperation = remoteOperations.persists[uniqueId] as RemoteOperation;
				if (remoteOperation.data.temporaryUid == temporaryUid) {
					delete remoteOperations.persists[uniqueId];
					return true;
				}
			}
			
			return false;
		}
		
		/**
		 * Add a merge remote operation to the flush queue.
		 * 
		 * @private 
		 * @param	entity	The entity to merge
		 * @return
		 */
		internal function merge(entity:Object):Object {
			remoteOperations.merges[EntityUtil.getUniqueHash(entity)] = new RemoteOperation( { entity: entity }, RemoteOperation.MERGE);
			return entity;
		}
		
		/**
		 * Add a remove remote operation to the flush queue.
		 * 
		 * @private 
		 * @param	entity	The entity to remove
		 */
		internal function remove(entity:Object):void {
			// Add the entity to the list of entities that we expect to be deleted on the next flush
			removedEntitiesMap[EntityUtil.getUniqueHash(entity)] = entity;
			
			// If the entity is in the merge queue remove it as there is no point merging an entity that is about to be removed
			delete remoteOperations.merges[EntityUtil.getUniqueHash(entity)];
			
			remoteOperations.removes[EntityUtil.getUniqueHash(entity)] = new RemoteOperation( { entity: entity }, RemoteOperation.REMOVE);
		}
		
		/**
		 * Check whether the given entity was something we expected to be removed.  This is called when the changeset is returned from the server to decide
		 * whether or not to execute the delete against the repository or not.
		 * 
		 * @param	entity		  The entity that we are checking
		 * 
		 * @private 
		 * @return
		 */
		internal function hasRemovedEntity(entity:Object):Boolean {
			return removedEntitiesMap[EntityUtil.getUniqueHash(entity)]
		}
		
		/**
		 * Remove an entity from the removedEntitiesMap
		 * 
		 * @private 
		 * @param	entity
		 */
		internal function removeEntityFromRemoveMap(entity:Object):void {
			delete removedEntitiesMap[EntityUtil.getUniqueHash(entity)];
		}
		
		/**
		 * Checks whether there are any entities in the expected removals map.  Used as a sanity check; after a flush this should always return false or
		 * something has gone wrong.
		 * 
		 * @private 
		 * @return
		 */
		internal function hasRemovedEntities():Boolean {
			// If there are any keys in the entity map this returns true
			for (var uniqueHash:String in removedEntitiesMap)
				return true;
			
			return false;
		}
		
		/**
		 * Add a custom operation to the flush queue.  This has no default implementation in FlextrineService, but you can add functionality by extending
		 * FlextrineService in a new class and overiding the runCustomOperation method.
		 * 
		 * @depreciated
		 * @private 
		 * @param	operation
		 * @param	data
		 */
		internal function beforeFlushCustomOperation(operation:String, data:Object = null):void {
			throw new Error("beforeFlushCustomOperation is depreciated");
			//remoteOperations.beforeFlushCustoms.push(new RemoteOperation(data, operation));
		}
		
		/**
		 * @depreciated
		 * @private 
		 * @param	operation
		 * @param	data
		 */
		internal function afterFlushCustomOperation(operation:String, data:Object = null):void {
			throw new Error("afterFlushCustomOperation is depreciated");
			//remoteOperations.afterFlushCustoms.push(new RemoteOperation(data, operation));
		}
		
		/**
		 * Clear the flush queue.  All remote operations since the last flush will be discarded.
		 * 
		 * @private 
		 */
		internal function clear():void {
			remoteOperations = new RemoteOperations();
		}
		
		/**
		 * Flush the queue - all remote operations will be executed on the server in the order they were added.
		 * 
		 * @private 
		 */
		internal function flush(fetchMode:String):AsyncToken {
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
import org.davekeen.flextrine.orm.RemoteOperation;
import org.davekeen.flextrine.util.EntityUtil;

class RemoteOperations {
	
	public var persists:Dictionary = new Dictionary(true);
	public var merges:Dictionary = new Dictionary(true);
	public var removes:Dictionary = new Dictionary(true);
	
	/**
	 * Returns the total number of queued remote operations in the RemoteOperations object
	 * 
	 * @return 
	 * 
	 */
	public function size():int {
		return getDictionarySize(persists) + getDictionarySize(merges) + getDictionarySize(removes) /*+ beforeFlushCustoms.length + afterFlushCustoms.length*/;
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
		
		var object:Object = { persists: dictionaryToArray(persists, remoteEntityFactory),
				 			  merges: dictionaryToArray(merges, remoteEntityFactory),
				 			  removes: dictionaryToArray(removes, remoteEntityFactory)
							}
		
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
	private function dictionaryToArray(dictionary:Dictionary, remoteEntityFactory:RemoteEntityFactory):Array {
		var array:Array = [];
		
		for each (var remoteOperation:RemoteOperation in dictionary) {	
			remoteOperation.data.entity = remoteEntityFactory.getRemoteEntity(remoteOperation.data.entity);
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