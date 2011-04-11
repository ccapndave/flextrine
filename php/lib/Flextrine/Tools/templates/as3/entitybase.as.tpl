package {tmpl_var name='package'} {
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import mx.events.PropertyChangeEvent;
	import mx.collections.errors.ItemPendingError;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.flextrine;
<tmpl_loop name='associationsloop'>
<tmpl_if name='type' op='<>' value='PersistentCollection'>
	import {tmpl_var name='package'};
</tmpl_if>
</tmpl_loop>

	[Bindable]
	public class {tmpl_var name='classname'}EntityBase extends EventDispatcher {
		
		public var isUnserialized__:Boolean;
		
		public var isInitialized__:Boolean = true;
		
		flextrine var itemPendingError:ItemPendingError;
		
<tmpl_loop name='fieldsloop'>
<tmpl_if name='id'>		[Id]
		public function get {tmpl_var name='name'}():{tmpl_var name='type'} { return _{tmpl_var name='name'}; }
		public function set {tmpl_var name='name'}(value:{tmpl_var name='type'}):void { _{tmpl_var name='name'} = value; }
		private var _{tmpl_var name='name'}:{tmpl_var name='type'};
		
<tmpl_else>		public function get {tmpl_var name='name'}():{tmpl_var name='type'} { checkIsInitialized("{tmpl_var name='name'}"); return <tmpl_if name='type' op='==' value='Date'>(_{tmpl_var name='name'} && _{tmpl_var name='name'}.getTime() > 0) ? _{tmpl_var name='name'} : null<tmpl_else>_{tmpl_var name='name'}</tmpl_if>; }
		public function set {tmpl_var name='name'}(value:<tmpl_if name='type' op='==' value='Date'>*<tmpl_else>{tmpl_var name='type'}</tmpl_if>):void { _{tmpl_var name='name'} = <tmpl_if name='type' op='==' value='Date'>(value is Date) ? value : new Date(value)<tmpl_else>value</tmpl_if>; }
		private var _{tmpl_var name='name'}:{tmpl_var name='type'}<tmpl_if name='type' op='==' value='Number'> = 0</tmpl_if>;
		
</tmpl_if>
</tmpl_loop>
<tmpl_loop name='associationsloop'>
		[Association(side="{tmpl_var name='side'}"<tmpl_if name='bidirectional'>, oppositeAttribute="{tmpl_var name='oppositeAssociationName'}", oppositeCardinality="{tmpl_var name='oppositeCardinality'}"</tmpl_if>)]
		public function get {tmpl_var name='name'}():{tmpl_var name='type'} { checkIsInitialized("{tmpl_var name='name'}"); return _{tmpl_var name='name'}; }
		public function set {tmpl_var name='name'}(value:{tmpl_var name='type'}):void { <tmpl_if name='type' op='!=' value='PersistentCollection'><tmpl_if name='bidirectional'><tmpl_if name='oppositeCardinality' op='==' value='1'>(value) ? value.flextrine::setValue('{tmpl_var name='oppositeAssociationName'}', this) : ((_{tmpl_var name='name'}) ? _{tmpl_var name='name'}.flextrine::setValue('{tmpl_var name='oppositeAssociationName'}', null) : null); <tmpl_else>(value) ? value.flextrine::addValue('{tmpl_var name='oppositeAssociationName'}', this) : ((_{tmpl_var name='name'}) ? _{tmpl_var name='name'}.flextrine::removeValue('{tmpl_var name='oppositeAssociationName'}', this) : null); </tmpl_if></tmpl_if></tmpl_if>_{tmpl_var name='name'} = value; }
		private var _{tmpl_var name='name'}:{tmpl_var name='type'};
		
</tmpl_loop>
		public function {tmpl_var name='classname'}EntityBase() {
<tmpl_loop name='associationsloop'>
<tmpl_if name='type' op='==' value='PersistentCollection'>			if (!_{tmpl_var name='name'}) _{tmpl_var name='name'} = new PersistentCollection(null, true, "{tmpl_var name='name'}", this);
</tmpl_if>
</tmpl_loop>
		}
		
		override public function toString():String {
			return "[{tmpl_var name='classname'} <tmpl_loop name='identifiersloop'>{tmpl_var name='identifier'}=" + {tmpl_var name='identifier'} + "</tmpl_loop>]";
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
<tmpl_loop name='fieldsloop'>				memento["{tmpl_var name='name'}"] = {tmpl_var name='name'};
</tmpl_loop>
<tmpl_loop name='associationsloop'>				<tmpl_if name='type' op='==' value='PersistentCollection'>memento["{tmpl_var name='name'}"] = {tmpl_var name='name'}.flextrine::saveState();
<tmpl_else>memento["{tmpl_var name='name'}"] = {tmpl_var name='name'};
</tmpl_if></tmpl_loop>
				return memento;
			}
			
			return null;
		}
		
		flextrine function restoreState(memento:Dictionary):void {
			if (isInitialized__) {
<tmpl_loop name='fieldsloop'>				<tmpl_if name='type' op='==' value='Boolean'>{tmpl_var name='name'} = (memento["{tmpl_var name='name'}"] == true);
<tmpl_else>{tmpl_var name='name'} = memento["{tmpl_var name='name'}"];
</tmpl_if>
</tmpl_loop>
<tmpl_loop name='associationsloop'>				<tmpl_if name='type' op='==' value='PersistentCollection'>{tmpl_var name='name'}.flextrine::restoreState(memento["{tmpl_var name='name'}"]);
<tmpl_else>{tmpl_var name='name'} = memento["{tmpl_var name='name'}"];
</tmpl_if></tmpl_loop>
			}
		}
		
	}

}
