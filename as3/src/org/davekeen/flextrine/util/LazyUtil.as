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
 * If not, see http://www.gnu.org/licenses/.
 * 
 */

package org.davekeen.flextrine.util {
	import mx.collections.errors.ItemPendingError;
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;

	public class LazyUtil {

		/**
		 * Standard flex logger
		 */
		private static var log:ILogger = Log.getLogger("org.davekeen.flextrine.util.LazyUtil");

		/**
		 * A helper method to allow blocks of code that may throw ItemPendingErrors to be executed, and automatically re-executed after lazy content
		 * has been loaded.  Since this method is not associated in any way with the Flextrine core it is acceptable to use it directly in view
		 * components.
		 * 
		 * For example, the following code will get the first item in the <code>pages</code> collection and assign the result to the <code>page</code>
		 * instance variable.  If it happens that <code>pages</code> is lazily loaded it will automatically be retrieved from the server and the code
		 * block will be run again when it is ready.
		 * 
		 * <pre>
		 * LazyUtil.async(function():void {
		 * 		page = myBook.pages.getItemAt(0) as Page;
		 * } );
		 * </pre>
		 * 
		 * Flextrine can throw ItemPendingErrors on lazily loaded collections and lazily loaded entities (see Configuration), so this method can be
		 * used in both cases.
		 * 
		 * @param result
		 * @param fault
		 */
		public static function async(result:Function, fault:Function = null):void {
			try {
				result();
			} catch (e:ItemPendingError) {
				log.info("ItemPendingError recieved during an async block; starting responder.");
				e.addResponder(new AsyncResponder(
					function(e:ResultEvent, token:Object):void {
						log.info("Received result.");
						result();
					},
					function (e:FaultEvent, token:Object):void {
						log.info("Received fault [{0}]", e.fault.faultDetail);
						if (fault != null) fault();
					}
				));
			}
		}
		
	}

}