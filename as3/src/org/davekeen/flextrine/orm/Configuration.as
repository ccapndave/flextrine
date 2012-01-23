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
	/**
	 * The configuration class sets major Flextrine parameters.  It must be provided to an instance of the <code>EntityManager</code> using the
	 * <code>setConfiguration</code> method..
	 * 
	 * @example The following code shows the minimum necessary configuration for Flextrine to function.
	 * 
	 * <pre>
	 *   var em:EntityManager = EntityManager.getInstance();
	 *   var configuration:Configuration = new Configuration();
	 *   configuration.gateway = "http://localhost/flextrineproject/gateway.php";
	 *   em.setConfiguration(configuration);
	 * </pre>
	 * @author Dave Keen
	 */
	public class Configuration {
		
		/**
		 * The full URL to the <code>gateway.php</code> file in the Flextrine project.  For example, if your project was accessible at
		 * <code>http://localhost/flextrineproject</code>, the gateway would be <code>http://localhost/flextrineproject/gateway.php</code>.
		 * <b>This configuration setting is required for Flextrine to function.</b>
		 */
		public var gateway:String;
		
		/**
		 * The service defaults to FlextrineService (which is what it will be in most configurations)
		 */
		public var service:String = "FlextrineService";
		
		/**
		 * The default fetch mode to use.  Most Flextrine methods provide a fetchMode parameter with which you can override this default setting on a call by
		 * call basis.
		 */
		public var fetchMode:String = FetchMode.EAGER;
		
		/**
		 * The write mode to use.  Either WriteMode.PUSH where you make changes directly in the repository, and then flush them, or WriteMode.PULL
		 * where changes need to be made on detached copies of the entities, then merged and flushed.
		 * 
		 * At present WriteMode.PULL is experimental and it is recommended to only use WriteMode.PUSH (the default).
		 */
		public var writeMode:String = WriteMode.PUSH;
		
		/**
		 * For future implementation
		 */ 
		public var transactionMode:String = TransactionMode.FLAT;
		
		/**
		 * Whether or not to automatically load uninitialized entities when any of their properties are accessed.  This works well with Flex binding, but is less
		 * use when using entities in AS3 code.
		 */
		public var loadEntitiesOnDemand:Boolean = true;
		
		/**
		 * Whether or not to automatically load uninitialized associated collections when they are accessed, throwing ItemPendingErrors.  This allows
		 * uninitialized collections to be bound directly to some Flex components (through AsyncListView in Flex 4).
		 */
		public var loadCollectionsOnDemand:Boolean = true;
		
		/**
		 * Determines how long entities are stored in repositories before they are garbage collection.  If this is set to -1 entities will never be garbage
		 * collected; this is useful if you are sure that you will never have too much information in your database and want to use the entities property
		 * of EntityRepository directly.  It is not advised to set this value to less than 5 seconds (5000).
		 */
		public var entityTimeToLive:int = 5000;
		
		/**
		 * Whether to bundle together multiple requests into single calls, or to make them one after the other.  Setting this to true can give a significant
		 * performance boost, especially with on demand loading.  However, this may cause problems if you use multiple remote service files.
		 */
		public var useConcurrentRequests:Boolean = true;
	}

}