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
	public class PullO2mUpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture("doctorsandpatients1");
			
			em.getConfiguration().writeMode = WriteMode.PULL;
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var p1:Patient;
		private var p2:Patient;
		private var p3:Patient;
		private var p4:Patient;
		
		[Test(async, description = "Very basic test that checks updating and reassigning one to many persists work in pull mode.")]
		public function pullUpdateO2mTest():void {
			// Load all doctors - this will also pull in associated patients
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(2, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(4, em.getRepository(Patient).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d2 = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			p2 = em.getRepository(Patient).entities.getItemAt(1) as Patient;
			p3 = em.getRepository(Patient).entities.getItemAt(2) as Patient;
			p4 = em.getRepository(Patient).entities.getItemAt(3) as Patient;
			
			var detachedD1:Doctor = em.detach(d1) as Doctor;
			var detachedD2:Doctor = em.detach(d2) as Doctor;
			var detachedP3:Patient = em.detach(p3) as Patient;
			var detachedP4:Patient = em.detach(p4) as Patient;
			
			detachedD2.patients.removeAll();
			detachedD1.patients.addItem(detachedP3); detachedP3.doctor = detachedD1;
			detachedD1.patients.addItem(detachedP4); detachedP4.doctor = detachedD1;
			
			em.merge(detachedD1);
			em.merge(detachedD2);
			em.merge(detachedP3);
			em.merge(detachedP4);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(d1, p2.doctor);
			Assert.assertStrictlyEquals(d1, p3.doctor);
			Assert.assertStrictlyEquals(d1, p4.doctor);
			
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, d1.patients.getItemAt(1));
			Assert.assertStrictlyEquals(p3, d1.patients.getItemAt(2));
			Assert.assertStrictlyEquals(p4, d1.patients.getItemAt(3));
		}
		
	}
}