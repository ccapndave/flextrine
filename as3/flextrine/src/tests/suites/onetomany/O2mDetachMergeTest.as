package tests.suites.onetomany {
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
	public class O2mDetachMergeTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Basic test that checks detaching and merging entities with o2m associations.")]
		public function o2mDetachMergeTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			var doctor:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			
			// Detach the doctor
			var detachedDoctor:Doctor = em.detach(doctor) as Doctor;
			
			// Check that the doctor and all assocated patients are detached
			Assert.assertFalse(detachedDoctor === doctor);
			Assert.assertFalse(detachedDoctor.patients.getItemAt(0) === em.getRepository(Patient).find(detachedDoctor.patients.getItemAt(0).id));
			Assert.assertFalse(detachedDoctor.patients.getItemAt(1) === em.getRepository(Patient).find(detachedDoctor.patients.getItemAt(1).id));
			
			// Check that the detached patients still refer to the detached doctor
			Assert.assertStrictlyEquals(detachedDoctor, detachedDoctor.patients.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(detachedDoctor, detachedDoctor.patients.getItemAt(1).doctor);
			
			// Check that changes to the detached patients don't trigger an update
			detachedDoctor.patients.getItemAt(0).name = "Changed patient 1";
			detachedDoctor.patients.getItemAt(1).name = "Changed patient 2";
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
			
			// Now merge the doctor back into the repository
			var mergedDoctor:Doctor = em.merge(detachedDoctor) as Doctor;
			
			// We should have an update on the two patients and the doctor.  In fact it could be argued that there should only be two
			// updates - need to look into this at some point.
			//Assert.assertEquals(3, em.getUnitOfWork().size());
			
			// Check that the merged doctor associations are the same instances as the original doctor
			Assert.assertStrictlyEquals(mergedDoctor, doctor);
			Assert.assertStrictlyEquals(mergedDoctor.patients.getItemAt(0), doctor.patients.getItemAt(0));
			Assert.assertStrictlyEquals(mergedDoctor.patients.getItemAt(1), doctor.patients.getItemAt(1));
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// Check the changes were saved correctly
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			Assert.assertEquals("Changed patient 1", d1.patients.getItemAt(0).name);
			Assert.assertEquals("Changed patient 2", d1.patients.getItemAt(1).name);
			
			// Now we need to check that moving objects between associations works
			var d2:Doctor = em.getRepository(Doctor).find(2) as Doctor;
			
			var detachedDoctor1:Doctor = em.detach(d1) as Doctor;
			var detachedDoctor2:Doctor = em.detach(d2) as Doctor;
			
			// NOTE: This presupposes cascade merge; I'm not actually sure that this should work
			
			// Move a patient from doc 2 to doc 1
			var detachedPatient3:Patient = detachedDoctor2.patients.getItemAt(0) as Patient;
			detachedPatient3.doctor = detachedDoctor1;
			detachedDoctor2.patients.removeItemAt(detachedDoctor2.patients.getItemIndex(detachedPatient3));
			detachedDoctor1.patients.addItem(detachedPatient3);
			
			// Nothing should have been put in the unit of work so far
			Assert.assertEquals(0, em.getUnitOfWork().size());
			
			trace("**************");
			
			// Merge the entities into Flextrine
			var mergedDoctor1:Doctor = em.merge(detachedDoctor1) as Doctor;
			var mergedDoctor2:Doctor = em.merge(detachedDoctor2) as Doctor;
			
			Assert.assertEquals(3, em.getUnitOfWork().size());
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 5000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result5, remoteFault), 5000));
		}
		
		private function result5(e:ResultEvent, token:AsyncToken):void {
			// Check that the associations have changed
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			var d2:Doctor = em.getRepository(Doctor).find(2) as Doctor;
			
			Assert.assertEquals(3, d1.patients.length);
			Assert.assertEquals(1, d2.patients.length);
		}
		
	}

}