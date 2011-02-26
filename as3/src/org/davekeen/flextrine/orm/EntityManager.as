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
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.core.mx_internal;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.logging.LogEventLevel;
	import mx.logging.targets.TraceTarget;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.collections.PagedCollection;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.delegates.FlextrineDelegate;
	import org.davekeen.flextrine.orm.events.FlextrineEvent;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.orm.rpc.FlextrineAsyncResponder;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.davekeen.flextrine.util.QueryUtil;
	
	// Required for token.applyResult
	use namespace mx_internal;
	
	/**
	 * The EntityManager is the central access point to the ORM functionality provided by Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class EntityManager extends EventDispatcher {
		
		private static var _instance:EntityManager;
		private static var singletonInstantiation:Boolean;
		
		private var repositories:Dictionary;
		
		private var unitOfWork:UnitOfWork;
		
		private var flextrineDelegate:FlextrineDelegate;
		
		// The configuration of this EntityManager
		private var configuration:Configuration;
		
		// This object is used to track cyclical references and ensure we don't get into an inifinite loop when adding heirarchical objects to the repositories
		private var visited:Object;
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		/**
		 * @private
		 */
		public function EntityManager() {
			// Ensure singleton integrity
			if (!singletonInstantiation)
				throw new Error("EntityManager is a singleton and can only be accessed through getInstance()");
			
			// Configure logging for use within Flextrine
			var logTarget:TraceTarget = new TraceTarget();
			logTarget.filters = [ "org.davekeen.*" ];
			logTarget.level = LogEventLevel.ALL;
			logTarget.includeDate = false;
			logTarget.includeTime = false;
			logTarget.includeCategory = true;
			logTarget.includeLevel = true;
			Log.addTarget(logTarget);
			
			unitOfWork = new UnitOfWork(this);
			repositories = new Dictionary(true);
			
			// Check the the required metadata is compiled into the class
			MetaTags.checkKeepMetaData();
		}
		
		/**
		 * Get a singleton instance of the EntityManager.
		 * 
		 * @return
		 */
		public static function getInstance():EntityManager {
			if (!_instance) {
				singletonInstantiation = true;
				_instance = new EntityManager();
				singletonInstantiation = false;
			}
			
			return _instance;
		}
		
		/**
		 * Get direct access to the unit of work.  Public access to this might be removed in the future as, unlike Doctrine 2, changing
		 * things directly in the UoW can potentially put Flextrine in an unstable state.
		 * 
		 * @return
		 */
		public function getUnitOfWork():UnitOfWork {
			return unitOfWork;
		}
		
		/**
		 * @private 
		 * @return
		 */
		internal function getDelegate():FlextrineDelegate {
			if (!flextrineDelegate) {
				if (!configuration)
					throw new Error("You must use setConfiguration to set the configuration of the EntityManager before using Flextrine");
				
				// Create the delegate for RPC calls to PHP.  Since other programs can hook into these events we need to give these maximum priority as there
				// are Flextrine specific tasks (e.g. populating the repositories) that need to be done before anything else.  Use a priority of int.MAX_VALUE
				// to achieve this.
				flextrineDelegate = new FlextrineDelegate(configuration.gateway, configuration.service);
				flextrineDelegate.addEventListener(FlextrineEvent.LOAD_COMPLETE, onFlextrineLoadComplete, false, int.MAX_VALUE, false);
				flextrineDelegate.addEventListener(FlextrineEvent.FLUSH_COMPLETE, onFlextrineFlushComplete, false, int.MAX_VALUE, false);
			}
			
			return flextrineDelegate;
		}
		
		/**
		 * Set the configuration of the EntityManager.  A configuration <b>must</b> be provided, and at least <code>configuration.gateway</code> must be set
		 * in that configuration in order to use Flextrine.
		 * 
		 * @param	configuration The configuration to apply to the <code>EntityManager</code>
		 */
		public function setConfiguration(configuration:Configuration):void {
			this.configuration = configuration;
		}
		
		/**
		 * Get the currently set configuration on this <code>EntityManager</code>.
		 * 
		 * @return The current configuration on the <code>EntityManager</code>
		 */
		public function getConfiguration():Configuration {
			return configuration;
		}
		
		/**
		 * Add the entity to its repository and mark it for insertion into the database on the next <code>flush</code>.
		 * 
		 * @param	entity
		 * @return
		 */
		public function persist(entity:Object):Object {
			// Add the entity to the appropriate repository, and receive a temporary id back
			var temporaryUid:String = (getRepository(ClassUtil.getClass(entity)) as EntityRepository).persistEntity(entity, configuration.writeMode != WriteMode.PULL);
			
			// If the entity was already persisted we get null back and do nothing
			if (temporaryUid) {
				log.info("Persisting " + entity);
				
				// Add the persist operation to the unit of work
				unitOfWork.persist(entity, temporaryUid);
				
				// Return the entity to aid in the chaining methods together
				return entity;
			} else {
				return null;
			}
		}
		
		/**
		 * Return an unmanaged copy of the given entity.  This entity is not the same instance as that in the repository and
		 * changes to its properties will not trigger updates on the database.  This has no effect on the entity given as a parameter -
		 * it remains in its repository as a fully managed entity.
		 * 
		 * <p>Typically <code>detach</code> would be used in situations where you want to make changes to an entity that might be
		 * discarded; for example, an edit window with a <b>Save</b> and <b>Cancel</b> button.  If the user hits <b>cancel</b> the unmanaged entity can just be
		 *  thrown away, or otherwise <code>EntityManager.merge</code> can be used to merge changes back into the repository.</p>
		 * 
		 * <p>Note that since <code>detach</code> returns an <code>Object</code> it will probably want to be cast to a strongly typed object.
		 * 
		 * @example To get an unmanaged copy of a <code>user</code> entity:
		 * 
		 * <pre>
		 * var unmanagedUser:User = em.detach(managedUser) as User;
		 * </pre>
		 * 
		 * @param	entity The entity to detach.
		 * @return  An unmanaged copy of the entity
		 */
		public function detach(entity:Object):Object {
			log.info("Detaching " + entity);
			
			return EntityUtil.copyEntity(entity);
		}
		
		/**
		 * Merge a detached entity back into Flextrine.  If the entity has changed compared to its merged counterpart the merged
		 * object will be marked dirty and scheduled for update on the next flush.
		 * 
		 * <p><code>merge</code> is the opposite operation to <code>detach</code>
		 * 
		 * @example Thie following example detaches an entity, makes a change, then merges it back into the repository:
		 * 
		 * <pre>
		 * var unmanagedUser:User = em.detach(managedUser) as User;
		 * unmanagedUser.name = "A different name";
		 * em.merge(unmanagedUser);
		 * 
		 * // This will write the changes that were made to the entity whilst it was detached
		 * em.flush();
		 * </pre>
		 * 
		 * @param	entity The entity to merge
		 * @return  The managed entity.  This will be a different instance to the entity that was passed into the method.
		 */
		public function merge(entity:Object):Object {
			log.info("Merging " + entity);
			
			switch (getConfiguration().writeMode) {
				case WriteMode.PUSH:
					return addLoadedEntityToRepository(entity, true);
				case WriteMode.PULL:
					return unitOfWork.merge(entity);
			}
			
			return null;
		}
		
		/**
		 * Remove an entity from the repository and mark it for deletion from the database on the next flush.
		 * 
		 * @example The following example will remove the given user from the database
		 * 
		 * <pre>
		 * em.remove(user);
		 * em.flush();
		 * </pre>
		 * 
		 * @param	entity The entity to remove
		 * @return The entity that was removed
		 */
		public function remove(entity:Object):Object {
			if ((getRepository(ClassUtil.getClass(entity)) as EntityRepository).deleteEntity(entity, configuration.writeMode != WriteMode.PULL)) {
				log.info("Removing " + entity);
				unitOfWork.remove(entity);
			}
			
			// Return the entity to aid in the chaining methods together
			return entity;
		}
		
		/**
		 * Run a DQL select query against the database.  Use <code>EntityManager.getDQLClass</code> to convert a Flextrine entity or entity class
		 * into a DQL fully qualified class name.
		 * 
		 * @param	query
		 * @param	fetchMode
		 * @return
		 */
		public function select(query:Query, fetchMode:String = null):AsyncToken {
			log.info("Selecting " + query.dql);
			
			return getDelegate().select(query, 0, 0, (fetchMode) ? fetchMode : getConfiguration().fetchMode);
		}
		
		public function selectPaged(query:Query, pageSize:uint, fetchMode:String = null):PagedCollection {
			log.info("Selecting (paged) " + query.dql);
			
			var pagedCollection:PagedCollection = new PagedCollection();
			pagedCollection.setDelegate(getDelegate());
			pagedCollection.setQuery(query);
			
			return pagedCollection;
		}
		
		/**
		 * Run a DQL select query against the database.  Use <code>EntityManager.getDQLClass</code> to convert a Flextrine entity or entity class
		 * into a DQL fully qualified class name.  Only returns the first results - all others are discarded on the server.
		 * 
		 * @param	query
		 * @param	fetchMode
		 * @return
		 */
		public function selectOne(query:Query, fetchMode:String = null):AsyncToken {
			log.info("Selecting (one) " + query.dql);
			
			return getDelegate().selectOne(query, (fetchMode) ? fetchMode : getConfiguration().fetchMode);
		}
		
		/**
		 * This is a convenience method to save having to explicitly retrieve the repository.
		 * It is equivalent to calling <code>em.getRepository(entityClass).load(id)</code>
		 * 
		 * @param	entityClass
		 * @param	id
		 * @param	fetchMode
		 * @return
		 */
		public function load(entityClass:Class, id:Number, fetchMode:String = null):AsyncToken {
			log.info("Loading " + entityClass.toString() + " id=" + id);
			
			return getRepository(entityClass).load(id, fetchMode);
		}
		
		/**
		 * This is a convenience method to save having to explicitly retrieve the repository.
		 * It is equivalent to calling <code>em.getRepository(entityClass).loadOneBy(criteria)</code>
		 * 
		 * @param	entityClass
		 * @param	criteria
		 * @param	fetchMode
		 * @return
		 */
		public function loadOneBy(entityClass:Class, criteria:Object, fetchMode:String = null):AsyncToken {
			log.info("Loading one by " + entityClass.toString() + ObjectUtil.toString(criteria));
			
			return getRepository(entityClass).loadOneBy(criteria, fetchMode);
		}
		
		/**
		 * This is a convenience method to save having to explicitly retrieve the repository.
		 * It is equivalent to calling <code>em.getRepository(entityClass).loadBy(criteria)</code>
		 * 
		 * @param	entityClass
		 * @param	criteria
		 * @param	fetchMode
		 * @return
		 */
		public function loadBy(entityClass:Class, criteria:Object, fetchMode:String = null):AsyncToken {
			log.info("Loading by " + entityClass.toString() + ObjectUtil.toString(criteria));
			
			return getRepository(entityClass).loadBy(criteria, fetchMode);
		}
		
		/**
		 * This is a convenience method to save having to explicitly retrieve the repository.
		 * It is equivalent to calling <code>em.getRepository(entityClass).loadAll()</code>
		 * 
		 * @param	entityClass
		 * @param	fetchMode
		 * @return
		 */
		public function loadAll(entityClass:Class, fetchMode:String = null):AsyncToken {
			log.info("Loading all " + entityClass.toString());
			
			return getRepository(entityClass).loadAll(fetchMode);
		}
		
		/**
		 * Flush all outstanding changes to the database.  Until <code>flush</code> is called, no changes will ever be written to the database.
		 * 
		 * @param	fetchMode
		 * @return
		 */
		public function flush(fetchMode:String = null):AsyncToken {
			log.info("Flushing");
			
			return unitOfWork.flush((fetchMode) ? fetchMode : getConfiguration().fetchMode);
		}
		
		/**
		 * Call a custom method on a remote service.  By default this will call a remote method on the default <code>FlextrineService</code>, but its also
		 * possible to specify a different service in the <code>services</code> folder by using the notation &lt;remoteServiceName&gt;.&lt;remoteMethodName&gt;
		 * 
		 * <p>This method returns an <code>AsyncToken</code> to which you can attach responders in order to handle the result.</p>
		 * 
		 * @example Call a <code>doSomething</code> remote method in <code>FlextrineService</code>
		 * 
		 * <pre>
		 * em.callRemoteMethod("doSomething");
		 * </pre>
		 * 
		 * @example Call a <code>doSomethingElse</code> remote method on a service called <code>MyNewService</code>
		 * 
		 * <pre>
		 * em.callRemoteMethod("MyNewService.doSomethingElse");
		 * </pre>
		 * 
		 * @example Call the <code>addTwoNumbers</code> method on FlextrineService and handle the result
		 * 
		 * <pre>
		 * em.callRemoteMethod("addTwoNumbers", 2, 3).addResponder(new AsyncResponder(onAddTwoNumbersResult, null));
		 * 
		 * function onAddTwoNumbersResult(e:ResultEvent, token:Object):void {
		 *   trace("The answer is " + e.result);
		 * }
		 * </pre>
		 * 
		 * @param	methodName The name of the method.  This can either be in the form <code>&lt;remoteMethodName&gt;</code> or
		 * 					   <code>&lt;remoteServiceName&gt;.&lt;remoteMethodName&gt;</code>
		 * @param	...args    A variable length list of arguments that will be passed directly to the remote method.
		 * @return  An AsyncToken which can be used to handle a result or fault.
		 */
		public function callRemoteMethod(methodName:String, ...args):AsyncToken {
			log.info("Calling remote method " + methodName + " " + ObjectUtil.toString(args));
			
			return getDelegate().callRemoteMethod(methodName, args);
		}
		
		/**
		 * Ensure that a single valued association is loaded before taking an action.  If the association is already loaded this
		 * calls <code>onResult</code> instantly.
		 * 
		 * @example To initalize a lazily loaded single valued association <code>owner</code> on a <code>dog</code> entity:
		 * 
		 * <pre>
		 * em.requireOne(dog.owner, onOwnerLoaded);
		 * 
		 * function onOwnerLoaded():void {
		 *   trace(dog.owner + " is now initialized");
		 * }
		 * </pre>
		 * 
		 * @param	entity The uninitialized entity to load.
		 * @param	onResult A callback to invoke when the single valued association has loaded.
		 * @param	onFault A callback if the require fails.
		 * @return
		 */
		public function requireOne(entity:Object, onResult:Function = null, onFault:Function = null, fetchMode:String = null):AsyncToken {
			if (entity is PersistentCollection)
				throw new FlextrineError("requireOne can only be called on a single valued association, not a collection", FlextrineError.ILLEGAL_REQUIRE);
			
			log.info("Requiring one " + entity);
			
			if (EntityUtil.isInitialized(entity)) {
				if (onResult != null) onResult();
				// TODO: This should return an AsyncToken that initializes instantly
				return null;
			} else {
				var asyncToken:AsyncToken = getRepository(ClassUtil.getClass(entity)).loadOneBy(EntityUtil.getIdObject(entity), fetchMode);
				if (onResult != null || onFault != null) asyncToken.addResponder(new AsyncResponder(onResult, onFault));
				return asyncToken;
			}
		}
		
		/**
		 * Ensure that a many valued collection is loaded before taking an action.  If the collection is already loaded this
		 * calls <code>onResult</code> instantly.
		 * 
		 * @example To initalize a lazily loaded collection association <code>toes</code> on a <code>foot</code> entity:
		 * 
		 * <pre>
		 * em.requireMany(foot, "toes", onToesLoaded);
		 * 
		 * function onToesLoaded():void {
		 *   trace("We loaded " + foot.toes.length + " toes");
		 * }
		 * </pre>
		 * 
		 * It is also possible to use an array of attribute names if you need to required more than one association at a time.
		 * A common usage of this would be to wrap a block that works on possibly uninitialized collections in a requireMany
		 * call with all the associations:
		 * 
		 * <pre>
		 * em.requireMany(foot, [ "toes", "nails" ], function():void {
		 * 	foot.toes.add(new Toe());
		 *  foor.nails.add(new Nail());
		 * } );
		 * </pre>
		 * 
		 * @param	entity The entity containing the unitialized collection.
		 * @param	manyAttributeName The name of the collection attribute as a String, or an array of String attributes
		 * @param	onResult A callback to invoke when the collection association has loaded.
		 * @param	onFault A callback if the require fails.
		 * @return
		 */
		public function requireMany(parentEntity:Object, manyAttributeNames:*, onResult:Function = null, onFault:Function = null, fetchMode:String = null):AsyncToken {
			log.info("Requiring many " + parentEntity + " - " + manyAttributeNames);
			
			return doRequireMany(parentEntity, (manyAttributeNames is Array) ? manyAttributeNames : [ manyAttributeNames ], onResult, onFault, fetchMode);
		}
		
		private function doRequireMany(parentEntity:Object, manyAttributeNames:Array, onResult:Function = null, onFault:Function = null, fetchMode:String = null):AsyncToken {
			var associationsToLoad:Array = [ ];
			
			for each (var manyAttributeName:String in manyAttributeNames) {
				if (!(parentEntity[manyAttributeName] is PersistentCollection))
					throw new FlextrineError("requireMany can only be called on a PersistentCollection (" + manyAttributeName + ")", FlextrineError.ILLEGAL_REQUIRE);
				
				if (!EntityUtil.isCollectionInitialized(parentEntity[manyAttributeName]))
					associationsToLoad.push(manyAttributeName);
			}
			
			if (associationsToLoad.length == 0) {
				if (onResult != null) onResult();
				// TODO: This should return an AsyncToken that initializes instantly
				return null;
			} else {
				// Build up the fetch query to refetch the parentEntity but fetch joined to the association we are requiring
				var query:String = "SELECT p, " + associationsToLoad.join(", ") + " FROM " + QueryUtil.getDQLClass(parentEntity) + " p ";
				for each (var associationName:String in associationsToLoad)
					query += "LEFT JOIN p." + associationName + " " + associationName + " ";
				
				query += "WHERE p.id=" + parentEntity.id;
				
				var asyncToken:AsyncToken = selectOne(new Query(query), fetchMode);
				if (onResult != null || onFault != null) asyncToken.addResponder(new AsyncResponder(onResult, onFault));
				return asyncToken;
			}
		}
		
		/**
		 * Get the <code>EntityRepository</code> for the given class.  If the repository does not exist then create an empty one and return it.
		 * 
		 * @param	entityClass
		 * @param	entityTimeToLive An optional parameter that will override Configuration.entityTimeToLive for this particular repository.  This is useful
		 * 			if you have a particular repository (e.g. Categories) that you are going to load on application startup and then never want to be garbage
		 * 			collected, in which case you would set this parameter to -1.  This can only ever be set on the very first call to getRepository otherwise
		 * 			an error will be thrown.
		 * @return
		 */
		public function getRepository(entityClass:Class, entityTimeToLive:Number = NaN):IEntityRepository {
			if (!repositories[entityClass]) {
				repositories[entityClass] = new EntityRepository(this, entityClass, entityTimeToLive);
			} else {
				if (!isNaN(entityTimeToLive))
					throw new Error("entityTimeToLive can only be overwritten for a repository on the very first call to getRepository");
			}
			
			return repositories[entityClass] as IEntityRepository;
		}
		
		/**
		 * This method empties the repositories and clears any operations scheduled in the <code>UnitOfWork</code>.  This method should be used with care
		 * as after it has been invoked any references to entities that were previously in the repositories will become <i>orphaned</i> and will no longer
		 * be managed.
		 */
		public function clear():void {
			for each (var repository:EntityRepository in repositories)
				repository.clear();
			
			unitOfWork = new UnitOfWork(this); // TODO: This should probably call unitOfWork.clear() instead
		}
		
		/**
		 * Rollback any entities to the state they were in when last loaded from the database.  This will discard any changes to properties or associations
		 * since the last load or flush.
		 */
		public function rollback():void {
			if (!configuration.enabledRollback)
				throw new Error("In order to use em.rollback() you must set enabledRollback in the configuration to true");
			
			log.info("Rolling back");
			
			for each (var repository:EntityRepository in repositories)
				repository.rollback();
			
			unitOfWork.clear();
		}
		
		private function onFlextrineLoadComplete(e:FlextrineEvent):void {
			// If we got nothing back then no changes are required on the server so we don't need to do anything
			if (!e.data) return;
			
			// Normal queries return an entity or an array of entities, but pages queries need to return the total count too so they return an object
			// with 'results' and 'count'.  If e.data has a results property then make that the results, otherwise use e.data itself.
			var results:* = e.data.hasOwnProperty("results") ? e.data.results : e.data;
			
			// Convert the result to an array (even if it is a single entity returned from load())
			var entities:Array = (results is Array) ? results as Array : [ results ];
			
			// Loading objects that are already in the repository results in a merge which means that we can't just return e.data to any responders that were
			// added to the original load call.  Instead we need to build up a new result (which will be an array or an array of entities) and replace the
			// result in the AsyncToken with it.
			var result:Object;
			
			// Add everything to the repository filling in result along the way
			if (results is Array) {
				result = [];
				// If we have an array its a special case and we want to maintain the cyclical reference visited array between
				// calls to addLoadedEntityToRepository, so clear it here and use doAddLoadedEntityToRepository directly
				visited = new Object();
				for each (var entity:Object in entities)
					result.push(doAddLoadedEntityToRepository(entity));
			} else {
				result = addLoadedEntityToRepository(results);
			}
			
			// Re-apply the result to the token.  We need to remove all responders added by Flextrine (FlextrineAsyncResponders) which will only leave
			// ones added by the user.
			var resultEvent:ResultEvent = e.resultEvent;
			
			for (var flextrineResponderCount:uint = 0; flextrineResponderCount < resultEvent.token.responders.length; flextrineResponderCount++)
				if (!(resultEvent.token.responders[flextrineResponderCount] is FlextrineAsyncResponder))
					break;
			
			resultEvent.token.responders.splice(0, flextrineResponderCount);
			resultEvent.token.applyResult(new ResultEvent(ResultEvent.RESULT, resultEvent.bubbles, resultEvent.cancelable, e.data.hasOwnProperty("results") ? { results: result, count: e.data.count } : result, resultEvent.token, resultEvent.message));
		}
		
		/**
		 * This adds an entity to the applicable EntityRepositories by recursively adding the object itself, followed by its [MappedAssociations].
		 * Once this method has run the repositories will have been populated with the entity tree in the given entity allowing find, findBy and
		 * findAll operations to run locally for each repository.  Note that this method tracks cyclical references so we don't end up in an infinite
		 * loop.
		 * 
		 * @param	entity  The entity to add to the repository
		 */
		private function addLoadedEntityToRepository(loadedEntity:Object, checkForPropertyChanges:Boolean = false):Object {
			// Clear the cyclical reference tracker
			visited = new Object();
			
			return doAddLoadedEntityToRepository(loadedEntity, checkForPropertyChanges);
		}
		
		private function doAddLoadedEntityToRepository(loadedEntity:Object, checkForPropertyChanges:Boolean = false):Object {
			var oid:String = EntityUtil.getUniqueHash(loadedEntity);
			
			// Add the entity itself to the appropriate repository
			if (!visited[oid]) {
				
				// Add the entity to the list of visited entities to ensure we don't add the same entity twice
				visited[oid] = true;
				
				// Check if this entity already exists in its repository
				var repository:EntityRepository = getRepository(ClassUtil.getClass(loadedEntity)) as EntityRepository;
				var foundEntity:Object = repository.findOneBy(EntityUtil.getIdObject(loadedEntity));
				
				var repoEntity:Object;
				
				if (!foundEntity) {
					// If the entity doesn't already exist then add it
					repoEntity = (getRepository(ClassUtil.getClass(loadedEntity)) as EntityRepository).addEntity(loadedEntity);
				} else {
					// Update the existing entity with the values from the entity that was just loaded
					repoEntity = repository.updateEntity(loadedEntity, checkForPropertyChanges);
				}
				
				// Get the repository for the repoEntity
				var repoEntityRepository:EntityRepository = getRepository(ClassUtil.getClass(repoEntity)) as EntityRepository;
			
				// Go through the associations adding or remapping as appropriate.  If the entity is a lazily loaded stub we don't want to do this.
				if (EntityUtil.isInitialized(loadedEntity)) {
					for each (var associationAttribute:XML in EntityUtil.getAttributesWithTag(loadedEntity, MetaTags.ASSOCIATION)) {
						// Cascade through the owning (mapped) associations calling doAddLoadedEntityToRepository on each associated entity.
						var value:* = loadedEntity[associationAttribute];
						
						if (value is PersistentCollection) {
							// The association is a collection
							
							// Inject some stuff into the PersistentCollection that it needs for lazy loading
							(value as PersistentCollection).setOwner(repoEntity);
							(value as PersistentCollection).setAssociationName(associationAttribute);
							
							// If the repoEntity is a different instance to the loadedEntity (i.e. we found a matching one in the repository) and
							// this collection is initalized in the loadedEntity, we are going to totally replace the collection in the repoEntity so
							// delete anything that is there.
							
							// TODO: This causes problems in many-many associations, not sure why yet
							if (loadedEntity !== repoEntity && EntityUtil.isCollectionInitialized(value))
								repoEntityRepository.resetManyAssociation(repoEntity[associationAttribute]);
							
							if (EntityUtil.isCollectionInitialized(value)) {
								for (var n:uint = 0; n < value.source.length; n++) {
									var associatedObject:Object = value.source[n];
									
									// If the repoEntity is a different instance to the loadedEntity we are replacing the collection (which was just
									// deleted) so use addItem), otherwise they are the same instances so we don't use add.
									if (loadedEntity !== repoEntity) {
										// We only add related entities to a many association if they have not already been added (as they can be in
										// a ManyToMany relationship) and the collection is initialized.
										if (loadedEntity !== repoEntity || checkForPropertyChanges)
											// Add the result of the recursion to repoEntity[associationAttribute].  We use a method in EntityRepository
											// so that the change listeners can be disabled during the update.
											repoEntityRepository.addEntityToManyAssociation(repoEntity, associationAttribute, doAddLoadedEntityToRepository(associatedObject, checkForPropertyChanges), checkForPropertyChanges);
									} else {
										// Otherwise they are the same instance so we just add it to the repository without adding it to repoEntity
										// (since repoEntity IS loadedEntity so its already there!)
										doAddLoadedEntityToRepository(associatedObject, checkForPropertyChanges);
									}									
								}
							}
							
						} else if (value is Object) {
							// The association is single valued.  Update its value recursively (use updateEntityProperty so we don't trigger property change events)
							repoEntityRepository.updateEntityProperty(repoEntity, associationAttribute, doAddLoadedEntityToRepository(value, checkForPropertyChanges), checkForPropertyChanges);
						} else {
							// Don't add a null attribute
						}
					}
				}
				
				// Return the entity we just added to the repository
				var returnEntity:Object = getRepository(ClassUtil.getClass(loadedEntity)).findOneBy(EntityUtil.getIdObject(repoEntity));
				if (configuration.enabledRollback) returnEntity.flextrine::saveState();
				return returnEntity;
			} else {
				// If we have already visited the entity then just return it directly
				return getRepository(ClassUtil.getClass(loadedEntity)).findOneBy(EntityUtil.getIdObject(loadedEntity));
			}
		}
		
		private function onFlextrineFlushComplete(e:FlextrineEvent):void {
			// Clear the unit of work
			unitOfWork.clear();
			
			var changeSet:ChangeSet = new ChangeSet(e.data);
			
			// Execute the change set against the repositories, and get back a changes object with arrays of what has been persisted, removed and updated
			var changes:Object = executeChangeSet(changeSet);
			
			// Apply changes to the token.  We need to remove all responders added by Flextrine (FlextrineAsyncResponders) which will only leave
			// ones added by the user.
			var resultEvent:ResultEvent = e.resultEvent;
			
			for (var flextrineResponderCount:uint = 0; flextrineResponderCount < resultEvent.token.responders.length; flextrineResponderCount++)
				if (!(resultEvent.token.responders[flextrineResponderCount] is FlextrineAsyncResponder))
					break;
			
			resultEvent.token.responders.splice(0, flextrineResponderCount);
			resultEvent.token.applyResult(new ResultEvent(ResultEvent.RESULT, resultEvent.bubbles, resultEvent.cancelable, changes, resultEvent.token, resultEvent.message));
		}
		
		/**
		 * Execute a changeset returned from the server against the entity repositories.
		 * 
		 * @param changeSet
		 * @return 
		 */
		private function executeChangeSet(changeSet:ChangeSet):Object {
			var changes:Object = { };
			
			changes.persists = handleEntityInsertions(changeSet.entityInsertions, changeSet.temporaryUidMap);
			changes.updates = handleEntityUpdates(changeSet.entityUpdates);
			changes.removes = handleEntityDeletions(changeSet.entityDeletions);
			
			return changes;
		}
		
		private function handleEntityInsertions(entityInsertions:Object, temporaryUidMap:Object):Array {
			var persists:Array = [ ];
			
			var serverInsertions:Array = [ ];
			
			for (var oid:String in entityInsertions) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityInsertions[oid])) as EntityRepository;
				
				var changedEntity:Object = repo.getPersistedEntity(temporaryUidMap[oid]);
				
				if (changedEntity) {
					// We found the temporary uid in the repository, so upate the existing entity and merge it into the repository
					log.info("Updating persisted entity " + changedEntity + " with uid " + temporaryUidMap[oid]);
					
					changedEntity = repo.mergeIdentifiers(changedEntity, entityInsertions[oid]);
					changedEntity = addLoadedEntityToRepository(changedEntity);
					
					repo.clearPersistedEntity(temporaryUidMap[oid]);
					
					// Get the real repository object and put it in changes
					persists.push(repo.findOneBy(EntityUtil.getIdObject(changedEntity)));
				} else {
					serverInsertions.push(entityInsertions[oid]);
				}
				
			}
			
			for each (var serverInsertion:Object in serverInsertions) {
				log.info("Got a new persisted entity from the server " + serverInsertion);
				changedEntity = addLoadedEntityToRepository(entityInsertions[oid]);
				persists.push(repo.findOneBy(EntityUtil.getIdObject(changedEntity)));
			}
			
			return persists;
		}
		
		private function handleEntityUpdates(entityUpdates:Object):Array {
			var updates:Array = [ ];
			
			var changedEntity:Object;
			
			for (var oid:String in entityUpdates) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityUpdates[oid])) as EntityRepository;
				
				switch (configuration.writeMode) {
					case WriteMode.PUSH:
						// In push mode the entity graph will already be updated in the repository, so just call updateEntity (this probably isn't even
						// necessary)
						changedEntity = repo.updateEntity(entityUpdates[oid]);
						break;
					case WriteMode.PULL:
						// In pull mode we are actually integrating the graph into the repository
						changedEntity = addLoadedEntityToRepository(entityUpdates[oid]);
						break;
				}
				
				// Get the real repository object and put it in changes
				updates.push(repo.findOneBy(EntityUtil.getIdObject(changedEntity)));
			}
			
			return updates;
		}
		
		private function handleEntityDeletions(entityDeletions:Object):Array {
			var removes:Array = [ ];
			
			// Remove the entities from the map and if in PULL mode actually remove the entities from the repository
			for (var oid:String in entityDeletions) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityDeletions[oid])) as EntityRepository;
				
				if (!unitOfWork.hasRemovedEntity(entityDeletions[oid])) {
					// Since there is no data push at the moment this is currently unused so throw an error for now
					throw new Error("This block should be unreachable until data push is implemented");
				} else {
					unitOfWork.removeEntityFromRemoveMap(entityDeletions[oid]);
					
					if (configuration.writeMode == WriteMode.PULL) {
						// If we are in WriteMode.PULL we need to match up the entity deletion with a real repo entity and remove it
						var repoEntity:Object = repo.findOneBy(EntityUtil.getIdObject(entityDeletions[oid]));
						repo.deleteEntity(repoEntity);
					}
				}
				
				// Since a removed object no longer exists in the repository we just put what we got back from the server into changes
				removes.push(entityDeletions[oid]);
			}
			
			// At the end of a flush we would expect the unit of work to no longer have any expected entity removals in its map
			if (unitOfWork.hasRemovedEntities())
				throw new Error("Unit of work still contains expected removals after a flush");
			
			return removes;
		}
		
	}

}