/**
 * Copyright (C) 2012 Dave Keen http://www.actionscriptdeveloper.co.uk
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

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