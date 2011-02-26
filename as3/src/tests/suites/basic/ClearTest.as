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
	public class ClearTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var d3:Doctor;
		
		[Test(async, description = "Very basic test that checks that em.clear() works.")]
		public function clearTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d2 = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			d3 = em.getRepository(Doctor).entities.getItemAt(2) as Doctor;
			
			em.clear();
			
			Assert.assertStrictlyEquals(0, em.getRepository(Doctor).entities.length);
			
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(3, em.getRepository(Doctor).entities.length);
			
			Assert.assertFalse(d1 === em.getRepository(Doctor).entities.getItemAt(0));
			Assert.assertFalse(d2 === em.getRepository(Doctor).entities.getItemAt(1));
			Assert.assertFalse(d3 === em.getRepository(Doctor).entities.getItemAt(2));
		}
		
	}
}