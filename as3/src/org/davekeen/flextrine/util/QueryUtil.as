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
	/**
	 * Provides helper methods for working with queries in Flextrine.
	 * 
	 * @author Dave Keen
	 */
	public class QueryUtil {
		
		/**
		 * Formats an object or a class into a DQL friendly fully qualified class name for use in select queries.
		 * 
		 * @example This is an example of using <code>getDQLClass</code> in a select
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