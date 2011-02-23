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
	public class RemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "Very basic remove test that checks that entities get removed properly.")]
		public function removeTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			var d2:Doctor = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			em.remove(d2);
			
			Assert.assertStrictlyEquals(2, em.getRepository(Doctor).entities.length);
			
			Assert.assertEquals(1, em.getRepository(Doctor).entities.getItemAt(0).id);
			Assert.assertEquals("Doctor 1", em.getRepository(Doctor).entities.getItemAt(0).name);
			
			Assert.assertEquals(3, em.getRepository(Doctor).entities.getItemAt(1).id);
			Assert.assertEquals("Doctor 3", em.getRepository(Doctor).entities.getItemAt(1).name);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(2, em.getRepository(Doctor).entities.length);
			
			Assert.assertEquals(1, em.getRepository(Doctor).entities.getItemAt(0).id);
			Assert.assertEquals("Doctor 1", em.getRepository(Doctor).entities.getItemAt(0).name);
			
			Assert.assertEquals(3, em.getRepository(Doctor).entities.getItemAt(1).id);
			Assert.assertEquals("Doctor 3", em.getRepository(Doctor).entities.getItemAt(1).name);
			
			var d1:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			var d3:Doctor = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			em.remove(d1);
			em.remove(d3);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(0, em.getRepository(Doctor).entities.length);
		}
		
	}
}