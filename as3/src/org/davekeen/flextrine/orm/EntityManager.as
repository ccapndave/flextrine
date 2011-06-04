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
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.flextrine;
	import org.davekeen.flextrine.orm.collections.PagedCollection;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.delegates.FlextrineDelegate;
	import org.davekeen.flextrine.orm.events.FlextrineEvent;
	import org.davekeen.flextrine.orm.events.FlextrineFaultEvent;
	import org.davekeen.flextrine.orm.events.FlextrineResultEvent;
	import org.davekeen.flextrine.orm.metadata.MetaTags;
	import org.davekeen.flextrine.orm.walkers.DetachCopyWalker;
	import org.davekeen.flextrine.orm.walkers.LocalMergeWalker;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.davekeen.flextrine.util.QueryUtil;
	
	use namespace mx_internal;
	use namespace flextrine;
	
	/**
	 * The EntityManager is the central access point to the ORM functionality provided by Flextrine.
	 *
	 * @author Dave Keen
	 */
	public class EntityManager extends EventDispatcher {
		
		/**
		 * Singleton management for EntityManager
		 */
		private static var _instance:EntityManager;
		private static var singletonInstantiation:Boolean;
		
		/**
		 * This contains the EntityRepositories
		 */
		private var repositories:Dictionary;
		
		private var unitOfWork:UnitOfWork;
		
		/**
		 * The server delegate.
		 */
		private var flextrineDelegate:FlextrineDelegate;
		
		/**
		 * Flextrine allows transactions; this counter records the transaction level the EntityManager is currently on.  If the user does not
		 * explicitly open a new transaction this will always be 0.
		 */
		private var transactionLevel:uint = 0;
		
		/**
		 * The configuration of this EntityManager
		 */
		private var configuration:Configuration;
		
		/**
		 * This object is used to track cyclical references and ensure we don't get into an inifinite loop when adding heirarchical objects to the repositories
		 */
		private var visited:Object;
		
		/**
		 * This is the listener for on-demand loading 
		 */
		private var onDemandListener:OnDemandListener;
		
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
			logTarget.filters = ["org.davekeen.*"];
			logTarget.level = LogEventLevel.ALL;
			logTarget.includeDate = false;
			logTarget.includeTime = false;
			logTarget.includeCategory = true;
			logTarget.includeLevel = true;
			Log.addTarget(logTarget);
			
			// Create instances of classes used by the EntityManager
			unitOfWork = new UnitOfWork(this);
			repositories = new Dictionary(false);
			onDemandListener = new OnDemandListener(this);
			
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
				flextrineDelegate = new FlextrineDelegate(configuration.gateway, configuration.service, configuration.useConcurrentRequests);
				flextrineDelegate.addEventListener(FlextrineResultEvent.LOAD_COMPLETE, onFlextrineLoadComplete, false, int.MAX_VALUE, false);
				flextrineDelegate.addEventListener(FlextrineResultEvent.FLUSH_COMPLETE, onFlextrineFlushComplete, false, int.MAX_VALUE, false);
				flextrineDelegate.addEventListener(FlextrineFaultEvent.LOAD_FAULT, onFlextrineLoadFault, false, int.MAX_VALUE, false);
				flextrineDelegate.addEventListener(FlextrineFaultEvent.FLUSH_FAULT, onFlextrineFlushFault, false, int.MAX_VALUE, false);
				
				// Pass on events (generally these are useful for loading/saving/error status messages in applications)
				flextrineDelegate.addEventListener(FlextrineEvent.LOADING, function(e:FlextrineEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
				flextrineDelegate.addEventListener(FlextrineEvent.FLUSHING, function(e:FlextrineEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
				flextrineDelegate.addEventListener(FlextrineResultEvent.LOAD_COMPLETE, function(e:FlextrineResultEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
				flextrineDelegate.addEventListener(FlextrineResultEvent.FLUSH_COMPLETE, function(e:FlextrineResultEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
				flextrineDelegate.addEventListener(FlextrineFaultEvent.LOAD_FAULT, function(e:FlextrineFaultEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
				flextrineDelegate.addEventListener(FlextrineFaultEvent.FLUSH_FAULT, function(e:FlextrineFaultEvent):void { dispatchEvent(e.clone()); }, false, 0, false);
			}
			
			return flextrineDelegate;
		}
		
		internal function getOnDemandListener():OnDemandListener {
			return onDemandListener;
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
			if (!entity)
				throw new TypeError("Attempted to persist null");
			
			// Add the entity to the appropriate repository, and receive a temporary id back
			var temporaryUid:String = (getRepository(ClassUtil.getClass(entity)) as EntityRepository).persistEntity(entity, configuration.writeMode != WriteMode.PULL);
			
			// If the entity was already persisted we get null back and do nothing
			if (temporaryUid) {
				log.info("Persisting {0}", entity);
				
				// Add the persist operation to the unit of work
				unitOfWork.persist(entity, temporaryUid);
				
				// Return the entity to aid in the chaining methods together
				return entity;
			} else {
				return null;
			}
		}
		
		/**
		 * 
		 * @param entity
		 */
		public function detach(entity:Object):void {
			if (!entity)
				throw new TypeError("Attempted to detach null");
			
			log.info("Detaching {0}", entity);
			
			(getRepository(ClassUtil.getClass(entity)) as EntityRepository).detachEntity(entity);
		}
		
		/**
		 * Return an unmanaged copy of the given entity.  This entity is not the same instance as that in the repository and
		 * changes to its properties will not trigger updates on the database.  This has no effect on the entity given as a parameter -
		 * it remains in its repository as a fully managed entity.  Detached copies still support on-demand loading and bidirectional
		 * association management.
		 *
		 * <p>Typically <code>detachCopy</code> would be used in situations where you want to make changes to an entity that might be
		 * discarded; for example, an edit window with a <b>Save</b> and <b>Cancel</b> button.  If the user hits <b>cancel</b> the unmanaged entity can just be
		 *  thrown away, or otherwise <code>EntityManager.merge</code> can be used to merge changes back into the repository.</p>
		 *
		 * @example To detach a <code>user</code> entity:
		 *
		 * <pre>
		 * var detachedUserCopy:User = em.detachCopy(user) as User;
		 * </pre>
		 *
		 * @param	entity The entity to detach.
		 * @return
		 */
		public function detachCopy(entity:Object):Object {
			if (!entity)
				throw new TypeError("Attempted to detach null");
			// Make a fresh copy of the entity
			var entityCopy:Object = EntityUtil.copyEntity(entity);
			
			// Use the DetachCopyWalker to walk through the entity adding on-demand loading listeners and adding private attributes back in
			return new DetachCopyWalker(onDemandListener).walk(entityCopy);
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
			if (!entity)
				throw new TypeError("Attempted to merge null");
			
			log.info("Merging {0}", entity);
			
			switch (getConfiguration().writeMode) {
				case WriteMode.PUSH:
					return addLoadedEntityToRepository(entity, true);
				case WriteMode.PULL:
					throw new Error("Not implemented");
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
			if (!entity)
				throw new TypeError("Attempted to remove null");
			
			if ((getRepository(ClassUtil.getClass(entity)) as EntityRepository).deleteEntity(entity, configuration.writeMode != WriteMode.PULL)) {
				log.info("Removing {0}", entity);
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
			log.info("Selecting {0}", query.dql);
			
			return getDelegate().select(query, 0, 0, (fetchMode) ? fetchMode : getConfiguration().fetchMode);
		}
		
		// TODO: It should be possible to use a remote method for this instead of DQL
		public function selectPaged(query:Query, pageSize:uint, fetchMode:String = null):PagedCollection {
			log.info("Selecting (paged) {0}", query.dql);
			
			var pagedCollection:PagedCollection = new PagedCollection();
			pagedCollection.pageSize = pageSize;
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
			log.info("Selecting (one) {0}", query.dql);
			
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
			log.info("Loading {0} id={1}", entityClass.toString(), id);
			
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
			log.info("Loading one by {0}", entityClass.toString() + ObjectUtil.toString(criteria));
			
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
			log.info("Loading by {0}", entityClass.toString() + ObjectUtil.toString(criteria));
			
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
			log.info("Loading all {0}", entityClass.toString());
			
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
		public function callRemoteMethod(methodName:String, ... args):AsyncToken {
			log.info("Calling remote method {0} {1}", methodName, ObjectUtil.toString(args));
			
			return getDelegate().callRemoteMethod(methodName, args);
		}
		
		/**
		 * This is identical to callRemoteMethod, except that this expects a response from the server that is either an entity or an array of entities.
		 *
		 * On the server it is essential to prepare the return value for Flextrine using the <pre>flextrinize</pre> method:
		 *
		 * <pre>
		 * public function myRemoteEntityMethod($id) {
		 *   $entity = $this->em->getRepository("vo\User")->load($id);
		 *   return $this->flextrinize($entity);
		 * }
		 * </pre>
		 *
		 * @param methodName
		 * @param args
		 * @return
		 *
		 */
		public function callRemoteEntityMethod(methodName:String, ... args):AsyncToken {
			log.info("Calling remote entity method {0} {1}", methodName, ObjectUtil.toString(args));
			
			return getDelegate().callRemoteEntityMethod(methodName, args);
		}
		
		public function callRemoteFlushMethod(methodName:String, ... args):AsyncToken {
			log.info("Calling remote flush method {0} {1}", methodName, ObjectUtil.toString(args));
			
			return getDelegate().callRemoteFlushMethod(methodName, args);
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
			
			log.info("Requiring one {0}", entity);
			
			if (EntityUtil.isInitialized(entity)) {
				if (onResult != null)
					onResult();
				// TODO: This should return an AsyncToken that initializes instantly
				return null;
			} else {
				var entityIsDetached:Boolean = (getRepository(ClassUtil.getClass(entity)).getEntityState(entity) == EntityRepository.STATE_DETACHED);
				
				var asyncToken:AsyncToken = getDelegate().loadOneBy(ClassUtil.getClass(entity), EntityUtil.getIdObject(entity), (fetchMode) ? fetchMode : getConfiguration().fetchMode, (entityIsDetached) ? entity : null);
				if (onResult != null || onFault != null)
					asyncToken.addResponder(new AsyncResponder(onResult, onFault));
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
			log.info("Requiring many {0}::{1}", parentEntity, manyAttributeNames);
			
			return doRequireMany(parentEntity, (manyAttributeNames is Array) ? manyAttributeNames : [manyAttributeNames], onResult, onFault, fetchMode);
		}
		
		private function doRequireMany(parentEntity:Object, manyAttributeNames:Array, onResult:Function = null, onFault:Function = null, fetchMode:String = null):AsyncToken {
			var associationsToLoad:Array = [];
			
			for each (var manyAttributeName:String in manyAttributeNames) {
				if (!(parentEntity[manyAttributeName] is PersistentCollection))
					throw new FlextrineError("requireMany can only be called on a PersistentCollection (" + manyAttributeName + ")", FlextrineError.ILLEGAL_REQUIRE);
				
				if (!EntityUtil.isCollectionInitialized(parentEntity[manyAttributeName]))
					associationsToLoad.push(manyAttributeName);
			}
			
			if (associationsToLoad.length == 0) {
				if (onResult != null)
					onResult();
				// TODO: This should return an AsyncToken that initializes instantly
				return null;
			} else {
				// Build up the fetch query to refetch the parentEntity but fetch joined to the association we are requiring
				var dql:String = "SELECT p, " + associationsToLoad.join(", ") + " FROM " + QueryUtil.getDQLClass(parentEntity) + " p ";
				for each (var associationName:String in associationsToLoad)
				dql += "LEFT JOIN p." + associationName + " " + associationName + " ";
				
				dql += "WHERE p.id=:id";
				
				var query:Query = new Query(dql, { id: parentEntity.id });
				
				var entityIsDetached:Boolean = (getRepository(ClassUtil.getClass(parentEntity)).getEntityState(parentEntity) == EntityRepository.STATE_DETACHED);
				
				var asyncToken:AsyncToken = getDelegate().selectOne(query, (fetchMode) ? fetchMode : getConfiguration().fetchMode, (entityIsDetached) ? parentEntity : null);
				if (onResult != null || onFault != null)
					asyncToken.addResponder(new AsyncResponder(onResult, onFault));
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
			log.info("Clearing the EntityManager");
			
			for each (var repository:EntityRepository in repositories)
				repository.clear();
			
			unitOfWork.clear();
		}
		
		public function beginTransaction():void {
			// Start a new transaction
			//throw new Error("Not yet implemented");
		}
		
		/**
		 * Rollback any entities to the state they were in when last loaded from the database.  This will discard any changes to properties or associations
		 * since the last load or flush.  Return true if there was anything to rollback (this is mainly for use in unit tests).
		 */
		public function rollback():Boolean {
			//if (transactionLevel == 0)
			//	throw new FlextrineError("Unable to rollback without explicitly beginning a new transaction with em.beginTransaction()", FlextrineError.NO_ACTIVE_TRANSACTION);
			
			log.info("Rolling back transaction {0}", transactionLevel);
			
			var rolledBack:Boolean;
			var entity:Object;
			
			// Add any removed entities
			for (entity in unitOfWork.removedEntities) {
				rolledBack = true;
				(getRepository(ClassUtil.getClass(entity)) as EntityRepository).addEntity(entity);
			}
			
			// Restore any dirty entities using the memento stored in the dictionary
			for (entity in unitOfWork.dirtyEntities) {
				rolledBack = true;
				entity.flextrine::restoreState(unitOfWork.dirtyEntities[entity]);
			}
			
			// Remove any persisted entities
			for (entity in unitOfWork.persistedEntities) {
				rolledBack = true;
				(getRepository(ClassUtil.getClass(entity)) as EntityRepository).deleteEntity(entity);
			}
			
			unitOfWork.clear();
			
			return rolledBack;
		}
		
		public function commit():Boolean {
			if (transactionLevel == 0)
				throw new FlextrineError("Unable to commit without explicitly beginning a new transaction with em.beginTransaction()", FlextrineError.NO_ACTIVE_TRANSACTION);
			
			// Commit a transaction
			throw new Error("Not yet implemented");
		}
		
		private function onFlextrineLoadComplete(e:FlextrineResultEvent):void {
			// If we got nothing back then no changes are required on the server so we don't need to do anything
			if (!e.data)
				return;
			
			// Normal queries return an entity or an array of entities, but pages queries need to return the total count too so they return an object
			// with 'results' and 'count'.  If e.data has a results property then make that the results, otherwise use e.data itself.
			var results:* = e.data.hasOwnProperty("results") ? e.data.results : e.data;
			
			// Convert the result to an array (even if it is a single entity returned from load())
			var entities:Array = (results is Array) ? results as Array : [results];
			
			// Add the resultset to the repository
			var result:Object = addLoadedEntityToRepository(results, false, e.detachedEntity);
			
			// Re-apply the result to the token.
			e.resultEvent.setResult(e.data.hasOwnProperty("results") ? {results: result, count: e.data.count} : result);
		}
		
		/**
		 * This method is called on entities returned from the server.  Effectively it takes the DETACHED entities coming in and makes them MANAGED by
		 * matching them up 
		 *
		 * @param	loadedEntity  The entity to make MANAGED
		 * @param	isMerge  If true then add the entity to the unit of work's remote merge list.  This is used when calling em.merge() on a local detached entity
		 * @param	entityIsDetached If true then we don't want to merge the root entity into the repository as it was originally detached
		 */
		private function addLoadedEntityToRepository(loadedEntity:Object, isMerge:Boolean = false, detachedEntity:Object = null):Object {
			// Our brand new walker
			return new LocalMergeWalker(this, isMerge, detachedEntity).walk(loadedEntity);
		}
		
		private function onFlextrineFlushComplete(e:FlextrineResultEvent):void {
			var changeSet:ChangeSet = new ChangeSet(e.data);
			
			// Execute the change set against the repositories, and get back a changes object with arrays of what has been persisted, removed and updated
			var changes:Object = executeChangeSet(changeSet);
			
			// Apply changes to the result event
			e.resultEvent.setResult(changes);
			
			// Clear the unit of work
			unitOfWork.clear();
		}
		
		private function onFlextrineLoadFault(e:FlextrineFaultEvent):void {
			log.error("Load fault: {0}\n{1}", e.faultEvent.fault.faultString, e.faultEvent.fault.faultDetail);
		}
		
		private function onFlextrineFlushFault(e:FlextrineFaultEvent):void {
			log.error("Flush fault: {0}\n{1}", e.faultEvent.fault.faultString, e.faultEvent.fault.faultDetail);
		}
		
		/**
		 * Execute a changeset returned from the server against the entity repositories.
		 *
		 * @param changeSet
		 * @return
		 */
		private function executeChangeSet(changeSet:ChangeSet):Object {
			var changes:Object = {};
			
			changes.persists = handleEntityInsertions(changeSet.entityInsertions, changeSet.temporaryUidMap);
			changes.updates = handleEntityUpdates(changeSet.entityUpdates);
			changes.removes = handleEntityDeletions(changeSet.entityDeletions);
			
			return changes;
		}
		
		private function handleEntityInsertions(entityInsertions:Object, temporaryUidMap:Object):Array {
			var persists:Array = [];
			
			var serverInsertions:Array = [];
			
			for (var oid:String in entityInsertions) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityInsertions[oid])) as EntityRepository;
				
				var changedEntity:Object = repo.getPersistedEntity(temporaryUidMap[oid]);
				
				if (changedEntity) {
					// We found the temporary uid in the repository, so upate the existing entity and merge it into the repository
					log.info("Updating persisted entity {0} with uid {1} to {2}", changedEntity, temporaryUidMap[oid], entityInsertions[oid]);
					
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
				log.info("Got a new persisted entity from the server {0}", serverInsertion);
				changedEntity = addLoadedEntityToRepository(serverInsertion);
				
				repo = getRepository(ClassUtil.getClass(changedEntity)) as EntityRepository;
				persists.push(repo.findOneBy(EntityUtil.getIdObject(changedEntity)));
			}
			
			return persists;
		}
		
		private function handleEntityUpdates(entityUpdates:Object):Array {
			var updates:Array = [];
			
			var changedEntity:Object;
			
			for (var oid:String in entityUpdates) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityUpdates[oid])) as EntityRepository;
				
				// Since we can run server-side flushes even in PUSH mode we always need to integrate into the repository
				switch (configuration.writeMode) {
					case WriteMode.PUSH:
					case WriteMode.PULL:
						// In both push and pull mode we need to integrate the graph into the repository
						changedEntity = addLoadedEntityToRepository(entityUpdates[oid]);
						break;
				}
				
				// Get the real repository object and put it in changes
				if (changedEntity)
					updates.push(repo.findOneBy(EntityUtil.getIdObject(changedEntity)));
			}
			
			return updates;
		}
		
		private function handleEntityDeletions(entityDeletions:Object):Array {
			var removes:Array = [];
			
			// Remove the entities from the map and if in PULL mode actually remove the entities from the repository
			for (var oid:String in entityDeletions) {
				var repo:EntityRepository = getRepository(ClassUtil.getClass(entityDeletions[oid])) as EntityRepository;
				
				var repoEntity:Object = repo.findOneBy(EntityUtil.getIdObject(entityDeletions[oid]));
				if (repoEntity) {
					log.info("Entity removed on server and also in local repository {0}", repoEntity);
					repo.deleteEntity(repoEntity);
				} else {
					log.info("Entity removed on server {0}", entityDeletions[oid]);
				}
				
				// Since a removed object no longer exists in the repository we just put what we got back from the server into changes
				removes.push(entityDeletions[oid]);
			}
			
			return removes;
		}
	
	}

}