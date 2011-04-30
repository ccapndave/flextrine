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

package org.davekeen.flextrine.orm.walkers {
	import org.davekeen.flextrine.orm.OnDemandListener;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.EntityUtil;
	
	/**
	 * @private 
	 */
	public class DetachCopyWalker extends AbstractWalker {
		
		private var onDemandListener:OnDemandListener;
		
		public function DetachCopyWalker(onDemandListener:OnDemandListener) {
			this.onDemandListener = onDemandListener;
		}
		
		protected override function beforeCollectionWalk(collection:PersistentCollection, owner:Object, associationName:String, data:Object):void {
			collection.setOwner(owner);
			collection.setAssociationName(associationName);
			
			if (!EntityUtil.isCollectionInitialized(collection))
				collection.addEventListener(EntityEvent.INITIALIZE_COLLECTION, onDemandListener.onInitializeCollection, false, int.MAX_VALUE, true);
		}
		
		protected override function replaceEntity(entity:Object, data:Object):Object {
			if (!EntityUtil.isInitialized(entity))
				entity.addEventListener(EntityEvent.INITIALIZE_ENTITY, onDemandListener.onInitializeEntity, false, int.MAX_VALUE, true);
			
			return entity;
		}
	
	}

}