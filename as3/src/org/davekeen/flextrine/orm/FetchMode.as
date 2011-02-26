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
	 * for more details.
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