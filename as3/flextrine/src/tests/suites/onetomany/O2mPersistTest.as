package tests.suites.onetomany {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class O2mPersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var p1:Patient;
		private var p2:Patient;
		
		[Test(async, description = "Basic test that checks persisting o2m associations.")]
		public function o2mPersistTest():void {
			d1 = new Doctor();
			d1.name = "Doctor 1";
			
			p1 = new Patient();
			p1.name = "Patient 1";
			
			p2 = new Patient();
			p2.name = "Patient 2";
			
			d1.patients.addItem(p1);
			d1.patients.addItem(p2);
			
			em.persist(d1);
			em.persist(p1);
			em.persist(p2);
			
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(1).doctor);
			
			// Now flush
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Check that we still have 1 doctor and 2 patients
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			// Check that the association exists between the patients and the doctor
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(1).doctor);
			
			// And the other way around
			Assert.assertStrictlyEquals(p1, em.getRepository(Doctor).entities.getItemAt(0).patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, em.getRepository(Doctor).entities.getItemAt(0).patients.getItemAt(1));
			
			// Now clear the repository and reload just the doctor.  This should pull in the associated patients too.
			em.clear();
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			var doctor:Doctor = e.result as Doctor;
			
			// Check that we have 1 doctor and 2 patients
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			// Check that e.result is that doctor
			Assert.assertStrictlyEquals(em.getRepository(Doctor).entities.getItemAt(0), doctor);
			
			// Check that the associations exist and are the same instances as in the repositories
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(1).doctor);
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(0), doctor.patients.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(1), doctor.patients.getItemAt(1));
			
			// Now add a third patient
			var p3:Patient = new Patient();
			p3.name = "Patient 3";
			
			em.persist(p3);
			
			doctor.patients.addItem(p3);
			
			// Flush the new patient
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// Check that we have 1 doctor and 3 patients
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(3, em.getRepository(Patient).entities.length);
			
			var doctor:Doctor = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			
			// Check that the associations exist between the repostitory items
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(1).doctor);
			Assert.assertStrictlyEquals(doctor, em.getRepository(Patient).entities.getItemAt(2).doctor);
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(0), doctor.patients.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(1), doctor.patients.getItemAt(1));
			Assert.assertStrictlyEquals(em.getRepository(Patient).entities.getItemAt(2), doctor.patients.getItemAt(2));
		}
		
	}

}