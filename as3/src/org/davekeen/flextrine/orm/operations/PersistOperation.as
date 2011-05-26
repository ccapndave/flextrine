package org.davekeen.flextrine.orm.operations {
	import org.davekeen.flextrine.orm.RemoteEntityFactory;
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.operations.PersistOperation")]
	public class PersistOperation extends RemoteOperation {
		
		public var entity:Object;
		public var temporaryUid:String;
		
		public function PersistOperation(entity:Object, temporaryUid:String) {
			this.entity = entity;  
			this.temporaryUid = temporaryUid;  
		}
		
		override public function transformEntities(remoteEntityFactory:RemoteEntityFactory):void {
			entity = remoteEntityFactory.getRemoteEntity(entity);
		}
		
	}
	
}
