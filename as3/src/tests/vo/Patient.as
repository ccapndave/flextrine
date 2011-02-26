package tests.vo {
	import mx.collections.ArrayCollection;
	import mx.utils.UIDUtil;
	
	[RemoteClass(alias="tests.vo.Patient")]
	[Entity]
	public class Patient extends PatientEntityBase {
		
		[Transient]
		public var uuid:String;
		
		public function Patient():void {
			super();
			
			uuid = UIDUtil.createUID();
		}
		
		override public function toString():String {
			return "[Patient id=" + id + " uuid=" + uuid + "]";
		}
		
	}

}
