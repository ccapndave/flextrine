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

package org.davekeen.flextrine.orm.delegates {
	import flash.events.EventDispatcher;
	import flash.utils.getQualifiedClassName;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.delegates.IDelegateResponder;
	import org.davekeen.delegates.RemoteDelegate;
	import org.davekeen.flextrine.orm.Query;
	import org.davekeen.flextrine.orm.events.FlextrineEvent;
	import org.davekeen.flextrine.orm.events.FlextrineFaultEvent;
	import org.davekeen.flextrine.orm.events.FlextrineResultEvent;
	import org.davekeen.flextrine.orm.rpc.FlextrineAsyncResponder;
	
	/**
	 * @private 
	 * @author Dave Keen
	 */
	public class FlextrineDelegate extends EventDispatcher implements IDelegateResponder {
		
		private var gateway:String;
		
		private var service:String;
		
		public function FlextrineDelegate(gateway:String, service:String, useConcurrentRequests:Boolean) {
			this.gateway = gateway;
			this.service = service;
			
			RemoteDelegate.setUseConcurrentRequests(useConcurrentRequests);
		}
		
		public function load(entityClass:Class, id:Number, fetchMode:String):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("load", [ flextrineClassToDoctrineClass(entityClass), id, fetchMode ], this, gateway, service).execute();
		}
		
		public function loadBy(entityClass:Class, criteria:Object, fetchMode:String):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("loadBy", [ flextrineClassToDoctrineClass(entityClass), criteria, fetchMode ], this, gateway, service).execute();
		}
		
		public function loadOneBy(entityClass:Class, criteria:Object, fetchMode:String, detachedEntity:Object = null):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("loadOneBy", [ flextrineClassToDoctrineClass(entityClass), criteria, fetchMode ], this, gateway, service).execute(detachedEntity);
		}
		
		public function loadAll(entityClass:Class, fetchMode:String):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("loadAll", [ flextrineClassToDoctrineClass(entityClass), fetchMode ], this, gateway, service).execute();
		}
		
		public function select(query:Query, firstIdx:int, lastIdx:uint, fetchMode:String):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("select", [ query, firstIdx, lastIdx, fetchMode ], this, gateway, service).execute();
		}
		
		public function selectOne(query:Query, fetchMode:String, detachedEntity:Object = null):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			return new RemoteDelegate("selectOne", [ query, fetchMode ], this, gateway, service).execute(detachedEntity);
		}
		
		public function flush(remoteOperations:Object, fetchMode:String):AsyncToken {
			dispatchEvent(new FlextrineEvent(FlextrineEvent.FLUSHING));
			return new RemoteDelegate("flush", [ remoteOperations, fetchMode ], this, gateway, service).execute();
		}
		
		public function callRemoteMethod(methodName:String, args:Array):AsyncToken {
			var splitMethodName:Array = methodName.split(".");
			
			if (splitMethodName.length > 2)
				throw new Error("Illegal method name - it must be in the form <RemoteMethod> or <RemoteService>.<RemoteMethod>");
			
			var selectedService:String = (splitMethodName.length == 1) ? service : splitMethodName[0];
			methodName = (splitMethodName.length == 1) ? methodName : splitMethodName[1];
			
			return new RemoteDelegate(methodName, args, null, gateway, selectedService).execute();
		}
		
		public function callRemoteEntityMethod(methodName:String, args:Array):AsyncToken {
			var splitMethodName:Array = methodName.split(".");
			
			if (splitMethodName.length > 2)
				throw new Error("Illegal method name - it must be in the form <RemoteMethod> or <RemoteService>.<RemoteMethod>");
			
			var selectedService:String = (splitMethodName.length == 1) ? service : splitMethodName[0];
			methodName = (splitMethodName.length == 1) ? methodName : splitMethodName[1];
			
			dispatchEvent(new FlextrineEvent(FlextrineEvent.LOADING));
			
			var asyncToken:AsyncToken = new RemoteDelegate(methodName, args, null, gateway, selectedService).execute();
			asyncToken.addResponder(new FlextrineAsyncResponder(
				function (e:ResultEvent, token:Object = null):void {
					dispatchEvent(new FlextrineResultEvent(FlextrineResultEvent.LOAD_COMPLETE, e.result, e));
				},
				function (e:FaultEvent, token:Object = null):void {
					dispatchEvent(new FlextrineFaultEvent(FlextrineFaultEvent.LOAD_FAULT, null, e));
				}
			));
			return asyncToken;
		}
		
		public function callRemoteFlushMethod(methodName:String, args:Array):AsyncToken {
			var splitMethodName:Array = methodName.split(".");
			
			if (splitMethodName.length > 2)
				throw new Error("Illegal method name - it must be in the form <RemoteMethod> or <RemoteService>.<RemoteMethod>");
			
			var selectedService:String = (splitMethodName.length == 1) ? service : splitMethodName[0];
			methodName = (splitMethodName.length == 1) ? methodName : splitMethodName[1];
			
			dispatchEvent(new FlextrineEvent(FlextrineEvent.FLUSHING));
			
			var asyncToken:AsyncToken = new RemoteDelegate(methodName, args, null, gateway, selectedService).execute();
			asyncToken.addResponder(new FlextrineAsyncResponder(
				function (e:ResultEvent, token:Object = null):void {
					dispatchEvent(new FlextrineResultEvent(FlextrineResultEvent.FLUSH_COMPLETE, e.result, e));
				},
				function (e:FaultEvent, token:Object = null):void {
					dispatchEvent(new FlextrineFaultEvent(FlextrineFaultEvent.FLUSH_FAULT, null, e));
				}
			));
			return asyncToken;
		}
		
		private function flextrineClassToDoctrineClass(entityClass:Class):String {
			var qualifiedClassString:String = getQualifiedClassName(entityClass);
			return qualifiedClassString.replace(/\.|::/g, "\\");
		}
		
		/* INTERFACE org.davekeen.delegates.IDelegateResponder */
		
		/**
		 * This is called on a successful return from a remote method.  The token is a pass-through object that is set when the remote method was called.
		 * In this case token is used to set detachedEntity on FlextrineResultEvent, which lets Flextrine know that the root of the returned entity should
		 * be merged into detachedEntity instead of into the repository equivalent.
		 * 
		 * This is used by on-demand loading of entities and collections within a detached entity, ensuring that the entity doesn't become
		 * managed as a result of an automatic requireOne or requireMany call.
		 * 
		 * @param operation
		 * @param data
		 * @param resultEvent
		 * @param token
		 */
		public function onDelegateResult(operation:String, data:Object, resultEvent:ResultEvent = null, token:Object = null):void {
			switch (operation) {
				case "load":
				case "loadBy":
				case "loadOneBy":
				case "loadAll":
				case "select":
				case "selectOne":
					dispatchEvent(new FlextrineResultEvent(FlextrineResultEvent.LOAD_COMPLETE, data, resultEvent, token));
					break;
				case "flush":
					dispatchEvent(new FlextrineResultEvent(FlextrineResultEvent.FLUSH_COMPLETE, data, resultEvent));
					break;
				default:
					throw new Error("Result from unknown operation " + operation + " (" + data + ")");
			}
		}
		
		public function onDelegateFault(operation:String, data:Object, faultEvent:FaultEvent = null, token:Object = null):void {
			switch (operation) {
				case "load":
				case "loadBy":
				case "loadOneBy":
				case "loadAll":
				case "select":
				case "selectOne":
					dispatchEvent(new FlextrineFaultEvent(FlextrineFaultEvent.LOAD_FAULT, data, faultEvent));
					break;
				case "flush":
					dispatchEvent(new FlextrineFaultEvent(FlextrineFaultEvent.FLUSH_FAULT, data, faultEvent));
					break;
				default:
					throw new Error("Fault from unknown operation " + operation + " (" + data + ")");
			}
		}
		
	}

}