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
					data.targetEntity = data.entityRepository.updateEntity(entity, isMerge);
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
					if (EntityUtil.isCollectionInitialized(collection))
						data.entityRepository.resetManyAssociation(data.targetEntity[associationName]);
					break;
			}
		}
		
		protected override function propertyAction(entity:Object, associationName:String, data:Object):void {
			// This is the same as the parent property, except it targets data.targetEntity instead of entity
			var relatedEntity:Object = entity[associationName];
			setProperty(data.targetEntity, associationName, relatedEntity ? doWalk(replaceEntity(relatedEntity, data)) : null);
		}
		
		protected override function collectionAction(collection:PersistentCollection, associationName:String, idx:uint, data:Object):void {
			var relatedEntity:Object = collection.getItemAt(idx);
			
			switch (data.mergeType) {
				case UPDATE:
				case DETACHED:
					// We will have removed the collection in beforeCollectionWalk, so add them back in with the recursive results
					data.entityRepository.addEntityToManyAssociation(data.targetEntity, associationName, doWalk(replaceEntity(collection.source[idx], data)), isMerge);
					break;
				case ADD:
				case THIS:
					var addedEntity:Object = doWalk(replaceEntity(relatedEntity, data));
					
					// If the original element was unitialized then replace it with the possibly initialized version
					if (!EntityUtil.isInitialized(relatedEntity))
						setItemAt(collection, idx, addedEntity);
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
			// If we are merging then naively add merge to the unit of work.  This may be unnecessary as the client will figure out whether anything has changed
			// through the normal methods, but this protects against entities being garbage collected.  Improve on this in the future.
			//if (isMerge)
			//	em.getUnitOfWork().merge(data.targetEntity);
		}
		
		/**
		 * Use updateEntityProperty to set a property on the entity (this temporarily disables the property change handlers whilst doing the update)
		 * 
		 * @param entity
		 * @param property
		 * @param value
		 */
		protected override function setProperty(entity:Object, property:String, value:*):void {
			(em.getRepository(ClassUtil.getClass(entity)) as EntityRepository).updateEntityProperty(entity, property, value, isMerge);
		}
		
	}

}