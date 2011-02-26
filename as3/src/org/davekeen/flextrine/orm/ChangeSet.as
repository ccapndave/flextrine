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
	 * @private 
	 * @author Dave Keen
	 */
	public class ChangeSet {
		
		public var entityInsertions:Object;
		public var entityDeletions:Object;
		public var entityUpdates:Object;
		public var collectionUpdates:Object;
		public var collectionDeletions:Object;
		public var temporaryUidMap:Object;
		//public var orphanRemovals:Object;
		
		public function ChangeSet(fromServerArray:Object) {
			entityInsertions = fromServerArray.entityInsertions;
			entityDeletions = fromServerArray.entityDeletions;
			entityUpdates = fromServerArray.entityUpdates;
			collectionUpdates = fromServerArray.collectionUpdates;
			collectionDeletions = fromServerArray.collectionDeletions;
			temporaryUidMap = fromServerArray.temporaryUidMap;
			//orphanRemovals = fromServerArray._orphanRemovals;
		}
		
	}

}