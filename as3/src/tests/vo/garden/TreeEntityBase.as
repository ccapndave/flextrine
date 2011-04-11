package tests.vo.garden {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;
	import tests.vo.garden.Garden;

	[Bindable]
	public class TreeEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var itemPendingError:ItemPendingError;
		
		[Id]
		public function get id():String { return _id; }
		public function set id(value:String):void { _id = value; }
		private var _id:String;
		
		public function get type():String { checkIsInitialized("type"); return _type; }
		public function set type(value:String):void { _type = value; }
		private var _type:String;
		
		[Association(side="inverse", oppositeAttribute="tree", oppositeCardinality="1")]
		public function get branches():PersistentCollection { checkIsInitialized("branches"); return _branches; }
		public function set branches(value:PersistentCollection):void { _branches = value; }
		private var _branches:PersistentCollection;
		
		[Association(side="owning", oppositeAttribute="trees", oppositeCardinality="*")]
		public function get garden():Garden { checkIsInitialized("garden"); return _garden; }
		public function set garden(value:Garden):void { (value) ? value.flextrine::addValue('trees', this) : ((_garden) ? _garden.flextrine::removeValue('trees', this) : null); _garden = value; }
		private var _garden:Garden;
		
		public function TreeEntityBase() {
			if (!_branches) _branches = new PersistentCollection(null, true, "branches", this);
		}
		
		override public function toString():String {
			return "[Tree id=" + id + "]";
		}
		
		private function checkIsInitialized(property:String):void {
			if (!isInitialized__ && isUnserialized__) {
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
				memento["type"] = type;
				memento["branches"] = branches.flextrine::saveState();
				memento["garden"] = garden;
				return memento;
			}
			
			return null;
		}
		
		flextrine function restoreState(memento:Dictionary):void {
			if (isInitialized__) {
				id = memento["id"];
				type = memento["type"];
				branches.flextrine::restoreState(memento["branches"]);
				garden = memento["garden"];
			}
		}
		
	}

}
