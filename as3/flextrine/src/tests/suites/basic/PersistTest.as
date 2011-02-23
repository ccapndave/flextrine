package tests.suites.basic {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class PersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var d3:Doctor;
		
		[Test(async, description = "Very basic persist test that checks that entities persist and reload.")]
		public function persistTest():void {
			d1 = new Doctor();
			d1.name = "Doctor 1";
			
			Assert.assertNull(d1.id);
			
			em.persist(d1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertStrictlyEquals(d1, em.getRepository(Doctor).entities.getItemAt(0));
			
			Assert.assertEquals(1, d1.id);
			
			em.clear();
			
			// Since we cleared the repository in the last step d1 will not the same object as what will come back from load so set to null to avoid confusion
			d1 = null;
			
			Assert.assertStrictlyEquals(0, em.getRepository(Doctor).entities.length);
			
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			
			d2 = new Doctor();
			d2.name = "Doctor 2";
			d3 = new Doctor();
			d3.name = "Doctor 3";
			
			Assert.assertNull(d2.id);
			Assert.assertNull(d3.id);
			
			em.persist(d2);
			em.persist(d3);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(3, em.getRepository(Doctor).entities.length);
			Assert.assertStrictlyEquals(d2, em.getRepository(Doctor).entities.getItemAt(1));
			Assert.assertStrictlyEquals(d3, em.getRepository(Doctor).entities.getItemAt(2));
			
			Assert.assertEquals("Doctor 1", em.getRepository(Doctor).entities.getItemAt(0).name);
			Assert.assertEquals("Doctor 2", em.getRepository(Doctor).entities.getItemAt(1).name);
			Assert.assertEquals("Doctor 3", em.getRepository(Doctor).entities.getItemAt(2).name);
		}
		
	}

}