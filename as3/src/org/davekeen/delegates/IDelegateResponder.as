/**
 * Copyright 2010 Dave Keen
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
 * If not, see http://www.gnu.org/licenses/.
 * 
 */

package org.davekeen.delegates {
	
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	/**
	 * @private
	 * @author Dave Keen
	 */
	
	public interface IDelegateResponder {
		
		function onDelegateResult(operation:String, data:Object, resultEvent:ResultEvent = null, token:Object = null):void;
		function onDelegateFault(operation:String, data:Object, faultEvent:FaultEvent = null, token:Object = null):void;
		
	}
	
}