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
 * If not, see http://www.gnu.org/licenses/.
 * 
 */

package org.davekeen.flextrine.orm {
	import mx.rpc.AsyncToken;
	
	import org.davekeen.flextrine.orm.collections.EntityCollection;
	
	/**
	 * An <code>EntityRepository</code> is a collection of entities of a specific type and it can be thought of as a kind of local copy of the database.
	 * There is one <code>EntityRepository</code> for each entity in your application.
	 * 
	 * @example To get a reference to a particular <code>EntityRepository</code> you need to use <code>EntityManager.getRepository</code>
	 * 
	 * <pre>
	 * var userEntityRepository:IEntityRepository = em.getRepository(User);
	 * </pre>
	 * 
	 * @author Dave Keen
	 */
	public interface IEntityRepository {
		
		/**
		 * The collection of currently loaded and persisted entities.  This is fully bindable as per normal Flex binding and can be assigned directly as
		 * a dataprovider to Flex components.  The <code>entities</code> collection always exists, so its possible to bind a component to <code>entities</code>
		 * and then later load entities into a repository; once the entities have loaded the component will automatically update its view.
		 * 
		 * @example Binding to a List component
		 * 
		 * <pre>
		 * &lt;s:List dataProvider="{em.getRepository(User).entities}" labelField="name" /&gt;
		 * </pre>
		 */
		function get entities():EntityCollection;
		
		/**
		 * Get the state of an entity.  An entity which is not yet in a repository is NEW, an object which is in a repository is MANAGED, and object which is an
		 * identified entity but isn't in a repository is DETACHED and an object which is scheduled for removal is REMOVED.
		 * 
		 * @param	entity
		 * @return
		 */
		function getEntityState(entity:Object):String;
		
		/**
		 * Load the entity with the given identifier (primary key).  Behaviour for entities with composite keys is currently undefined.
		 * 
		 * @param	id The id of the entity to load
		 * @param	fetchMode Optionally override the <code>FetchMode</code> set in the <code>Configuration</code> for this request
		 * @return  An AsyncToken which you can add responders to in order to handle results or failures.
		 * @see FetchMode
		 */
		function load(id:Number, fetchMode:String = null):AsyncToken;
		
		/**
		 * Load a single entity that matches the criteria.  Criteria are given as vanilla objects of the form <code>attribute: value</code>
		 * 
		 * @example Load the <code>User</code> with <code>name="Dave Keen"</code>
		 * 
		 * <pre>
		 * em.getRepository(User).loadOneBy( { name: "Dave Keen" } );
		 * </pre>
		 * 
		 * @param	criteria A simple criteria given as a vanilla object
		 * @param	fetchMode Optionally override the <code>FetchMode</code> set in the <code>Configuration</code> for this request
		 * @return  An AsyncToken which you can add responders to in order to handle results or failures.
		 * @see FetchMode
		 */
		function loadOneBy(criteria:Object, fetchMode:String = null):AsyncToken;
		
		/** 
		 * Load multiple entities that matches the criteria.  Criteria are given as vanilla objects of the form <code>attribute: value</code>
		 * 
		 * @example Load all <code>User</code> entities with <code>status="active"</code>
		 * 
		 * <pre>
		 * em.getRepository(User).loadBy( { status: "active" } );
		 * </pre>
		 * 
		 * @param	criteria A simple criteria given as a vanilla object
		 * @param	fetchMode Optionally override the <code>FetchMode</code> set in the <code>Configuration</code> for this request
		 * @return  An AsyncToken which you can add responders to in order to handle results or failures.
		 * @see FetchMode
		 */
		function loadBy(criteria:Object, fetchMode:String = null):AsyncToken;
		
		/**
		 * Load all entities.
		 * 
		 * @example Load all <code>User</code> entities
		 * 
		 * <pre>
		 * em.getRepository(User).loadAll();
		 * </pre>
		 * 
		 * @param	fetchMode Optionally override the <code>FetchMode</code> set in the <code>Configuration</code> for this request
		 * @return An AsyncToken which you can add responders to in order to handle results or failures.
		 * @see FetchMode
		 */
		function loadAll(fetchMode:String = null):AsyncToken;
		
		function find(id:Number):Object;
		function findOneBy(criteria:Object):Object;
		function findAll():Array;
		function findBy(criteria:Object):Array;
		
	}
	
}