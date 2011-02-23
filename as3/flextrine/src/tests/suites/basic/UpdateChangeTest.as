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
	public class UpdateChangeTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		private var d1:Doctor;
		
		[Test(async, description = "Very basic test that checks that only real changes trigger updates.")]
		public function updateChangeTest():void {
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(1, em.getRepository(Doctor).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			
			// This is the name that the doctor already has
			d1.name = "Doctor 1";
			
			// Check that Flextrine has realised that the name hasn't actually changed and the unit of work is still empty
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
	}
}