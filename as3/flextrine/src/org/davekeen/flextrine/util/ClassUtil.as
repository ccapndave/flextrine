/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 * 
 * This file is part of Flextrine.
 * 
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 * 
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