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

package org.davekeen.flextrine.orm {
	/**
	 * The fetch mode defines how Flextrine will load associations.
	 * 
	 * <p>When using <code>FetchMode.EAGER</code> all associations will be followed in all connected
	 * entities, thus returnig a complete connected object heirarchy.  Loading associations in eager
	 * mode makes it much easier to work with entities, as all their associations will definitely be available.
	 * However, in some cases (especially with bi-directional assocations) it is possible to accidentally
	 * load a very large amount of data without meaning to.</p>
	 * 
	 * <p>Conversely when using <code>FetchMode.LAZY</code> no associations will be followed at all, and Flextrine will return
	 * only the requested entity and nothing more.  Both single valued associations and collections
	 * will be replaced with unitialized stubs and its necessary to to use <code>EntityMananger.requireOne</code>
	 * and <code>EntityManager.requireMany</code> to fill these stubs in from the database.</p>
	 * 
	 * <p>Note that its also possible to use <code>EntityManager.select</code> with <code>FetchMode.LAZY</code> to explicitly
	 * define which associations to fetch by using <b>DQL fetch joins</b>.  See Doctrine 2 DQL documentation
	 * for more details.</p>
	 * 
	 * @author Dave Keen
	 */
	public class FetchMode {
		
		/**
		 * Lazy fetch mode.  Don't follow any associations when loading entities.
		 */
		public static const LAZY:String = "lazy";
		
		/**
		 * Eager fetch mode.  Follow all associations when loading entities.
		 */
		public static const EAGER:String = "eager";
		
	}

}