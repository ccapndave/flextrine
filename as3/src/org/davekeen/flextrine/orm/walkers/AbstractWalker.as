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

package org.davekeen.flextrine.orm.walkers {
	import mx.logging.ILogger;
	import mx.logging.Log;
	
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	/**
	 * This is the base class for walking through object graphs, with various callback methods at different points of the walk.
	 * 
	 * @private 
	 * @author Dave Keen
	 */
	internal class AbstractWalker {
		
		private var visited:Object;
		
		/**
		 * Standard flex logger
		 */
		protected var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		public function AbstractWalker() {
			
		}
		
		final public function walk(entityOrArray:Object):Object {
			var result:Object;
			
			visited = [];
			
			if (entityOrArray is Array) {
				result = [];
				
				for each (var entity:Object in entityOrArray)
					result.push(doWalk(entity));
				
			} else {
				result = doWalk(entityOrArray);
			}
			
			return result;
		}
		
		final protected function doWalk(entity:Object):Object {
			if (!entity) return null;
			
			var data:Object = {};
			
			var oid:String;
			try {
				// If we get a reference error when trying to get the unique hash, then this isn't an entity.  Assume that this is a query result with a 
				// hydration mode other than HYDRATE_OBJECT and just silently return.
				oid = EntityUtil.getUniqueHash(entity);
			} catch (e:ReferenceError) {
				log.info("Received a non-entity result; not walking.");
				return entity;
			}
			
			setupWalk(entity, data);
			
			if (visited[oid])
				return returnEntity(entity, data);
			
			visited[oid] = true;
			
			beforeWalk(entity, data);
			
			if (EntityUtil.isInitialized(entity)) {
				for each (var associationAttribute:XML in EntityUtil.getAttributesWithTag(entity, MetaTags.ASSOCIATION)) {
					var value:* = entity[associationAttribute];
					
					if (value is PersistentCollection) {
						var persistentCollection:PersistentCollection = value as PersistentCollection;
						
						beforeCollectionWalk(persistentCollection, entity, associationAttribute.toString(), data);
						
						if (EntityUtil.isCollectionInitialized(persistentCollection))
							for (var n:uint = 0; n < persistentCollection.source.length; n++)
								collectionAction(persistentCollection, associationAttribute.toString(), n, data);
						
					} else {
						propertyAction(entity, associationAttribute, data);
					}
				}
				
				afterWalk(entity, data);
			}
			
			return returnEntity(entity, data);
		}

		/**
		 * This method is invoked before starting to walk an entity, even if the entity has been visited before.  It should be used to set
		 * variables in data that might be used in returnEntity.
		 * 
		 * @param entity The entity we are about to walk
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function setupWalk(entity:Object, data:Object):void { }
		
		/**
		 * This method is invoked before starting to walk an entity.  It is invoked whether or not the entity is initialized.
		 * 
		 * @param entity The entity we are about to walk
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function beforeWalk(entity:Object, data:Object):void { }
		
		/**
		 * This method is invoked before starting to walk through a collection.  It is invoked whether or not the collection is initialized.
		 * 
		 * @param collection The PersistentCollection we are about to walk
		 * @param owner The entity owning the collection (this will be the same entity as in beforeWalk)
		 * @param associationName The name of the association property
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function beforeCollectionWalk(collection:PersistentCollection, owner:Object, associationName:String, data:Object):void { }
		
		/**
		 * The method is invoked as the action to take when walking through an element of a collection.  In general this will be left at the default, which
		 * replaces the existing element with the result of the doWalk recursion.
		 * 
		 * @param collection The PersistentCollection we are walking
		 * @param associationName The name of the association property
		 * @param idx The index of the current element we are walking
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function collectionAction(collection:PersistentCollection, associationName:String, idx:uint, data:Object):void {
			var relatedEntity:Object = collection.getItemAt(idx);
			setItemAt(collection, idx, doWalk(replaceEntity(relatedEntity, data)), data);
		}
		
		/**
		 * The method is invoked as the action to take when walking through a single association.  In general this will be left at the default, which
		 * replaces the existing element with the result of the doWalk recursion.
		 * 
		 * @param entity The entity we are walking
		 * @param associationName The name of the association property
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function propertyAction(entity:Object, associationName:String, data:Object):void {
			var relatedEntity:Object = entity[associationName];
			setProperty(entity, associationName, relatedEntity ? doWalk(replaceEntity(relatedEntity, data)) : null, data);
		}
		
		/**
		 * Replace an associated entity.  By default this returns the original entity.
		 * 
		 * @param entity The original entity
		 * @param data A value object which can be used for storing data specific to the current recursion
		 * @return The replacement entity
		 */
		protected function replaceEntity(entity:Object, data:Object):Object { return entity; }
		
		/**
		 * This method is invoked after an entity has been walked.  This method is only invoked if the entity was initialized.
		 * 
		 * @param entity The entity that has just been walked
		 * @param data A value object which can be used for storing data specific to the current recursion
		 */
		protected function afterWalk(entity:Object, data:Object):void { }
		
		/**
		 * This method can be used to control the path of the recursion by replacing the return value.
		 * 
		 * @param entity The entity that was walked
		 * @param data A value object which can be used for storing data specific to the current recursion
		 * @return The entity that we actually return
		 */
		protected function returnEntity(entity:Object, data:Object):Object { return entity; }
		
		protected function setProperty(entity:Object, property:String, value:*, data:Object):void { entity[property] = value; }
		protected function setItemAt(collection:PersistentCollection, idx:uint, value:*, data:Object):void { collection.setItemAt(value, idx); }
	
	}

}