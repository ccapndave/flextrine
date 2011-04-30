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
	import flash.utils.Dictionary;
	
	import mx.collections.errors.ItemPendingError;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.UIDUtil;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.collections.EntityCollection;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.Closure;
	import org.davekeen.flextrine.util.EntityUtil;

	use namespace flextrine;
	
	/**
	 * @private
	 * @author Dave Keen
	 */
	public class EntityRepository implements IEntityRepository {
		
		public static const STATE_NEW:String = "state_new";
		public static const STATE_MANAGED:String = "state_managed";
		public static const STATE_REMOVED:String = "state_removed";
		public static const STATE_DETACHED:String = "state_detached";
		
		private var em:EntityManager;
		
		private var entityClass:Class;
		
		[Bindable]
		public function set entities(value:EntityCollection):void { _entities = value; }
		public function get entities():EntityCollection { return _entities; }
		private var _entities:EntityCollection;
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		/**
		 * This flag is used to differentiate between entity changes within the repository (which should not mark objects as dirty) and changes from elsewhere.
		 * It would be nice if this wasn't static, but at least for the moment bi-directional relationship can cause changes in one repository to trigger changes
		 * in another, and we don't want updates sent from any.  For the moment leave this static until a prettier solution can be determined.
		 */
		private static var isUpdating:Boolean;
		
		/**
		 * 
		 * @param em The EntityManager containing this entity repository.
		 * @param entityClass The class of entities this repository will manage
		 * @param entityTimeToLive Optionally override the entityTimeToLive defined in the global configuration
		 */
		public function EntityRepository(em:EntityManager, entityClass:Class, entityTimeToLive:Number = NaN) {
			this.em = em;
			this.entityClass = entityClass;
			
			// Initialize the repository
			entities = new EntityCollection(null, (isNaN(entityTimeToLive)) ? em.getConfiguration().entityTimeToLive : entityTimeToLive);
			
			// Add the id fields as an index
			//entities.addIndex(EntityUtil.getIdFields(new entityClass()));
		}
		
		/**
		 * Returns the temporaryUidMap from the current transaction
		 * 
		 * @return 
		 */
		private function get temporaryUidMap():Object {
			return em.getUnitOfWork().temporaryUidMap;
		}
		
		/**
		 * Returns the persistedEntities from the current transaction
		 * 
		 * @return 
		 */
		private function get persistedEntities():Dictionary {
			return em.getUnitOfWork().persistedEntities;
		}
		
		/**
		 * Returns the dirtyEntities from the current transaction
		 * 
		 * @return 
		 */
		private function get dirtyEntities():Dictionary {
			return em.getUnitOfWork().dirtyEntities;
		}
		
		/**
		 * Returns the removedEntities from the current transaction
		 * 
		 * @return 
		 */
		private function get removedEntities():Dictionary {
			return em.getUnitOfWork().removedEntities;
		}
		
		/**
		 * @private 
		 */
		internal function clear():void {
			entities.removeAll();
			
			isUpdating = false;
		}
		
		/**
		 * Get the state of an entity.  An entity which is not yet in a repository is NEW, an object which is in a repository is MANAGED, and object which is an
		 * identified entity but isn't in a repository is DETACHED and an object which is scheduled for removal is REMOVED.
		 * 
		 * @param	entity
		 * @return
		 */
		public function getEntityState(entity:Object):String {
			if (!entity)
				throw new TypeError("Attempted to get entity state of null");
			
			if (ClassUtil.getClass(entity) !== entityClass)
				throw new Error("This is not the correct repository for " + entity + " {entity class = " + ClassUtil.getClassAsString(entity) + ", repository class = " + ClassUtil.getClassAsString(entityClass));
			
			if (!EntityUtil.hasId(entity)) {
				// The entity has no id - if it is persistedEntities it is MANAGED (it has been persisted but not yet flushed), otherwise it is NEW
				return (persistedEntities[entity]) ? STATE_MANAGED : STATE_NEW;
			} else {
				// The entity has an id, so if it is in the array collection it is MANAGED, otherwise it is REMOVED or DETACHED
				var foundEntity:Object = findOneBy(EntityUtil.getIdObject(entity));
				if (foundEntity) {
					return (foundEntity === entity) ? STATE_MANAGED : STATE_DETACHED;
				} else {
					return (removedEntities[entity]) ? STATE_REMOVED : STATE_DETACHED;
				}
			}
		}
		
		/**
		 * Add an entity to the repository and setup listeners on it.  This is called on the returned objects from a load operation.
		 * 
		 * @private 
		 * @param	entity
		 * @param   temporaryUid This is the temporary uid for entities that have been persisted and not yet flushed.  This is only for debug purposes
		 * 						 and is not used by addEntity.
		 */
		flextrine function addEntity(entity:Object, temporaryUid:String = null):Object {
			var idHash:String = EntityUtil.getIdHash(entity);
			
			log.info("Adding " + entity + " {repository=" + ClassUtil.formatClassAsString(entityClass) + ", " + ((temporaryUid) ? "tempUid=" + temporaryUid : "idHash=" + idHash) + "}");
			
			entities.addItem(entity);
			
			addDefaultListenerToManagedEntity(entity);
			
			return entity;
		}
		
		/**
		 * Persists an entity to the repository and setup listeners on it.  This is called on the client when persist is called locally (before a flush).
		 * This method generates a unique id for the persisted entity, so that when flush() is called we can match up the returned entity with the persisted
		 * entity and merge in its id value.
		 * 
		 * @private 
		 * @param	entity
		 * @param	addEntityToRepository If false the entity is added to the temporary map, but not actually added to the repository itself.  Used in WriteMode.PULL
		 */
		internal function persistEntity(entity:Object, addEntityToRepository:Boolean = true):String {
			switch (getEntityState(entity)) {
				case STATE_NEW:
				case STATE_REMOVED:
					// New and removed entities can be persisted
					var temporaryUid:String = UIDUtil.createUID();
					
					// Add the entity to the temporaryUidMap so that addEntity can match it up
					temporaryUidMap[temporaryUid] = entity;
					
					// Add the entity to the persisted entities so we don't persist it twice
					persistedEntities[entity] = true;
					
					if (addEntityToRepository) addEntity(entity, temporaryUid);
					
					return temporaryUid;
				case STATE_MANAGED:
					// If the entity is already managed do nothing
					return null;
				case STATE_DETACHED:
					throw new Error("Behaviour of persist for detached entities is not yet defined");
					break;
			}
			
			return null;
			
			if (getEntityState(entity) == STATE_MANAGED) return null;			
		}
		
		/**
		 * @private 
		 * @param	entity
		 * @return
		 */
		flextrine function updateEntity(entity:Object, checkForPropertyChanges:Boolean = false):Object {
			var idHash:String = EntityUtil.getIdHash(entity);
			
			// Find the existing entity
			var existingEntity:Object = entities.findOneBy(EntityUtil.getIdObject(entity));
			
			// Only update if the entity actually exists
			if (existingEntity) {
				log.info("Updating " + existingEntity + " to " +  entity + " {repository=" + ClassUtil.formatClassAsString(entityClass) + ", idHash=" + idHash + "}");
				
				if (!checkForPropertyChanges) isUpdating = true;
				existingEntity = EntityUtil.mergeEntity(entity, existingEntity);
				
				// Refresh the listeners on the entity
				// TODO: A future performance enhancement could be to only do this if an entity or one of its collections has changed from being uninitialized
				// to initialized.
				addDefaultListenerToManagedEntity(existingEntity);
				
				if (!checkForPropertyChanges) isUpdating = false;
			}
			
			return existingEntity;
		}
		
		/**
		 * When flush() is called and the returned changeset is executed, entity insertions will call this method.  It will first try and match up the entity
		 * with an entity that was persisted on this client and if so merge the changes with it.  If it cannot find the persisted entity in the temporaryUidMap
		 * we assume it was persisted on another client and add to the repository as normal.
		 * 
		 * @private 
		 * @param	entity
		 * @param	temporaryUid
		 * @param	addEntityToRepository If true the entity is also added to the repository.  Used in WriteMode.PULL.
		 */
		internal function addPersistedEntity(entity:Object, temporaryUid:String, addEntityToRepository:Boolean = false):Object {
			if (temporaryUidMap[temporaryUid]) {
				// We found the temporary uid in the repository, so upate the existing entity by reference
				log.info("Updating persisted entity " + entity + " with uid " + temporaryUid);
				
				isUpdating = true;
				EntityUtil.mergeEntity(entity, temporaryUidMap[temporaryUid]);
				isUpdating = false;
				
				if (addEntityToRepository)
					addEntity(temporaryUidMap[temporaryUid]);
				
				// Now this entity has a real id we can ditch the temporary one
				delete temporaryUidMap[temporaryUid];
			} else {
				// The temporary id was not found in the repository so this must have been persisted on another client; add the entity as a new object
				// We found the temporary uid in the repository, so upate the existing entity by reference
				log.info("Got a new persisted entity " + entity);
				
				addEntity(entity);
			}
			
			return entity;
		}
		
		internal function getPersistedEntity(temporaryUid:String):Object {
			return temporaryUidMap[temporaryUid];
		}
		
		internal function getTemporaryUidMap():Object {
			return temporaryUidMap;
		}
		
		internal function clearPersistedEntity(temporaryUid:String):void {
			delete persistedEntities[temporaryUidMap[temporaryUid]];
			delete temporaryUidMap[temporaryUid];
		}
		
		internal function mergeIdentifiers(toEntity:Object, fromEntity:Object):Object {
			isUpdating = true;
			for each (var idField:String in EntityUtil.getIdFields(fromEntity))
				toEntity[idField] = fromEntity[idField];
			isUpdating = false;
				
			return toEntity;
		} 
		
		/**
		 * The only purpose of this is to allow properties on entities to be updated without triggering property change events.
		 * 
		 * @param entity
		 * @param property
		 * @param value
		 * @param checkForPropertyChanges
		 * @return 
		 */
		flextrine function updateEntityProperty(entity:Object, property:String, value:*, checkForPropertyChanges:Boolean = false):void {
			if (!checkForPropertyChanges) isUpdating = true;
			entity[property] = value;
			if (!checkForPropertyChanges) isUpdating = false;
		}
		
		/**
		 * Delete an entity from the repository.  This has extra logic in it that detects if the entity we are removing has not yet been persisted on the
		 * server (i.e. has no id), and if so rolls back the pending persist operation instead of doing a persist then a remove on the server.
		 * 
		 * TODO: This logic doesn't really belong in EntityRepository
		 * 
		 * @private 
		 * @param	entity	The entity to delete
		 * @param	removeEntityFromRepository	If true the entity is not actually removed from the repository.  Used in WriteMode.PULL.
		 * @return	true if we actually need to remove the entity on the server, false if the remove is only local
		 */
		internal function deleteEntity(entity:Object, removeEntityFromRepository:Boolean = true):Boolean {
			var entityState:String = getEntityState(entity);
			
			var idHash:String;
			var entityToRemove:Object;
			
			switch (entityState) {
				case STATE_NEW:
					throw new Error("This entity is NEW and cannot be deleted from this repository.");
					break;
				case STATE_MANAGED:
					if (EntityUtil.hasId(entity)) {
						// Find the existing entity and set it as the entity to remove
						idHash = EntityUtil.getIdHash(entity);
						entityToRemove = entities.findOneBy(EntityUtil.getIdObject(entity));
					} else {
						// If this is a new entity that has been persisted but not yet flushed then removing it actually means removing it from the array collection,
						// removing it from the temporaryUidMap and removing it from the unit of work (so that it won't be flushed next time).  Since there is no id
						// we have to assume that the 'entity' passed is actually the same instance that is in the repository, as we obviously can't find it by its id
						// and the temporary uid is internal.
						entityToRemove = entity;
						
						// Remove from the temporaryUidMap, persistedEntities, dirtyEntities and the unit of work
						for (var temporaryUid:String in temporaryUidMap) {
							if (temporaryUidMap[temporaryUid] === entityToRemove) {
								// Remove from the unit of work
								em.getUnitOfWork().undoPersist(temporaryUid);
								
								// Remove from the temporaryUidMap
								delete temporaryUidMap[temporaryUid];
								
								// Remove from persistedEntities
								delete persistedEntities[entity];
								
								break;
							}
						}
					}
					break;
				case STATE_REMOVED:
					// If the entity has already been removed do nothing
					log.info("Remove called on already removed entity " + entity +  " - ignoring {repository=" + ClassUtil.formatClassAsString(entityClass) + ", idHash=" + idHash + "}");
					return false;
				case STATE_DETACHED:
					throw new Error("You cannot remove a detached entity");
					break;
				default:
					throw new Error("Unknown state '" + entityState + "' for entity " + entity);
			}
			
			log.info("Deleting " + entityToRemove +  " {repository=" + ClassUtil.formatClassAsString(entityClass) + ", idHash=" + idHash + "}");
			
			// Remove the property change listener
			entityToRemove.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, onPropertyChange);
			
			// Add to removed entities
			removedEntities[entityToRemove] = true;
			
			// Remove the entity from the array collection
			if (removeEntityFromRepository) entities.removeItem(entityToRemove);
			
			return (entityState == STATE_MANAGED && EntityUtil.hasId(entity));
		}
		
		internal function detachEntity(entity:Object):void {
			var entityState:String = getEntityState(entity);
			switch (entityState) {
				case STATE_MANAGED:
					// deleteEntity removes the entity from the repository and unit of work
					deleteEntity(entity);
					delete removedEntities[entity];
					break;
				case STATE_NEW:
				case STATE_DETACHED:
					// No need to do anything
					break;
				case STATE_REMOVED:
					log.warn("Attempted to detach REMOVED entity " + entity + ".  Ignoring.");
					break;
			}
		}
		
		/**
		 * Remove all items from the collection without triggering a collection update
		 * 
		 * @param	persistentCollection
		 * @param	associationName
		 */
		flextrine function resetManyAssociation(persistentCollection:PersistentCollection):void {
			isUpdating = true;
			persistentCollection.removeAll();
			//persistentCollection.removeAllNonRecursive();
			isUpdating = false;
		}
		
		/**
		 * Add entityToAdd to the array collection in entity[associationName].  The only reason this is a method of EntityRepository is so that
		 * we can set isUpdating to false whilst making the change therefore not making the object dirty.  addLoadedEntityToRepository makes use
		 * of this when mapping collections to existing objects.
		 * 
		 * @private 
		 * @param	entity
		 * @param	associationName
		 * @param	entityToAdd
		 */
		flextrine function addEntityToManyAssociation(entity:Object, associationName:String, entityToAdd:Object, checkForPropertyChanges:Boolean = false):void {
			if (!checkForPropertyChanges) isUpdating = true;
			entity[associationName].addItem(entityToAdd);
			//entity[associationName].addItemNonRecursive(entityToAdd);
			if (!checkForPropertyChanges) isUpdating = false;
		}
		
		public function find(id:Number):Object {			
			var idTags:XMLList = EntityUtil.getAttributesWithTag(new entityClass(), MetaTags.ID);
			
			if (idTags.length() > 1)
				throw new FlextrineError("EntityRepository.find() cannot be used on entities with composite keys {repository=" + ClassUtil.formatClassAsString(entityClass) + "}");
			
			var idObject:Object = {};
			idObject[idTags[0]] = id;
			
			return entities.findOneBy(idObject);
		}
		
		public function findAll():Array {
			return entities.toArray();
		}
		
		public function findBy(criteria:Object):Array {
			return entities.findBy(criteria);
		}
		
		public function findOneBy(criteria:Object):Object {
			return entities.findOneBy(criteria);
		}
		
		public function load(id:Number, fetchMode:String = null):AsyncToken {
			return em.getDelegate().load(entityClass, id, (fetchMode) ? fetchMode : em.getConfiguration().fetchMode);
		}
		
		public function loadBy(criteria:Object, fetchMode:String = null):AsyncToken {
			return em.getDelegate().loadBy(entityClass, criteria, (fetchMode) ? fetchMode : em.getConfiguration().fetchMode);
		}
		
		public function loadOneBy(criteria:Object, fetchMode:String = null):AsyncToken {
			return em.getDelegate().loadOneBy(entityClass, criteria, (fetchMode) ? fetchMode : em.getConfiguration().fetchMode);
		}
		
		public function loadAll(fetchMode:String = null):AsyncToken {
			return em.getDelegate().loadAll(entityClass, (fetchMode) ? fetchMode : em.getConfiguration().fetchMode);
		}
		
		/**
		 * Add the default listeners for a managed entity
		 * 
		 * @param	entity
		 */
		private function addDefaultListenerToManagedEntity(entity:Object):void {
			addEntityListeners(entity, em.getOnDemandListener().onInitializeEntity, em.getOnDemandListener().onInitializeCollection, onPropertyChange, onCollectionChange);
		}
		
		/**
		 * Add various event listeners to the given entity.
		 * 
		 * @param entity The entity to add the event listeners to
		 * @param initializeEntityListener The listener to invoke when a lazily loaded entity asks to be initialized
		 * @param initializeCollectionListener The listener to invoke when a lazily loaded collection asks to be initialized
		 * @param propertyChangeListener The listener to invoke when a property changes on the entity
		 * @param collectionChangeListener The listener to invoke when a collection changes on the entity
		 */
		private function addEntityListeners(entity:Object, initializeEntityListener:Function = null, initializeCollectionListener:Function = null, propertyChangeListener:Function = null, collectionChangeListener:Function = null):void {
			// TODO: Use a walker here
			
			if (propertyChangeListener != null) {
				entity.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeListener);
				entity.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeListener, false, 0, false);
			}
			
			// Go through the associations and when we find one that is a collection add an event listener to mark this object as dirty if elements are
			// added or removed from the collection.  We don't care about UPDATE events within the collection as these will be taken care of by the contained
			// entity's own repository.
			if (initializeEntityListener != null || initializeCollectionListener != null || collectionChangeListener != null) {
				if (EntityUtil.isInitialized(entity)) {
					for each (var associationAttribute:XML in EntityUtil.getAttributesWithTag(entity, MetaTags.ASSOCIATION)) {
						if (entity[associationAttribute] is PersistentCollection) {
							if (EntityUtil.isCollectionInitialized(entity[associationAttribute])) {
								if (collectionChangeListener != null) {
									// Only add a listener if this is the owning side, as there is no point listening to an inverse side
									if (isOwningAssociation(entity, associationAttribute)) {
										entity[associationAttribute].removeEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeListener);
										entity[associationAttribute].addEventListener(CollectionEvent.COLLECTION_CHANGE, collectionChangeListener, false, 0, true);
									}
								}
							} else {
								if (initializeCollectionListener != null) {
									// If the collection is not initialized add a listener to see if we need to initialize it on demand
									entity[associationAttribute].removeEventListener(EntityEvent.INITIALIZE_COLLECTION, initializeCollectionListener);
									entity[associationAttribute].addEventListener(EntityEvent.INITIALIZE_COLLECTION, initializeCollectionListener, false, int.MAX_VALUE, true);
								}
							}
						}
					}
				} else {
					if (initializeEntityListener != null) {
						// If the entity is not initialized add a listener to see if we need to initialize it on demand
						entity.removeEventListener(EntityEvent.INITIALIZE_ENTITY, initializeEntityListener);
						entity.addEventListener(EntityEvent.INITIALIZE_ENTITY, initializeEntityListener, false, int.MAX_VALUE, true);
					}
				}
			}
		}
		
		/**
		 * Detected a change on a collection.  This may need to trigger an update event on the containing entity.
		 * 
		 * @param e
		 */
		private function onCollectionChange(e:CollectionEvent):void {
			var persistentCollection:PersistentCollection = e.target as PersistentCollection;
			
			var entity:Object = persistentCollection.getOwner();
			var attributeName:String = persistentCollection.getAssociationName();
			
			if (e.kind == CollectionEventKind.ADD || e.kind == CollectionEventKind.REMOVE || e.kind == CollectionEventKind.RESET || e.kind == CollectionEventKind.REPLACE)
				entity.dispatchEvent(PropertyChangeEvent.createUpdateEvent(entity, attributeName, "Collection: " + e.kind, e.items));
		}
		
		/**
		 * Detected a change on a repository entity.  We may need to mark it dirty.
		 * 
		 * @param	e
		 */
		private function onPropertyChange(e:PropertyChangeEvent):void {
			if (!isUpdating) {
				var entityState:String = getEntityState(e.currentTarget);
				
				switch (entityState) {
					case STATE_NEW:
						throw new Error("There shouldn't be a property change listener on a new object");
						break;
					case STATE_MANAGED:
						if (em.getConfiguration().writeMode == WriteMode.PULL)
							throw new FlextrineError("Attempted to change an entity directly when in WriteMode.PULL (" + e.source + ", " + e.property + ")", FlextrineError.ATTEMPTED_WRITE_TO_REPOSITORY_ENTITY);
						
						// If the entity is uninitialized we don't want to do anything
						if (!EntityUtil.isInitialized(e.source))
							return;
						
						// A special case; if the property is a Date and the time is the same we don't want to update
						if (e.source[e.property] is Date)
							if (e.oldValue && e.newValue && e.newValue.time == e.oldValue.time)
								return;
						
						// Mark the entity as dirty in the dirtyEntities map so we know what to do on an em.rollback() within the current transaction.
						if (dirtyEntities[e.source] == null) {
							// Get a memento for the entity
							dirtyEntities[e.source] = e.source.flextrine::saveState();
							
							// and since we are in onPropertyChange change back the property that caused this handler to be fired, giving us the original
							if (e.source[e.property] is PersistentCollection) {
								log.error("Memento saving needs to be fixed for PersistentCollections! (" + e.source + "[" + e.property + "]");
							} else {
								dirtyEntities[e.source][e.property] = e.oldValue;
							}
						}
						
						// If this is a property, or the owning side of an association we need to mark for server-side merging
						if (!EntityUtil.isAssociation(e.source, e.property.toString()) || isOwningAssociation(e.source, e.property.toString())) {
							log.info("Detected change on managed entity " + e.currentTarget + " - property '" + e.property + "' from '" + e.oldValue + "' to '" + e.newValue + "' {repository = " + ClassUtil.formatClassAsString(entityClass) + "}");
							if (!persistedEntities[e.currentTarget])
								em.getUnitOfWork().merge(e.currentTarget);
						}
						break;
					case STATE_REMOVED:
						throw new Error("A change was detected on a removed entity; this is an error as there shouldn't be any listeners on the entity anymore!");
						break;
					case STATE_DETACHED:
						throw new Error("A change was detected on a detached entity; this is an error as there shouldn't be any property listeners on the entity!");
						break;
				}
			}
		}
		
		/**
		 * Use EntityUtil to determine whether the given association in the given entity is the owning side or not; Flextrine only sends changes to the
		 * owning side to the server for updates (as it is pointless sending inverse sides as they will be ignored by Doctrine anyway).
		 * 
		 * @param entity
		 * @param associationName
		 * @return 
		 */
		private function isOwningAssociation(entity:Object, associationName:String):Boolean {
			return EntityUtil.getMetaDataForAttributeAndTag(entity, associationName, MetaTags.ASSOCIATION).arg.(@key == "side").@value == "owning";
		}
		
	}

}