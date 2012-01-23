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