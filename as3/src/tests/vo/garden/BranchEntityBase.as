package tests.vo.garden {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.davekeen.flextrine.flextrine;
	import tests.vo.garden.Tree;

	[Bindable]
	public class BranchEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var itemPendingError:ItemPendingError;
		
		[Id]
		public function get id():String { return _id; }
		public function set id(value:String):void { _id = value; }
		private var _id:String;
		
		public function get length():int { checkIsInitialized("length"); return _length; }
		public function set length(value:int):void { _length = value; }
		private var _length:int;
		
		[Association(side="inverse", oppositeAttribute="branch", oppositeCardinality="1")]
		public function get leaves():PersistentCollection { checkIsInitialized("leaves"); return _leaves; }
		public function set leaves(value:PersistentCollection):void { _leaves = value; }
		private var _leaves:PersistentCollection;
		
		[Association(side="owning", oppositeAttribute="branches", oppositeCardinality="*")]
		public function get tree():Tree { checkIsInitialized("tree"); return _tree; }
		public function set tree(value:Tree):void { (value) ? value.flextrine::addValue('branches', this) : ((_tree) ? _tree.flextrine::removeValue('branches', this) : null); _tree = value; }
		private var _tree:Tree;
		
		public function BranchEntityBase() {
			if (!_leaves) _leaves = new PersistentCollection(null, true, "leaves", this);
		}
		
		override public function toString():String {
			return "[Branch id=" + id + "]";
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
				memento["length"] = length;
				memento["leaves"] = leaves.flextrine::saveState();
				memento["tree"] = tree;
				return memento;
			}
			
			return null;
		}
		
		flextrine function restoreState(memento:Dictionary):void {
			if (isInitialized__) {
				id = memento["id"];
				length = memento["length"];
				leaves.flextrine::restoreState(memento["leaves"]);
				tree = memento["tree"];
			}
		}
		
	}

}
