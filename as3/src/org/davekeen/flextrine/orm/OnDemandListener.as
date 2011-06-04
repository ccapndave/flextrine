package org.davekeen.flextrine.orm {
	import flash.events.EventDispatcher;
	
	import mx.collections.errors.ItemPendingError;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncResponder;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.ClassUtil;
	
	public class OnDemandListener {
		
		private var em:EntityManager;
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		public function OnDemandListener(em:EntityManager) {
			this.em = em;
		}
		
		/**
		 * Load an entity on demand
		 * 
		 * @param e
		 */
		public function onInitializeEntity(e:EntityEvent):void {
			var entity:Object = e.currentTarget;
			
			if (!em.getConfiguration().loadEntitiesOnDemand)
				throw new FlextrineError("Attempt to get property '" + e.property + "' on unitialized entity '" + entity + "'.  Consider using EntityManager::require, FetchMode.EAGER or configuration.loadEntitiesOnDemand.", FlextrineError.ACCESSED_UNINITIALIZED_ENTITY);
			
			log.info("Loading on demand: entity {0}", entity);
			
			em.requireOne(entity).addResponder(new AsyncResponder(onInitializeResult, onInitializeFault, e.itemPendingError));
		}
		
		/**
		 * Load a persistent collection on demand
		 * 
		 * @param e
		 */
		public function onInitializeCollection(e:EntityEvent):void {
			var persistentCollection:PersistentCollection = e.currentTarget as PersistentCollection;
			
			if (!em.getConfiguration().loadCollectionsOnDemand)
				throw new FlextrineError("Attempt to access uninitialized collection '" + e.property + "' on entity '" + persistentCollection.getOwner() + "'.  Consider using EntityManager::require, eager loading or configuration.loadCollectionsOnDemand.", FlextrineError.ACCESSED_UNINITIALIZED_ENTITY);
			
			if (!e.itemPendingError)
				e.itemPendingError = new ItemPendingError("ItemPendingError - initializing collection " + persistentCollection.getOwner() + "." + e.property);
			
			log.info("Loading on demand: collection '{0}' on entity {1}", e.property, persistentCollection.getOwner());
			
			em.requireMany(persistentCollection.getOwner(), e.property).addResponder(new AsyncResponder(onInitializeResult, onInitializeFault, e.itemPendingError));
		}
		
		public function onInitializeResult(e:ResultEvent, itemPendingError:ItemPendingError):void {
			if (itemPendingError && itemPendingError.responders)
				for each (var responder:IResponder in itemPendingError.responders)
					responder.result(e);
		}
		
		public function onInitializeFault(e:FaultEvent, itemPendingError:ItemPendingError):void {
			if (itemPendingError && itemPendingError.responders)
				for each (var responder:IResponder in itemPendingError.responders)
					responder.fault(e);
		}
		
	}
	
}