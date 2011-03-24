package tests.suites.onetomany {
	import flash.events.Event;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class O2mUpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var p1:Patient;
		private var p2:Patient;
		private var p3:Patient;
		private var p4:Patient;
		
		[Test(async, description = "Basic test that checks updating and re-assigning o2m associations.")]
		public function o2mUpdateTest():void {
			// Load all doctors - this will also pull in associated patients
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// First confirm that all the associations were loaded correctly
			Assert.assertEquals(2, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(4, em.getRepository(Patient).entities.length);
			
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			d2 = em.getRepository(Doctor).entities.getItemAt(1) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			p2 = em.getRepository(Patient).entities.getItemAt(1) as Patient;
			p3 = em.getRepository(Patient).entities.getItemAt(2) as Patient;
			p4 = em.getRepository(Patient).entities.getItemAt(3) as Patient;
			
			// Check that the association exists between the patients and the doctor
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(d1, p2.doctor);
			Assert.assertStrictlyEquals(d2, p3.doctor);
			Assert.assertStrictlyEquals(d2, p4.doctor);
			
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, d1.patients.getItemAt(1));
			Assert.assertStrictlyEquals(p3, d2.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p4, d2.patients.getItemAt(1));
			
			// Now remove p3 and p4 from d2's care and pass them into the capable hands of d1
			d2.patients.removeAll();
			d1.patients.addItem(p3); p3.doctor = d1;
			d1.patients.addItem(p4); p4.doctor = d1;
			
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
			
			em.clear();
			em.loadAll(Patient).addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// Check that we have 1 doctor and 4 patients
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(4, em.getRepository(Patient).entities.length);
			
			var doctor:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			
			// Check that the associations exist between the repostitory items
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(1).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(2).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(3).doctor);
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(0), doctor.patients.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(1), doctor.patients.getItemAt(1));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(2), doctor.patients.getItemAt(2));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(3), doctor.patients.getItemAt(3));
		}
		
		[Test(async, description = "Test updating properties in interlinked objects within a single flush.")]
		public function o2mUpdatePropertiesTest():void {
			// Load all doctors - this will also pull in associated patients
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 10000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			
			// Update both the doctor and the patient
			d1.name = "Changed doctor 1 name";
			p1.name = "Changed patient 1 name";
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2_2, remoteFault), 5000));
		}
		
		private function result2_2(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2_3, remoteFault), 5000));
		}
		
		private function result2_3(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			
			Assert.assertEquals("Changed doctor 1 name", d1.name);
			Assert.assertEquals("Changed patient 1 name", p1.name);
		}
		
	}

}