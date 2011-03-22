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
	public class RollbackPersistTest extends AbstractTest {
		
		[Before]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().enabledRollback = true;
		}
		
		[Test(description = "Test that persisted entities can be rolled back.")]
		public function persistRollbackTest():void {
			var d1:Doctor = new Doctor();
			d1.name = "Doctor 1";
			
			em.persist(d1);
			
			Assert.assertTrue(em.rollback());
			
			Assert.assertEquals(0, em.getRepository(Doctor).entities.length);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
		[Test(description = "Test that persisted and associated entities can be rolled back.")]
		public function persist2RollbackTest():void {
			var d1:Doctor = new Doctor();
			d1.name = "Doctor 1";
			
			var p1:Patient = new Patient();
			p1.name = "Patient 1";
			
			var p2:Patient = new Patient();
			p2.name = "Patient 2";
			
			d1.patients.addItem(p1);
			d1.patients.addItem(p2);
			
			em.persist(d1);
			em.persist(p1);
			em.persist(p2);
			
			var rolledBack:Boolean = em.rollback();
			Assert.assertTrue(rolledBack);
			
			// Somehow this works for the patients but not the doctor
			Assert.assertEquals(0, em.getRepository(Patient).entities.length);
			Assert.assertEquals(0, em.getRepository(Doctor).entities.length);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
	}
}