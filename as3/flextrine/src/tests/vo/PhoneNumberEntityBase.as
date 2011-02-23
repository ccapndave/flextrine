package tests.vo {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;
  	import tests.vo.Patient;
  
	[Bindable]
	public class PhoneNumberEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var savedState:Dictionary;
		
		[Id]
		public var id:String;
		
		public function get phoneNumber():String { checkIsInitialized("phoneNumber"); return _phoneNumber; }
		public function set phoneNumber(value:String):void { _phoneNumber = value; }
		private var _phoneNumber:String;
		
		[Association(side="owning", oppositeAttribute="phoneNumbers", oppositeCardinality="1")]
		public function get patient():Patient { checkIsInitialized("patient"); return _patient; }
		public function set patient(value:Patient):void { (value) ? value.flextrine::setValue('phoneNumbers', this) : ((_patient) ? _patient.flextrine::setValue('phoneNumbers', null) : null); _patient = value; }
		private var _patient:Patient;
		
		public function PhoneNumberEntityBase() {
		}
		
		override public function toString():String {
			return "[PhoneNumber id=" + id + "]";
		}
		
		private function checkIsInitialized(property:String):void {
			if (!isInitialized__ && isUnserialized__)
				dispatchEvent(new EntityEvent(EntityEvent.INITIALIZE_ENTITY, property));
		}
		
		flextrine function setValue(attributeName:String, value:*):void {
			if (isInitialized__) {
				if (this["_" + attributeName] is PersistentCollection)
					throw new Error("Internal error - Flextrine attempted to setValue on a PersistentCollection.");
					
				var propertyChangeEvent:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(this, attributeName, this[attributeName], value);
				
				this["_" + attributeName] = value;
				
				dispatchEvent(propertyChangeEvent);
			}
		}
		
		flextrine function addValue(attributeName:String, value:*):void {
			if (isInitialized__) {
				if (!(this["_" + attributeName] is PersistentCollection))
					throw new Error("Internal error - Flextrine attempted to addValue on a non-PersistentCollection.");
					
				this["_" + attributeName].flextrine::addItemNonRecursive(value);
			}
		}
		
		flextrine function removeValue(attributeName:String, value:*):void {
			if (isInitialized__) {
				if (!(this["_" + attributeName] is PersistentCollection))
					throw new Error("Internal error - Flextrine attempted to removeValue on a non-PersistentCollection.");
				
				this["_" + attributeName].flextrine::removeItemNonRecursive(value);
			}
		}
		
		flextrine function saveState():void {
			if (isInitialized__) {
				flextrine::savedState = new Dictionary(true);
				flextrine::savedState["id"] = id;
				flextrine::savedState["phoneNumber"] = phoneNumber;
				flextrine::savedState["patient"] = patient;
			}
		}
		
		flextrine function restoreState():void {
			if (isInitialized__) {
				id = flextrine::savedState["id"];
				phoneNumber = flextrine::savedState["phoneNumber"];
				patient = flextrine::savedState["patient"]; // this will trigger bi-directional??
			}
		}
		
	}

}
