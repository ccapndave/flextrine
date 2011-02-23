package tests.vo {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;
  	import tests.vo.Appointment;
   	import tests.vo.PhoneNumber;
   	import tests.vo.Doctor;
  
	[Bindable]
	public class PatientEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var savedState:Dictionary;
		
		[Id]
		public var id:String;
		
		public function get name():String { checkIsInitialized("name"); return _name; }
		public function set name(value:String):void { _name = value; }
		private var _name:String;
		
		public function get address():String { checkIsInitialized("address"); return _address; }
		public function set address(value:String):void { _address = value; }
		private var _address:String;
		
		public function get postcode():String { checkIsInitialized("postcode"); return _postcode; }
		public function set postcode(value:String):void { _postcode = value; }
		private var _postcode:String;
		
		[Association(side="inverse", oppositeAttribute="patient", oppositeCardinality="1")]
		public function get appointments():PersistentCollection { checkIsInitialized("appointments"); return _appointments; }
		public function set appointments(value:PersistentCollection):void { _appointments = value; }
		private var _appointments:PersistentCollection;
		
		[Association(side="inverse", oppositeAttribute="patient", oppositeCardinality="1")]
		public function get phoneNumbers():PhoneNumber { checkIsInitialized("phoneNumbers"); return _phoneNumbers; }
		public function set phoneNumbers(value:PhoneNumber):void { (value) ? value.flextrine::setValue('patient', this) : ((_phoneNumbers) ? _phoneNumbers.flextrine::setValue('patient', null) : null); _phoneNumbers = value; }
		private var _phoneNumbers:PhoneNumber;
		
		[Association(side="owning", oppositeAttribute="patients", oppositeCardinality="*")]
		public function get doctor():Doctor { checkIsInitialized("doctor"); return _doctor; }
		public function set doctor(value:Doctor):void { (value) ? value.flextrine::addValue('patients', this) : ((_doctor) ? _doctor.flextrine::removeValue('patients', this) : null); _doctor = value; }
		private var _doctor:Doctor;
		
		public function PatientEntityBase() {
			if (!_appointments) _appointments = new PersistentCollection(null, true, "appointments", this);
		}
		
		override public function toString():String {
			return "[Patient id=" + id + "]";
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
				flextrine::savedState["name"] = name;
				flextrine::savedState["address"] = address;
				flextrine::savedState["postcode"] = postcode;
				appointments.flextrine::saveState();
				flextrine::savedState["phoneNumbers"] = phoneNumbers;
				flextrine::savedState["doctor"] = doctor;
			}
		}
		
		flextrine function restoreState():void {
			if (isInitialized__) {
				id = flextrine::savedState["id"];
				name = flextrine::savedState["name"];
				address = flextrine::savedState["address"];
				postcode = flextrine::savedState["postcode"];
				appointments.flextrine::restoreState();
				phoneNumbers = flextrine::savedState["phoneNumbers"]; // this will trigger bi-directional??
				doctor = flextrine::savedState["doctor"]; // this will trigger bi-directional??
			}
		}
		
	}

}
