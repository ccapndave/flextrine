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
		 * An attempt was made to directly change a property or collection of an entity when in <code>WriteMode.PULL</code>
		 */
		public static const ENTITY_CHANGE_IN_PULL_MODE:int = 5;
		
		/**
		 * An attempt was made to perform an operation (i.e. commit(), rollback()) without explicitly beginning a transaction
		 */ 
		public static const NO_ACTIVE_TRANSACTION:int = 6;
		
		function FlextrineError(message:String, errorID:int = 0) {
			super(message, errorID);
		}
		
	}

}