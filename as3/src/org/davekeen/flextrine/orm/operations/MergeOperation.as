package org.davekeen.flextrine.orm.operations {
	import org.davekeen.flextrine.orm.RemoteEntityFactory;
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.operations.MergeOperation")]
	public class MergeOperation extends RemoteOperation {
		
		public var entity:Object;
		
		public function MergeOperation(entity:Object) {
			this.entity = entity;
		}
		
		override public function transformEntities(remoteEntityFactory:RemoteEntityFactory):void {
			entity = remoteEntityFactory.getRemoteEntity(entity);
		}
		
	}
}
