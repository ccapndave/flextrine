package tests.vo {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;
  	import tests.vo.Student;
   	import tests.vo.Course;
  
	[Bindable]
	public class MarkEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var savedState:Dictionary;
		
		[Id]
		public var id:String;
		
		public function get mark():Number { checkIsInitialized("mark"); return _mark; }
		public function set mark(value:Number):void { _mark = value; }
		private var _mark:Number = 0;
		
		[Association(side="owning", oppositeAttribute="marks", oppositeCardinality="*")]
		public function get student():Student { checkIsInitialized("student"); return _student; }
		public function set student(value:Student):void { (value) ? value.flextrine::addValue('marks', this) : ((_student) ? _student.flextrine::removeValue('marks', this) : null); _student = value; }
		private var _student:Student;
		
		[Association(side="owning")]
		public function get course():Course { checkIsInitialized("course"); return _course; }
		public function set course(value:Course):void { _course = value; }
		private var _course:Course;
		
		public function MarkEntityBase() {
		}
		
		override public function toString():String {
			return "[Mark id=" + id + "]";
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
				flextrine::savedState["mark"] = mark;
				flextrine::savedState["student"] = student;
				flextrine::savedState["course"] = course;
			}
		}
		
		flextrine function restoreState():void {
			if (isInitialized__) {
				id = flextrine::savedState["id"];
				mark = flextrine::savedState["mark"];
				student = flextrine::savedState["student"]; // this will trigger bi-directional??
				course = flextrine::savedState["course"]; // this will trigger bi-directional??
			}
		}
		
	}

}
