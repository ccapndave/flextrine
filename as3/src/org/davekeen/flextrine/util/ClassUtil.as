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

package org.davekeen.flextrine.util {
	
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class ClassUtil {
		
		/**
		 * Return the class of an object as a Class (useful for 'is' comparisons)
		 * 
		 * @param	obj
		 * @return
		 */
		public static function getClass(obj:Object):Class {
			return (obj) ? Class(getDefinitionByName(getQualifiedClassName(obj))) : null;
		}
		
		/**
		 * Returns the class of an object as a String
		 * 
		 * @param	obj
		 * @return
		 */
		public static function getClassAsString(obj:Object):String {
			return formatClassAsString(getClass(obj));
		}
		
		/**
		 * Returns the full package and class - for example calling the method on an instance of this class would return org.davekeen.flextrine.util.ClassUtil
		 * Useful for logging targets which don't accept the :: notation of getQualifiedClassName.
		 * 
		 * @param	obj
		 * @return
		 */
		public static function getQualifiedClassNameAsString(obj:Object):String {
			return getQualifiedClassName(obj).replace("::", ".");
		}
		
		public static function formatClassAsString(c:Object):String {
			if (!(c is Class))
				throw new Error("This method must take a Class as an argument");
				
			return c.toString().match(/\[class (\w*)\]/)[1];
		}
		
		/**
		 * Check if all the objects in the array are of the same class.
		 * 
		 * @param	objects An array of objects
		 * @return	This return the class of the objects or null if the array contains a mix (or is empty)
		 */
		public static function checkObjectClasses(objects:Array):Class {
			if (objects.length == 0) return null;
			
			var objectClass:Class = ClassUtil.getClass(objects[0]);
			
			for each (var o:Object in objects) {
				if (!(o is objectClass)) {
					objectClass = null;
					break;
				}
			}
				
			return objectClass;
		}
		
	}
	
}