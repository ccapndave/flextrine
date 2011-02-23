package tests.suites.basic {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class UpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var d3:Doctor;
		
		[Test(async, description = "Very basic test that checks that property updates are caught and flushed.")]
		public function updateTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(3, em.getRepository(Doctor).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d1.name = "Doctor 1 name changed";
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals("Doctor 1 name changed", em.getRepository(Doctor).entities.getItemAt(0).name);
			
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d2 = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			d3 = em.getRepository(Doctor).entities.getItemAt(2) as Doctor;
			
			Assert.assertEquals("Doctor 1 name changed", d1.name);
			
			d1.name = "Doctor 1 name changed back";
			d2.name = "Doctor 2 name changed";
			d3.name = "Doctor 3 name changed";
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 10000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(d1, em.getRepository(Doctor).entities.getItemAt(0));
			Assert.assertStrictlyEquals(d2, em.getRepository(Doctor).entities.getItemAt(1));
			Assert.assertStrictlyEquals(d3, em.getRepository(Doctor).entities.getItemAt(2));
			
			Assert.assertEquals("Doctor 1 name changed back", em.getRepository(Doctor).entities.getItemAt(0).name);
			Assert.assertEquals("Doctor 2 name changed", em.getRepository(Doctor).entities.getItemAt(1).name);
			Assert.assertEquals("Doctor 3 name changed", em.getRepository(Doctor).entities.getItemAt(2).name);
			
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result5, remoteFault), 10000));
		}
		
		private function result5(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals("Doctor 1 name changed back", em.getRepository(Doctor).entities.getItemAt(0).name);
			Assert.assertEquals("Doctor 2 name changed", em.getRepository(Doctor).entities.getItemAt(1).name);
			Assert.assertEquals("Doctor 3 name changed", em.getRepository(Doctor).entities.getItemAt(2).name);
		}
		
	}
}