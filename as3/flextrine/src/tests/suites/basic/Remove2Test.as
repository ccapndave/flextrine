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
	public class Remove2Test extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Tests removing multiple items, mainly checking that ids are received.")]
		public function remove2Test():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			var p1:Patient = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			var p2:Patient = em.getRepository(Patient).entities.getItemAt(1) as Patient;
			var d1:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			em.remove(p1);
			em.remove(p2);
			em.remove(d1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			//Assert.assertStrictlyEquals(0, em.getRepository(Doctor).entities.length);
		}
		
	}
}