package org.davekeen.flextrine.cache {
	import flash.utils.Dictionary;
	
	public class DictionaryCache implements ICache {
		
		private var dictionary:Dictionary;
		
		public function DictionaryCache(weakKeys:Boolean = false) {
			dictionary = new Dictionary(weakKeys);
		}
		
		public function fetch(key:*):* {
			if (!contains(key))
				throw new Error("Unable to find entry with key '" + key + "' in DictionaryCache");
			
			return dictionary[key];
		}
		
		public function contains(key:*):Boolean {
			return (dictionary[key] != null);
		}
		
		public function save(key:*, value:*):void {
			dictionary[key] = value;
		}
		
		public function remove(key:*):void {
			if (!contains(key))
				throw new Error("Unable to find entry with key '" + key + "' in DictionaryCache");
			
			delete dictionary[key];
		}
		
	}
	
}