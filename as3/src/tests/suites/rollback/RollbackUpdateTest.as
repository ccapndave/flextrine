package tests.suites.rollback {
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
	public class RollbackUpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test that property changes can be rolled back.")]
		public function propertyRollbackTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(propertyRollbackTestResult1, remoteFault), 10000));
		}
		
		private function propertyRollbackTestResult1(e:ResultEvent, token:AsyncToken):void {
			// Make some changes
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			var p1:Patient = em.getRepository(Patient).find(1) as Patient;
			
			d1.name = "Doctor 1 name change";
			p1.name = "Patient 1 name change";
			
			// Roll back any changes
			em.rollback();
			
			// Check that the properties have changed back again
			Assert.assertEquals("Doctor 1", d1.name);
			Assert.assertEquals("Patient 1", p1.name);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
		[Test(async, description = "Test that single valued associations can be rolled back.")]
		public function singleAssociationRollbackTest():void {
			em.getRepository(Patient).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(singleAssociationRollbackTestResult1, remoteFault), 10000));
		}
		
		private function singleAssociationRollbackTestResult1(e:ResultEvent, token:AsyncToken):void {
			// Make some changes
			var p1:Patient = em.getRepository(Patient).find(1) as Patient;
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			var d2:Doctor = em.getRepository(Doctor).find(2) as Doctor;
			
			p1.doctor = d2;
			
			// Roll back any changes
			em.rollback();
			
			// Check that the association has changed back again
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
		[Test(async, description = "Test that single valued associations can be rolled back.")]
		public function collectionRollbackTest():void {
			em.getRepository(Patient).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(collectionRollbackTestResult1, remoteFault), 10000));
		}
		
		private function collectionRollbackTestResult1(e:ResultEvent, token:AsyncToken):void {
			// Make some changes
			var p1:Patient = em.getRepository(Patient).find(1) as Patient;
			var p2:Patient = em.getRepository(Patient).find(2) as Patient;
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			var d2:Doctor = em.getRepository(Doctor).find(2) as Doctor;
			
			d2.patients.addItem(p1);
			d2.patients.addItem(p2);
			
			// Roll back any changes
			em.rollback();
			
			// Check that the association has changed back again
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(d1, p2.doctor);
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, d1.patients.getItemAt(1));
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
	}
}