package tests.suites.pull {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.WriteMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class PullUpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture("doctors1");
			
			em.getConfiguration().writeMode = WriteMode.PULL;
		}
		
		private var d1:Doctor;
		
		[Test(async, description = "Very basic test that checks that property updates work in pull mode.")]
		public function updateTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			
			// In WriteMode.PULL mode we can't write directly to entities, so use detach and merge
			var detachedD1:Doctor = em.detach(d1) as Doctor;
			detachedD1.name = "Doctor 1 name changed";
			em.merge(detachedD1);
			
			// Check the original d1 remains unchanged
			Assert.assertEquals(d1, em.getRepository(Doctor).entities.getItemAt(0));
			Assert.assertEquals("Doctor 1", d1.name);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals("Doctor 1 name changed", em.getRepository(Doctor).entities.getItemAt(0).name);
		}
		
	}
}