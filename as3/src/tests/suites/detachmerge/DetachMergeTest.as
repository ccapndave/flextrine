package tests.suites.detachmerge {
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
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class DetachMergeTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		[Test(async, description = "Test basic detaching and merging of entities")]
		public function detachMergeTest():void {
			var d1:Doctor = new Doctor();
			d1.name = "Doctor 1";
			em.persist(d1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// Check there is one entity in the repo
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			
			var doctor:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			
			// Now detach the entity
			em.detach(doctor);
			
			// Check the doctor has been removed from the repository
			Assert.assertEquals(0, em.getRepository(Doctor).entities.length);
			
			// Make some changes to detachedDoctor
			doctor.name = "Changed name";
			
			// Check that this didn't trigger a merge in the unitOfWork
			Assert.assertEquals(0, em.getUnitOfWork().size());
			
			// Now merge detachedDoctor back into the entity manager
			var mergedDoctor:Doctor = em.merge(doctor) as Doctor;
			
			// Check that this is the same instance as the original doctor
			Assert.assertStrictlyEquals(doctor, mergedDoctor);
			
			// Also check that a merge was triggered in the unitOfWork
			Assert.assertEquals(1, em.getUnitOfWork().size());
			
			em.clear();
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			var doctor:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			
			// Now detach the entity
			em.detach(doctor);
			
			// This time we won't actually make a change
			doctor.name = "Doctor 1";
			
			// Now merge detachedDoctor back into the entity manager
			var mergedDoctor:Doctor = em.merge(doctor) as Doctor;
			
			// The current implementation of detach merge lets Doctrine worry about what has changed.  Do a flush(), but expect no db changes.
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 10000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			var changes:Object = e.result;
			
			Assert.assertEquals(0, changes.persists.length);
			Assert.assertEquals(0, changes.removes.length);
			Assert.assertEquals(0, changes.updates.length);
		}
		
	}

}