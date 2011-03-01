package org.davekeen.flextrine.orm.collections {
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	import mx.collections.ArrayCollection;
	import mx.collections.IList;
	import mx.collections.ItemResponder;
	import mx.collections.ListCollectionView;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.Query;
	import org.davekeen.flextrine.orm.delegates.FlextrineDelegate;

	public class PagedCollection extends ListCollectionView {

		private var pageQueue:Array = new Array();
		private var delegate:FlextrineDelegate;
		private var query:Query;
		protected var _count:int;
		private var loadedRecords:Array = new Array();
		private var refreshTimer:Timer;
		private var workQueue:Array = new Array();

		// set to true if you want to throw away all packet fetch requests except the most recent one
		public var PROCESS_MOST_RECENT_ONLY:Boolean = false;
		private var _pageSize:uint = 60;

		public function PagedCollection(list:IList = null) {
			super(list);

			refreshTimer = new Timer(250, 1);
			refreshTimer.addEventListener(TimerEvent.TIMER, doRefreshTimer, false, 0, true);

			this.sort = new NullSort();
		}

		[Bindable("collectionChange")]
		public override function get length():int {
			return _count;
		}

		public function set pageSize(ps:uint):void {
			this._pageSize = ps;
		}

		public function get pageSize():uint {
			return this._pageSize;
		}

		public function setDelegate(delegate:FlextrineDelegate):void {
			this.delegate = delegate;
			loadedRecords = new Array();

			getInitial();
			//addRecordToQueue(0);
		}

		public function setQuery(query:Query):void {
			this.query = query;
			loadedRecords = new Array();

			getInitial();
			//addRecordToQueue(0);			
		}

		public override function getItemAt(idx:int, prefetch:int = 0):Object {
			addRecordToQueue(idx);
			return list[idx];
		}

		public override function setItemAt(item:Object, index:int):Object {
			return super.setItemAt(item, index);
		}


		private function addRecordToQueue(recordIdx:int):void {
			if (!loadedRecords[recordIdx] || loadedRecords[recordIdx] == 0) {
				loadedRecords[recordIdx] = 1;
				//if( this.pageQueue.indexOf(recordIdx) == -1)
				this.pageQueue.push({rec: recordIdx, priority: new Date().time});

				/*if( !refreshTimer.running)
				{
					refreshTimer.reset();
					refreshTimer.start();
				}*/
				refreshTimer.stop();
				refreshTimer.reset();
				refreshTimer.start();
			}
		}

		private function doRefreshTimer(e:TimerEvent):void {
			processQueue();
		}

		private function processQueue():void {
			// batch the records that need fetching into work units for flextrine to fetch
			// [1,2,3,5,6,99,100,104] will result in 2 work units, 1-6 and 99-104

			var maxGap:int = 5; // the biggest allowed gap in record index before a new fetch packet is started
			//this.pageQueue.sort(Array.NUMERIC);
			this.pageQueue.sortOn("rec", Array.NUMERIC);
			var si:int = -1;
			var ei:int = -1;
			var sio:Object;
			var eio:Object;
			var lastei:int;
			var maxpriority:Number;
			if (this.pageQueue.length > 1) {
				sio = this.pageQueue.shift();
				si = sio.rec;
				lastei = si;
				maxpriority = sio.priority;
				while (this.pageQueue.length > 0) {
					eio = this.pageQueue.shift();
					ei = eio.rec;
					maxpriority = Math.max(eio.priority, maxpriority);
					if (ei - lastei > maxGap || (this.pageQueue.length == 0)) {
						this.workQueue.push({start: si, end: ei + 1, priority: maxpriority});
						if (this.pageQueue.length > 0) {
							sio = this.pageQueue.shift();
							si = sio.rec;
							maxpriority = sio.priority;
						}
					}
					lastei = ei;
				}
			} else if (this.pageQueue.length == 1) {
				sio = this.pageQueue.pop();
				this.workQueue.push({start: sio.rec, end: sio.rec + 1, priority: sio.priority});
			}
			//trace('workQueue length', workQueue.length);
			if (this.workQueue.length > 0) {
				// process the most recent record fetch request packet first
				workQueue.sortOn("priority", Array.NUMERIC | Array.DESCENDING);
				var workUnit:Object = this.workQueue.pop();

				if (this.PROCESS_MOST_RECENT_ONLY) {
					while (this.workQueue.length > 0) {
						var tq:Object = this.workQueue.pop();
						for (var n:int = tq.start; n < tq.end; n++) {
							if (loadedRecords[n] && loadedRecords[n] != 2)
								loadedRecords[n] = 0;
						}
					}
				}
				fetchRecordsInWorkQueue(workUnit);
			}
		}

		private function fetchRecordsInWorkQueue(workUnit:Object):void {
			if (delegate && query) {
				var startidx:int = workUnit.start;
				var endidx:int = workUnit.end;
				trace("Loading:", startidx, endidx);
				var asyncToken:AsyncToken = delegate.select(query, startidx, endidx, FetchMode.LAZY);
				asyncToken.addResponder(new ItemResponder(onAsyncResult, onAsyncFault, {start: startidx, end: endidx}));
			}
		}

		private function getInitial():void {
			if (delegate && query) {
				//addRecordToQueue(0);
				var asyncToken:AsyncToken = delegate.select(query, 0, _pageSize, FetchMode.LAZY);
				asyncToken.addResponder(new ItemResponder(onAsyncResult, onAsyncFault, {start: 0, end: _pageSize}));
			}
		}

		private function onAsyncFault(error:FaultEvent, token:Object = null):void {
			trace("GOT A FAULT " + error.toString());
		}

		private function onAsyncResult(resultEvent:ResultEvent, token:Object = null):void {
			//trace("Loaded:", token.start, token.end);
			var count:uint = resultEvent.result.count;
			var resultArray:Array = resultEvent.result.results;
			var idx:int = 0;

			if (!list) {
				var ac:ArrayCollection = new ArrayCollection();
				ac.source.length = count;
				list = ac;
			}

			for (var n:int = token.start; n < token.end; n++) {
				if (resultArray.length > idx) {
					this.loadedRecords[n] = 2;

					var exists:Boolean = this.list[n];
					var oldValue:* = this.list[n];
					list[n] = resultArray[idx++];

					var ipce:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(list, n, oldValue, this.list[n]);
					if (exists)
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, true, false, CollectionEventKind.REPLACE, n, n, [ipce]));
					else
						dispatchEvent(new CollectionEvent(CollectionEvent.COLLECTION_CHANGE, true, false, CollectionEventKind.ADD, n, -1, [this.list[n]]));
				}
			}
			// If the length has changed dispatch a PropertyChangeEvent
			if (count != _count) {
				var propertyChangeEvent:PropertyChangeEvent = PropertyChangeEvent.createUpdateEvent(this, "length", _count, count);
				_count = count;
				dispatchEvent(propertyChangeEvent);
			}

			var callLater:Timer = new Timer(1, 1);
			callLater.addEventListener(TimerEvent.TIMER, function(e:TimerEvent):void {
				processQueue();
			});
			callLater.start();
		}

	}
}

import mx.collections.Sort;

class NullSort extends Sort {

	private var _sorted:Boolean = false;

	public function get sorted():Boolean {
		return _sorted;
	}

	public override function sort(array:Array):void {
		_sorted = true;
	}
}
