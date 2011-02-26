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
	/**
	 * Provides helper methods for working with queries in Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class QueryUtil {
		
		/**
		 * Formats an object or a class into a DQL friendly fully qualified class name for use in select queries.
		 * 
		 * @example This is an example of using <code>getDQLClass</code> in a select:
		 * 
		 * <pre>
		 *   em.select("SELECT u FROM " + QueryUtil.getDQLClass(User) + " u WHERE u.age > 25");
		 * </pre>
		 * 
		 * @param	obj Either an object or a class
		 * @return  a Doctrine 2 formatted DQL fully qualified class name
		 */
		public static function getDQLClass(obj:Object):String {
			return ClassUtil.getQualifiedClassNameAsString(obj).replace(/\./g, "\\")
		}
		
	}

}