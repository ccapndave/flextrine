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
	public class RemoveRemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "Removing multiple times should only leave 1 operation in the unit of work.")]
		public function removeRemoveTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			var d1:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			
			em.remove(d1);
			em.remove(d1);
			em.remove(d1);
			em.remove(d1);
			
			Assert.assertEquals(1, em.getUnitOfWork().size());
		}
		
	}
}