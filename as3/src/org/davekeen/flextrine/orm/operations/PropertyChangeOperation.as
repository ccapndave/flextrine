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

package org.davekeen.flextrine.orm.operations {
	import mx.events.PropertyChangeEvent;
	
	import org.davekeen.flextrine.orm.RemoteEntityFactory;
	import org.davekeen.flextrine.util.EntityUtil;
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.operations.PropertyChangeOperation")]
	public class PropertyChangeOperation extends RemoteOperation {
		
		public var entity:Object;
		
		public var property:String;
		
		public var value:Object;
		
		public function PropertyChangeOperation() {
			
		}
		
		override public function transformEntities(remoteEntityFactory:RemoteEntityFactory):void {
			entity = remoteEntityFactory.getRemoteEntity(entity);
			
			if (EntityUtil.isEntity(value))
				value = remoteEntityFactory.getRemoteEntity(value);
		}
		
		public static function createFromPropertyChangeEvent(e:PropertyChangeEvent):PropertyChangeOperation {
			var changeOperation:PropertyChangeOperation = new PropertyChangeOperation();
			
			changeOperation.entity = e.currentTarget;
			changeOperation.property = e.property.toString();
			changeOperation.value = e.newValue;
			
			return changeOperation;
		}
		
	}
}
