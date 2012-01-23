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
	 * This class defines errors thrown from Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class FlextrineError extends Error {
		
		/**
		 * Not currently used.
		 */
		public static const ATTEMPTED_WRITE_TO_REPOSITORY_ENTITY:int = 1;
		
		/**
		 * An attempt was made to access an lazily loaded association that has not been initialised.  This means it is necessary to use
		 * <code>EntityManager.requireOne</code> or <code>EntityManager.requireMany</code> to load the association from the database.
		 */
		public static const ACCESSED_UNINITIALIZED_ENTITY:int = 2;
		
		/**
		 * An attempt was made to perform an operation on an unitialized collection.
		 */
		public static const ACCESSED_UNINITIALIZED_COLLECTION:int = 3;
		
		/**
		 * <code>EntityManager.requireOne</code> or <code>EntityManager.requireMany</code> was called will illegal parameters.
		 */
		public static const ILLEGAL_REQUIRE:int = 4;
		
		/**
		 * An attempt was made to directly change a property or collection of an entity when in <code>WriteMode.PULL</code> (not yet implemented)
		 */
		public static const ENTITY_CHANGE_IN_PULL_MODE:int = 5;
		
		/**
		 * An attempt was made to perform an operation (i.e. commit(), rollback()) without explicitly beginning a transaction (not yet implemented)
		 */ 
		public static const NO_ACTIVE_TRANSACTION:int = 6;
		
		/**
		 * An attempt was made to change an identifier property of an entity
		 */ 
		public static const ILLEGAL_ID_PROPERTY_CHANGE:int = 7;
		
		function FlextrineError(message:String, errorID:int = 0) {
			super(message, errorID);
		}
		
	}

}