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

package org.davekeen.delegates {
	import flash.events.EventDispatcher;
	
	import mx.messaging.ChannelSet;
	import mx.messaging.channels.AMFChannel;
	import mx.rpc.AbstractOperation;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.mxml.RemoteObject;
	
	import org.davekeen.flextrine.orm.rpc.FlextrineAsyncResponder;
	
	/**
	 * @private
	 * @author Dave Keen
	 */
	
	public class RemoteDelegate extends EventDispatcher implements IDelegate {
		
		// PHP Error codes
		public static const E_ERROR:int = 1;
		public static const E_WARNING:int = 1;
		public static const E_NOTICE:int = 8;
		
		private static var useConcurrentRequests:Boolean;
		
		private static var concurrentRemoteObject:RemoteObject;
		
		private var remoteObject:RemoteObject;
		
		private var responder:IDelegateResponder;
		private var operationName:String;
		private var args:Array;
		
		private var channelSet:ChannelSet;
		private var service:String;
		
		private var dispatchEvents:Boolean;
		
		public function RemoteDelegate(operationName:String = "", args:Array = null, responder:IDelegateResponder = null, gateway:String = null, service:String = null, dispatchEvents:Boolean = false) {
			super();
			
			this.responder = responder;
			this.operationName = operationName;
			this.args = args;
			this.dispatchEvents = dispatchEvents;
			
			// Create the channel set for the given gateway
			channelSet = new ChannelSet();
			var amfChannel:AMFChannel = new AMFChannel("zendamf", gateway);
			channelSet.addChannel(amfChannel);
			
			// Set the service
			this.service = service;
			
			if (useConcurrentRequests && !concurrentRemoteObject) {
				concurrentRemoteObject = new RemoteObject();
				
				// Set the gateway and service of the remote object
				concurrentRemoteObject.channelSet = channelSet;
				concurrentRemoteObject.destination = "zendamf";
				concurrentRemoteObject.source = service;
			}
		}
		
		public function setOperationName(operationName:String):void {
			this.operationName = operationName;
		}
		
		public function getOperationName():String {
			return operationName;
		}
		
		public function setArgs(args:Array = null):void {
			this.args = args;
		}
		
		public function setDispatchEvents(dispatchEvents:Boolean):void {
			this.dispatchEvents = dispatchEvents;
		}
		
		public static function setUseConcurrentRequests(useConcurrentRequests:Boolean):void {
			RemoteDelegate.useConcurrentRequests = useConcurrentRequests;
		}
		
		/**
		 * Make the remote function call.
		 */
		public function execute(token:Object = null):AsyncToken {
			var operation:AbstractOperation;
			
			if (useConcurrentRequests) {
				// Use the same remote object
				// TODO: This needs to be examined with regards to concurrently calling different services
				operation = concurrentRemoteObject.getOperation(operationName);
			} else {
				// Create a new remote object
				remoteObject = new RemoteObject();
				
				remoteObject.channelSet = channelSet;
				remoteObject.destination = "zendamf";
				remoteObject.source = service;
				
				operation = remoteObject.getOperation(operationName);
			}
			
			if (args)
				operation.arguments = args;
			
			// Add a responder to this async token first - this ensure that any listeners on responder are called before listeners added to the returned
			// AsyncToken.
			var asyncToken:AsyncToken = operation.send();
			asyncToken.addResponder(new FlextrineAsyncResponder(onResult, onFault, token));
			return asyncToken;
		}
		
		/**
		 * Remove event listeners and disconnect the remote object.  This should make the delegate eligable for garbage collection.
		 */
		private function closeRemoteObject():void {
			remoteObject = null;
		}
		
		/**
		 * A result has been received so close the remote object and call the onDelegateResult method on the listener.
		 * 
		 * @param	event
		 */
		private function onResult(event:ResultEvent, token:Object = null):void {
			closeRemoteObject();
			if (responder) responder.onDelegateResult(operationName, event.result, event, token);
			if (dispatchEvents) dispatchEvent(event);
		}
		
		/**
		 * A fault has been received so close the remote object and call the onDelegateFault method on the listener.
		 * 
		 * @param	event
		 */
		private function onFault(event:FaultEvent, token:Object = null):void {
			closeRemoteObject();
			trace("RemoteDelegate:" + event.fault);
			if (responder) responder.onDelegateFault(operationName, event.fault.faultString, event, token);
			if (dispatchEvents) dispatchEvent(event);
		}
		
	}
	
}