package tests.suites.basic {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class LoadResultTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "This tests that values returned in load result objects are the same instances as the one in the repository.")]
		public function loadResultTest():void {
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// This is going to be the same since doctor 1 isn't in the repository so the returned entity is actually put in
			Assert.assertStrictlyEquals(e.result, em.getRepository(Doctor).entities.getItemAt(0));
			
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// In this case doctor 1 is in the repository and the returned entity is merged with it.  In this case Flextrine needs to make sure that e.result
			// reflects the object in the repository, not the object that was returned.
			Assert.assertStrictlyEquals(e.result, em.getRepository(Doctor).entities.getItemAt(0));
		}
		
	}
}