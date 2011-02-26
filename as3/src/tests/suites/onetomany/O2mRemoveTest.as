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
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class O2mRemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients2");
		}
		
		private var d1:Doctor;
		private var d2:Doctor;
		private var p1:Patient;
		private var p2:Patient;
		private var p3:Patient;
		private var p4:Patient;
		
		[Test(async, description = "Basic test that checks removing o2m associations.")]
		public function o2mRemoveTest():void {
			// Load all doctors - this will also pull in associated patients
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			p2 = em.getRepository(Patient).entities.getItemAt(1) as Patient;
			p3 = em.getRepository(Patient).entities.getItemAt(2) as Patient;
			p4 = em.getRepository(Patient).entities.getItemAt(3) as Patient;
			
			// In this fixture all patients belong to d1.  Remove them all.  Flextrine will maintain symmetry and set .doctor on the patients to null.
			d1.patients.removeAll();
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).entities.getItemAt(0) as Doctor;
			p1 = em.getRepository(Patient).entities.getItemAt(0) as Patient;
			p2 = em.getRepository(Patient).entities.getItemAt(1) as Patient;
			p3 = em.getRepository(Patient).entities.getItemAt(2) as Patient;
			p4 = em.getRepository(Patient).entities.getItemAt(3) as Patient;
			
			Assert.assertEquals(0, d1.patients.length);
			Assert.assertNull(p1.doctor);
			Assert.assertNull(p2.doctor);
			Assert.assertNull(p3.doctor);
			Assert.assertNull(p4.doctor);
			
			em.clear();
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 10000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// Check that we have 1 doctor and 0 patients
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(0, em.getRepository(Patient).entities.length);
		}
		
	}

}