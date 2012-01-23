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