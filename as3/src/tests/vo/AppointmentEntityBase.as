package tests.vo {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.davekeen.flextrine.flextrine;
	import tests.vo.Doctor;
	import tests.vo.Patient;

	[Bindable]
	public class AppointmentEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var itemPendingError:ItemPendingError;
		
		[Id]
		public function get id():String { return _id; }
		public function set id(value:String):void { _id = value; }
		private var _id:String;
		
		public function get date():Date { checkIsInitialized("date"); return (_date && _date.getTime() > 0) ? _date : null; }
		public function set date(value:*):void { _date = (value is Date) ? value : new Date(value); }
		private var _date:Date;
		
		[Association(side="owning", oppositeAttribute="appointments", oppositeCardinality="*")]
		public function get doctor():Doctor { checkIsInitialized("doctor"); return _doctor; }
		public function set doctor(value:Doctor):void { (value) ? value.flextrine::addValue('appointments', this) : ((_doctor) ? _doctor.flextrine::removeValue('appointments', this) : null); _doctor = value; }
		private var _doctor:Doctor;
		
		[Association(side="owning", oppositeAttribute="appointments", oppositeCardinality="*")]
		public function get patient():Patient { checkIsInitialized("patient"); return _patient; }
		public function set patient(value:Patient):void { (value) ? value.flextrine::addValue('appointments', this) : ((_patient) ? _patient.flextrine::removeValue('appointments', this) : null); _patient = value; }
		private var _patient:Patient;
		
		public function AppointmentEntityBase() {
		}
		
		override public function toString():String {
			return "[Appointment id=" + id + "]";
		}
		
		private function checkIsInitialized(property:String):void {
			if (!isInitialized__ && isUnserialized__ && !EntityUtil.flextrine::isCopying) {
				if (!flextrine::itemPendingError) {
					flextrine::itemPendingError = new ItemPendingError("ItemPendingError - initializing entity " + this);
					dispatchEvent(new EntityEvent(EntityEvent.INITIALIZE_ENTITY, property, flextrine::itemPendingError));
				}
			}
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
		
		flextrine function saveState():Dictionary {
			if (isInitialized__) {
				var memento:Dictionary = new Dictionary(true);
				memento["id"] = id;
				memento["date"] = date;
				memento["doctor"] = doctor;
				memento["patient"] = patient;
				return memento;
			}
			
			return null;
		}
		
		flextrine function restoreState(memento:Dictionary):void {
			if (isInitialized__) {
				id = memento["id"];
				date = memento["date"];
				doctor = memento["doctor"];
				patient = memento["patient"];
			}
		}
		
	}

}
