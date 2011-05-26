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
