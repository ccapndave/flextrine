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
	import mx.messaging.management.Attribute;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.EntityManager;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	
	use namespace flextrine;
	
	/**
	 * TODO: em.detach() followed by em.merge() currently doesn't work properly; the LocalMergeWalker needs to work out if we are doing an ADD and isMerge == true, and if so
	 * we need to push PropertyChangeOperations and RESET CollectionChangeOperations for every property and association on an initialized entity as the detached entity is no
	 * longer in the repository and we have no way of knowing what might have changed.  We could possibly get away with persisting it instead.
	 * 
	 * For the moment detachCopy works properly (and is actually much more useful)
	 * 
	 * @private 
	 */
	public class LocalMergeWalker extends AbstractWalker {
		
		private var em:EntityManager;
		
		private var isMerge:Boolean;
		
		private var detachedEntity:Object;
		
		/**
		 * The ADD mergetype means that we are adding this entity to the repository, so this is the instance we will be merging
		 */ 
		private static const ADD:String = "add";
		
		/**
		 * The UPDATE mergetype means that an entity with this id already exists in the repository, so we are merging data into that instance
		 */
		private static const UPDATE:String = "update";
		
		/**
		 * The THIS mergetype means that this already *is* the entity that is in the repository.
		 */
		private static const THIS:String = "this";
		
		/**
		 * The target entity itself is a detached entity.  This is generally when an entity detached with em.detachCopy does some on-demand loading, but
		 * the target entity needs to remain detached. 
		 */
		private static const DETACHED:String = "detached";
		
		public function LocalMergeWalker(em:EntityManager, isMerge:Boolean = false, detachedEntity:Object = null) {
			this.em = em;
			this.isMerge = isMerge;
			this.detachedEntity = detachedEntity;
		}
		
		protected override function setupWalk(entity:Object, data:Object):void {
			data.isMerge = isMerge;
			
			// Check if this entity already exists in its repository and set the mergeType and targetEntity accordingly
			data.entityRepository = em.getRepository(ClassUtil.getClass(entity)) as EntityRepository;
			
			if (!detachedEntity) {
				var repoEntity:Object = data.entityRepository.findOneBy(EntityUtil.getIdObject(entity));
				if (repoEntity) {
					// If entity is already the instance in the repository then we have mergeType THIS, otherwise mergeType UPDATE
					data.mergeType = (repoEntity === entity) ? THIS : UPDATE;
					data.targetEntity = repoEntity;
				} else {
					// If we need to add the entity to the repository we have mergeType ADD
					data.mergeType = ADD;
					data.targetEntity = entity;
				}
			} else {
				data.mergeType = DETACHED;
				data.targetEntity = detachedEntity;
				
				// We only want to do this on the top level, so set detachedEntity to null at this point.
				detachedEntity = null;
			}
		}
		
		protected override function beforeWalk(entity:Object, data:Object):void {
			switch (data.mergeType) {
				case ADD:
					data.targetEntity = data.entityRepository.addEntity(entity);
					break;
				case UPDATE:
					var checkForPropertyChanges:Boolean = data.isMerge && EntityUtil.isInitialized(entity) && EntityUtil.isInitialized(data.targetEntity);
					data.targetEntity = data.entityRepository.updateEntity(entity, checkForPropertyChanges);
					break;
				case DETACHED:
					data.targetEntity = EntityUtil.mergeEntity(entity, data.targetEntity);
					break;
				case THIS:
					break;
			}
		}
		
		protected override function beforeCollectionWalk(collection:PersistentCollection, owner:Object, associationName:String, data:Object):void {
			// Set properties on the collection
			collection.setOwner(owner);
			collection.setAssociationName(associationName);
			
			switch (data.mergeType) {
				case UPDATE:
				case DETACHED:
					// We want to remove everything from the targetEntity's existing many association (it will be re-added in collectionAction)
					if (EntityUtil.isCollectionInitialized(collection)) {
						var checkForPropertyChanges:Boolean = data.isMerge;
						data.entityRepository.resetManyAssociation(data.targetEntity[associationName], checkForPropertyChanges);
					}
					break;
			}
		}
		
		protected override function propertyAction(entity:Object, associationName:String, data:Object):void {
			// This is the same as the parent property, except it targets data.targetEntity instead of entity
			var relatedEntity:Object = entity[associationName];
			setProperty(data.targetEntity, associationName, relatedEntity ? doWalk(replaceEntity(relatedEntity, data)) : null, data);
		}
		
		protected override function collectionAction(collection:PersistentCollection, associationName:String, idx:uint, data:Object):void {
			var relatedEntity:Object = collection.getItemAt(idx);
			
			switch (data.mergeType) {
				case UPDATE:
				case DETACHED:
					// We will have removed the collection in beforeCollectionWalk, so add them back in with the recursive results
					var checkForPropertyChanges:Boolean = data.isMerge;
					data.entityRepository.addEntityToManyAssociation(data.targetEntity, associationName, doWalk(replaceEntity(collection.source[idx], data)), checkForPropertyChanges);
					break;
				case ADD:
				case THIS:
					var addedEntity:Object = doWalk(replaceEntity(relatedEntity, data));
					
					// If the original element was unitialized then replace it with the possibly initialized version
					if (!EntityUtil.isInitialized(relatedEntity))
						setItemAt(collection, idx, addedEntity, data);
					
					break;
			}
		}
		
		protected override function returnEntity(entity:Object, data:Object):Object {
			if (data.mergeType == DETACHED) {
				return data.targetEntity; 
			} else {
				return em.getRepository(ClassUtil.getClass(entity)).findOneBy(EntityUtil.getIdObject(entity)) || data.targetEntity;
			}
		}
		
		protected override function afterWalk(entity:Object, data:Object):void {
			
		}
		
		/**
		 * Use updateEntityProperty to set a property on the entity (this temporarily disables the property change handlers whilst doing the update)
		 * 
		 * @param entity
		 * @param property
		 * @param value
		 */
		protected override function setProperty(entity:Object, property:String, value:*, data:Object):void {
			(em.getRepository(ClassUtil.getClass(entity)) as EntityRepository).updateEntityProperty(entity, property, value, data.isMerge);
		}
		
	}

}