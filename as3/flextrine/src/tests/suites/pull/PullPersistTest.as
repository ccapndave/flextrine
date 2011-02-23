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
	public class PullPersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
			
			em.getConfiguration().writeMode = WriteMode.PULL;
		}
		
		private var d1:Doctor;
		
		[Test(async, description = "Very basic test that checks that persists work in pull mode.")]
		public function persistTest():void {
			d1 = new Doctor();
			d1.name = "Doctor 1";
			em.persist(d1);
			
			// Check that this hasn't added anything to the repository
			Assert.assertEquals(0, em.getRepository(Doctor).entities.length);
			
			// Flush
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			
			// This doesn't work, but it definitely should...
			Assert.assertStrictlyEquals(d1, em.getRepository(Doctor).entities.getItemAt(0));
		}
		
	}
}