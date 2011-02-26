package tests.suites.unitofwork {
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
	public class UpdateRemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "Test what happens when changed objects are removed before flushing.")]
		public function updateTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			var d1:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d1.name = "Doctor 1 name changed";
			
			Assert.assertEquals(1, em.getUnitOfWork().size());
			
			em.remove(d1);
			
			// Removing the entity should negate its merge and there should still be only 1 entry in the unit of work (just the remove)
			Assert.assertEquals(1, em.getUnitOfWork().size());
		}
		
	}
}