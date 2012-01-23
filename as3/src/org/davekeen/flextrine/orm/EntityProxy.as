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
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Dictionary;
	import flash.utils.IDataInput;
	import flash.utils.IDataOutput;
	import flash.utils.IExternalizable;
	import flash.utils.Proxy;
	import flash.utils.Timer;
	import flash.utils.flash_proxy;
	import flash.utils.getQualifiedClassName;
	
	import mx.core.IPropertyChangeNotifier;
	import mx.events.PropertyChangeEvent;
	import mx.events.PropertyChangeEventKind;
	import mx.utils.ObjectUtil;
	import mx.utils.UIDUtil;
	
	import org.davekeen.flextrine.flextrine;
	
	use namespace flash_proxy;
	use namespace flextrine;
	
	/**
	 * A utility class which is used as a wrapper for entities in a repository.  The actual storage mechanism uses a Dictionary with a weak key (as long
	 * as configuration.entityTimeToLive is not -1 in which case the entity will live forever).  This means that garbage collection will gradually replace
	 * entities in the repository will null as they fall out of usage.
	 */
	[Bindable("propertyChange")]
	public dynamic class EntityProxy extends Proxy implements IExternalizable, IPropertyChangeNotifier {
		
		private var timer:Timer;
		
		protected var dispatcher:EventDispatcher;
		
		protected var notifiers:Object;
		
		protected var proxyClass:Class = EntityProxy;
		
		protected var propertyList:Array;
		
		private var _type:QName;
		
		private var _proxyLevel:int;
		
		/**
		 * We use a dictionary to store an entity so it can be garbage collected even with this reference 
		 */
		private var dictionary:Dictionary;
		
		/**
		 * Use this to keep a strong reference to the item in the Dictionary to prevent it being garbage collection
		 */
		private var strongReference:Object;
		
		/**
		 * This timer is used to delete the strong reference once entityTimeToLive has run out, making the entity eligable for garbage collection
		 */
		private var expireTimer:Timer;
		
		flextrine var objectToString:String;
		
		private var _id:String;
		
		public function EntityProxy(item:Object, entityTimeToLive:int = 0) {
			super();
			
			// If the entityTimeToLive is not -1 use weak keys so the associated entity can be garbage collected
			dictionary = new Dictionary(entityTimeToLive >= 0);
			_item = item;
			
			_proxyLevel = 1;
			notifiers = {};
			dispatcher = new EventDispatcher(this);
			objectToString = item.toString();
			
			if (entityTimeToLive >= 0) {
				// Get a strong reference to the item in the Dictionary so it isn't garbage collected until entityTimeToLive has run out
				strongReference = _item;
				
				// Use a timer to remove the strong reference once the entityTimeToLive has expired
				expireTimer = new Timer(entityTimeToLive, 1);
				expireTimer.addEventListener(TimerEvent.TIMER_COMPLETE, onExpireTimerComplete);
				expireTimer.start();
			}
			
		}
		
		private function onExpireTimerComplete(e:Event):void {
			expireTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, onExpireTimerComplete);
			expireTimer = null;
			strongReference = null;
		}
		
		public function get _item():Object {
			for (var item:* in dictionary)
				return item;
			
			return null;
		}

		public function set _item(value:Object):void {
			dictionary[value] = true;
		}

		flextrine function get object():Object {
			return _item;
		}
		
		flextrine function get type():QName {
			return _type;
		}
		
		flextrine function set type(value:QName):void {
			_type = value;
		}
		
		public function get uid():String {
			if (_id === null)
				_id = UIDUtil.createUID();
			
			return _id;
		}
		
		public function set uid(value:String):void {
			_id = value;
		}
		
		override flash_proxy function getProperty(name:*):* {
			// if we have a data proxy for this then
			var result:*;
			
			if (notifiers[name.toString()])
				return notifiers[name];
			
			result = _item[name];
			
			if (result) {
				if (_proxyLevel == 0 || ObjectUtil.isSimple(result)) {
					return result;
				} else {
					result = flextrine::getComplexProperty(name, result);
				} // if we are proxying
			}
			
			return result;
		}
		
		override flash_proxy function callProperty(name:*, ... rest):* {
			return _item[name].apply(_item, rest)
		}
		
		override flash_proxy function deleteProperty(name:*):Boolean {
			var notifier:IPropertyChangeNotifier = IPropertyChangeNotifier(notifiers[name]);
			if (notifier) {
				notifier.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler);
				delete notifiers[name];
			}
			
			var oldVal:* = _item[name];
			var deleted:Boolean = delete _item[name];
			
			if (dispatcher.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE)) {
				var event:PropertyChangeEvent = new PropertyChangeEvent(PropertyChangeEvent.PROPERTY_CHANGE);
				event.kind = PropertyChangeEventKind.DELETE;
				event.property = name;
				event.oldValue = oldVal;
				event.source = this;
				dispatcher.dispatchEvent(event);
			}
			
			return deleted;
		}
		
		override flash_proxy function hasProperty(name:*):Boolean {
			return (name in _item);
		}
		
		override flash_proxy function nextName(index:int):String {
			return propertyList[index - 1];
		}
		
		override flash_proxy function nextNameIndex(index:int):int {
			if (index == 0) {
				setupPropertyList();
			}
			
			if (index < propertyList.length) {
				return index + 1;
			} else {
				return 0;
			}
		}
		
		override flash_proxy function nextValue(index:int):* {
			return _item[propertyList[index - 1]];
		}
		
		override flash_proxy function setProperty(name:*, value:*):void {
			var oldVal:* = _item[name];
			if (oldVal !== value) {
				// Update item.
				_item[name] = value;
				
				// Stop listening for events on old item if we currently are.
				var notifier:IPropertyChangeNotifier = IPropertyChangeNotifier(notifiers[name]);
				if (notifier) {
					notifier.removeEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler);
					delete notifiers[name];
				}
				
				// Notify anyone interested.
				if (dispatcher.hasEventListener(PropertyChangeEvent.PROPERTY_CHANGE)) {
					if (name is QName)
						name = QName(name).localName;
					var event:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(this, name.toString(), oldVal, value);
					dispatcher.dispatchEvent(event);
				}
			}
		}
		
		flextrine function getComplexProperty(name:*, value:*):* {
			if (value is IPropertyChangeNotifier) {
				value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler);
				notifiers[name] = value;
				return value;
			}
			
			if (getQualifiedClassName(value) == "Object") {
				value = new proxyClass(_item[name], null, _proxyLevel > 0 ? _proxyLevel - 1 : _proxyLevel);
				value.addEventListener(PropertyChangeEvent.PROPERTY_CHANGE, propertyChangeHandler);
				notifiers[name] = value;
				return value;
			}
			
			return value;
		}
		
		public function readExternal(input:IDataInput):void {
			var value:Object = input.readObject();
			_item = value;
		}
		
		public function writeExternal(output:IDataOutput):void {
			output.writeObject(_item);
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			dispatcher.removeEventListener(type, listener, useCapture);
		}
		
		public function dispatchEvent(event:Event):Boolean {
			return dispatcher.dispatchEvent(event);
		}
		
		public function hasEventListener(type:String):Boolean {
			return dispatcher.hasEventListener(type);
		}
		
		public function willTrigger(type:String):Boolean {
			return dispatcher.willTrigger(type);
		}
		
		public function propertyChangeHandler(event:PropertyChangeEvent):void {
			dispatcher.dispatchEvent(event);
		}
		
		protected function setupPropertyList():void {
			if (getQualifiedClassName(_item) == "Object") {
				propertyList = [];
				for (var prop:String in _item)
					propertyList.push(prop);
			} else {
				propertyList = ObjectUtil.getClassInfo(_item, null, {includeReadOnly: true, uris: ["*"]}).properties;
			}
		}
	}

}
