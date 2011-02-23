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
	
	[RemoteClass(alias="org.davekeen.flextrine.orm.Query")]
	public class Query {
		
		public var dql:String;
		
		public var params:Object;
		
		public var firstResult:uint;
		
		public var maxResults:uint;
		
		public function Query(dql:String, params:Object = null, firstResult:uint = 0, maxResults:uint = 0) {
			this.dql = dql;
			this.params = params;
			this.firstResult = firstResult;
			this.maxResults = maxResults;
		}
		
		public function setParameter(name:String, value:Object):void {
			params[name] = value;
		}
		
	}
	
}