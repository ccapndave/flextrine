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