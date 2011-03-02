package {tmpl_var name='package'} {
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
<tmpl_loop name='associationsloop'>
 <tmpl_if name='type' op='<>' value='PersistentCollection'>
	import {tmpl_var name='package'};
 </tmpl_if>
 </tmpl_loop>
 
	public interface {tmpl_var name='classname'}InterfaceBase {
	
<tmpl_loop name='fieldsloop'>
		[Bindable(event="propertyChange")]
		function get {tmpl_var name='name'}():{tmpl_var name='type'};
		function set {tmpl_var name='name'}(value:<tmpl_if name='type' op='==' value='Date'>*<tmpl_else>{tmpl_var name='type'}</tmpl_if>):void;
		
</tmpl_loop>
<tmpl_loop name='associationsloop'>
		[Bindable(event="propertyChange")]
		function get {tmpl_var name='name'}():{tmpl_var name='type'};
		function set {tmpl_var name='name'}(value:{tmpl_var name='type'}):void;
		
</tmpl_loop>
	}

}
