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

package org.davekeen.flextrine.orm {
	import flash.utils.Dictionary;
	
	import org.davekeen.flextrine.cache.DictionaryCache;
	import org.davekeen.flextrine.cache.ICache;
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class RemoteEntityFactory {
		
		private var remoteEntityCache:ICache;
		
		private var topLevelEntities:Dictionary;
		
		public function RemoteEntityFactory() {
			remoteEntityCache = new DictionaryCache(true);
			topLevelEntities = new Dictionary(true);
		}
		
		/**
		 * Top level entities are never un-initialized when converting entities to remote entities, even if they are identified
		 * 
		 * @param entity
		 */
		public function addTopLevelEntity(entity:Object):void {
			topLevelEntities[entity] = true;
		}
		
		private function isTopLevelEntity(entity:Object):Boolean {
			return topLevelEntities[entity];
		}
		
		public function getRemoteEntity(entity:Object):Object {
			return entityToRemoteEntity(entity);
		}
		
		private function entityToRemoteEntity(entity:Object):Object {
			// If the entity is in the cache already then we can just return that
			if (remoteEntityCache.contains(entity))
				return remoteEntityCache.fetch(entity);
			
			// Create a blank copy of the entity so our changes don't affect the original entity instance.  Use merge as this
			// fills in the properties for us already meaning we just need to worry about the associations.
			var entityClass:Class = ClassUtil.getClass(entity);
			var remoteEntity:Object = EntityUtil.mergeEntity(entity, new entityClass(), true);
			
			// Add the created remote entity to the cache
			remoteEntityCache.save(entity, remoteEntity);
			
			for each (var associationAttribute:XML in EntityUtil.getAttributesWithTag(entity, MetaTags.ASSOCIATION)) {
				var value:* = entity[associationAttribute];
				
				if (!value) continue;
				
				if (value is PersistentCollection) {
					if (EntityUtil.isCollectionInitialized(value)) {
						for (var n:int = 0; n < value.length; n++) {
							var item:Object = value.getItemAt(n);
							remoteEntity.flextrine::addValue(associationAttribute,
								EntityUtil.hasId(item) && !isTopLevelEntity(item)
								? toUninitializedEntity(item)
								: entityToRemoteEntity(item));
						}
					} else {
						// If the collection is uninitialized make it null
						remoteEntity[associationAttribute] = null;
					}
				} else {
					// For single valued associations
					remoteEntity.flextrine::setValue(associationAttribute,
						EntityUtil.hasId(value) && !isTopLevelEntity(value)
						? toUninitializedEntity(value)
						: entityToRemoteEntity(value));
				}
			}
			
			return remoteEntity;
		}
		
		/**
		 * Convert an entity to an un-initialized copy
		 * 
		 * @param entity
		 * @return 
		 */
		private function toUninitializedEntity(entity:Object):Object {
			if (remoteEntityCache.contains(entity))
				return remoteEntityCache.fetch(entity);
			
			// Create an empty uninitalized class
			var entityClass:Class = ClassUtil.getClass(entity);
			var uninitializedEntity:Object = new entityClass();
			uninitializedEntity.isInitialized__ = false;
			
			// Insert the ids
			for each (var idAttribute:String in EntityUtil.getIdFields(entity))
			uninitializedEntity[idAttribute] = entity[idAttribute];
			
			// Clear all the associations
			for each (var associationAttribute:XML in EntityUtil.getAttributesWithTag(entity, MetaTags.ASSOCIATION))
				uninitializedEntity[associationAttribute] = null;
			
			remoteEntityCache.save(entity, uninitializedEntity);
			
			return uninitializedEntity;
		}
		
	}
	
}