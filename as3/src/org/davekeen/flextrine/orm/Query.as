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