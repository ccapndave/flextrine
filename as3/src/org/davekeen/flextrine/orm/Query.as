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
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.Query")]
	public class Query {
		
		/**
		 * Hydrates an object graph. This is the default behavior.
		 */
		public static const HYDRATE_OBJECT:uint = 1;
		
		/**
		 * Hydrates an array graph.
		 */
		public static const HYDRATE_ARRAY:uint = 2;
		
		/**
		 * Hydrates a flat, rectangular result set with scalar values.
		 */
		public static const HYDRATE_SCALAR:uint = 3;
		
		/**
		 * Hydrates a single scalar value.
		 */
		public static const HYDRATE_SINGLE_SCALAR:uint = 4;
		
		/**
		 * The DQL query to execute. 
		 */
		public var dql:String;
		
		/**
		 * Named parameters referenced in the DQL query 
		 */		
		public var params:Object;
		
		/**
		 * The index of the first result to return.  Used when paging query results. 
		 */
		public var firstResult:uint;
		
		/**
		 * The maximum number of results to returns.  Used when paging query results. 
		 */
		public var maxResults:uint;
		
		/**
		 * The hydration mode to use for the query result.  By default this is HYDRATE_OBJECT. 
		 */
		public var hydrationMode:uint = HYDRATE_OBJECT;
		
		public function Query(dql:String, params:Object = null, firstResult:uint = 0, maxResults:uint = 0) {
			this.dql = dql;
			this.params = params;
			this.firstResult = firstResult;
			this.maxResults = maxResults;
		}
		
		public function setParameter(name:String, value:Object):void {
			params[name] = value;
		}

		public function setHydrationMode(hydrationMode:uint):void {
			this.hydrationMode = hydrationMode;
		}
		
	}
	
}