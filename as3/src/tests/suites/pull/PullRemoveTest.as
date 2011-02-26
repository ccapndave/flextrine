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
	public class PullRemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture("doctors1");
			
			em.getConfiguration().writeMode = WriteMode.PULL;
		}
		
		private var d1:Doctor;
		
		[Test(async, description = "Very basic test that checks that persists work in pull mode.")]
		public function removeTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Remove doctor 1
			d1 = em.getRepository(Doctor).find(1) as Doctor;
			
			em.remove(d1);
			
			// Confirm the doctor is still in the repository
			Assert.assertEquals(3, em.getRepository(Doctor).entities.length);
			
			// Flush the remove
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// Now the entity should have actually been removed from the repository
			Assert.assertEquals(2, em.getRepository(Doctor).entities.length);
		}
		
	}
}