package tests.suites.memory {
	import flash.system.System;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class MemoryTest extends AbstractTest {
		
		private var p:Patient;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "Basic test that checks garbage collection works.")]
		public function memoryTest():void {
			em.getRepository(Doctor).loadAll(FetchMode.LAZY).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Check that everything was loaded correctly.  This should only load one of the countries in the db.
			Assert.assertEquals(3, em.getRepository(Doctor).entities.length);
			trace("Hello");
			System.gc();
			trace("Done");
			Assert.assertEquals(3, em.getRepository(Doctor).entities.length);
			trace(em.getRepository(Doctor).entities);
		}
		
	}

}