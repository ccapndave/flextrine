package tests.vo.types {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;

	[Bindable]
	public class TypesObjectEntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var savedState:Dictionary;
		
		flextrine var itemPendingError:ItemPendingError;
		
		[Id]
		public function get id():String { return _id; }
		public function set id(value:String):void { _id = value; }
		private var _id:String;
		
		public function get integerField():int { checkIsInitialized("integerField"); return _integerField; }
		public function set integerField(value:int):void { _integerField = value; }
		private var _integerField:int;
		
		public function get smallIntField():int { checkIsInitialized("smallIntField"); return _smallIntField; }
		public function set smallIntField(value:int):void { _smallIntField = value; }
		private var _smallIntField:int;
		
		public function get bigIntField():Number { checkIsInitialized("bigIntField"); return _bigIntField; }
		public function set bigIntField(value:Number):void { _bigIntField = value; }
		private var _bigIntField:Number = 0;
		
		public function get decimalField():Number { checkIsInitialized("decimalField"); return _decimalField; }
		public function set decimalField(value:Number):void { _decimalField = value; }
		private var _decimalField:Number = 0;
		
		public function get booleanField():Boolean { checkIsInitialized("booleanField"); return _booleanField; }
		public function set booleanField(value:Boolean):void { _booleanField = value; }
		private var _booleanField:Boolean;
		
		public function get textField():String { checkIsInitialized("textField"); return _textField; }
		public function set textField(value:String):void { _textField = value; }
		private var _textField:String;
		
		public function get stringField():String { checkIsInitialized("stringField"); return _stringField; }
		public function set stringField(value:String):void { _stringField = value; }
		private var _stringField:String;
		
		public function get dateField():Date { checkIsInitialized("dateField"); return (_dateField && _dateField.getTime() > 0) ? _dateField : null; }
		public function set dateField(value:*):void { _dateField = (value is Date) ? value : new Date(value); }
		private var _dateField:Date;
		
		public function get dateTimeField():Date { checkIsInitialized("dateTimeField"); return (_dateTimeField && _dateTimeField.getTime() > 0) ? _dateTimeField : null; }
		public function set dateTimeField(value:*):void { _dateTimeField = (value is Date) ? value : new Date(value); }
		private var _dateTimeField:Date;
		
		public function TypesObjectEntityBase() {
		}
		
		override public function toString():String {
			return "[TypesObject id=" + id + "]";
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
		
		flextrine function saveState():void {
			if (isInitialized__) {
				flextrine::savedState = new Dictionary(true);
				flextrine::savedState["id"] = id;
				flextrine::savedState["integerField"] = integerField;
				flextrine::savedState["smallIntField"] = smallIntField;
				flextrine::savedState["bigIntField"] = bigIntField;
				flextrine::savedState["decimalField"] = decimalField;
				flextrine::savedState["booleanField"] = booleanField;
				flextrine::savedState["textField"] = textField;
				flextrine::savedState["stringField"] = stringField;
				flextrine::savedState["dateField"] = dateField;
				flextrine::savedState["dateTimeField"] = dateTimeField;
			}
		}
		
		flextrine function restoreState():void {
			if (isInitialized__) {
				id = flextrine::savedState["id"];
				integerField = flextrine::savedState["integerField"];
				smallIntField = flextrine::savedState["smallIntField"];
				bigIntField = flextrine::savedState["bigIntField"];
				decimalField = flextrine::savedState["decimalField"];
				booleanField = (flextrine::savedState["booleanField"] == true);
				textField = flextrine::savedState["textField"];
				stringField = flextrine::savedState["stringField"];
				dateField = flextrine::savedState["dateField"];
				dateTimeField = flextrine::savedState["dateTimeField"];
			}
		}
		
	}

}
