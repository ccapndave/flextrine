package {tmpl_var name='package'} {
<tmpl_if name='implements' op='!=' value='' >	import {tmpl_var name='implementspackage'};
</tmpl_if>
	[RemoteClass(alias="{tmpl_var name='remoteclass'}")]
	[Entity]
	public class {tmpl_var name='classname'} extends {tmpl_var name='classname'}EntityBase <tmpl_if name='implements' op='!=' value='' >implements {tmpl_var name='implements'} </tmpl_if>{
		
	}

}
