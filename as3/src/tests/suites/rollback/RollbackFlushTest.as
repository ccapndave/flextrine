package tests.suites.rollback {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.WriteMode;
	import org.flexunit.asserts.assertFalse;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class RollbackFlushTest extends AbstractTest {
		
		private var d1:Doctor;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
			
			em.getConfiguration().enabledRollback = true;
		}
		
		[Test(async, description = "Test that flushing clears the rollback queue.")]
		public function flushRollbackTest():void {
			d1 = new Doctor();
			d1.name = "Doctor 1";
			em.persist(d1);
			
			// Now flush
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			assertFalse(em.rollback());
			
			d1.name = "different name";
			
			// Now flush again
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			assertFalse(em.rollback());
		}
		
	}
}