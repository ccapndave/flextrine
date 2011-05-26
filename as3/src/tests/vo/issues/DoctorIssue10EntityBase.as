package tests.vo.issues {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.davekeen.flextrine.flextrine;

	[Bindable]
	public class DoctorIssue10EntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var itemPendingError:ItemPendingError;
		
		[Id]
		public function get identifier():String { return _identifier; }
		public function set identifier(value:String):void { _identifier = value; }
		private var _identifier:String;
		
		public function get name():String { checkIsInitialized("name"); return _name; }
		public function set name(value:String):void { _name = value; }
		private var _name:String;
		
		public function DoctorIssue10EntityBase() {
		}
		
		override public function toString():String {
			return "[DoctorIssue10 identifier=" + identifier + "]";
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
				memento["identifier"] = identifier;
				memento["name"] = name;
				return memento;
			}
			
			return null;
		}
		
		flextrine function restoreState(memento:Dictionary):void {
			if (isInitialized__) {
				identifier = memento["identifier"];
				name = memento["name"];
			}
		}
		
	}

}
