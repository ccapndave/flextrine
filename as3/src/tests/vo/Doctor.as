package tests.vo {
	import mx.utils.UIDUtil;
	
	[RemoteClass(alias="tests.vo.Doctor")]
	[Entity]
	public class Doctor extends DoctorEntityBase {
		
		[Transient]
		public var uuid:String;
		
		public function Doctor():void {
			super();
			
			uuid = UIDUtil.createUID();
		}
		
		override public function toString():String {
			return "[Doctor id=" + id + " uuid=" + uuid + "]";
		}
		
	}

}
