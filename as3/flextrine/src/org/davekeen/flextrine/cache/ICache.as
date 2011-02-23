package org.davekeen.flextrine.cache {
	
	public interface ICache {
		
		function fetch(key:*):*;
		
		function contains(keyEntity:*):Boolean;
		
		function save(key:*, valueEntity:*):void;
		
		function remove(key:*):void;
		
	}
	
}