package tests.suites.server {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class RemoteFlush2Test extends AbstractTest {
		
		public var embed:Array = [ Doctor, Patient ];
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test remote persist.")]
		public function remotePersistPatientsTest():void {
			em.callRemoteFlushMethod("persistPatientsWithLoad").addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 5000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			var p1:Patient = em.getRepository(Patient).find(5) as Patient;
			var p2:Patient = em.getRepository(Patient).find(6) as Patient;
			
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(d1, p2.doctor);
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, d1.patients.getItemAt(1));
		}
		
		[Test(async, description = "Test remote persist.")]
		public function remotePersistDoctorsTest():void {
			em.callRemoteFlushMethod("persistDoctorWithLoad").addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 5000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			var d1:Doctor = em.getRepository(Doctor).find(3) as Doctor;
			var p1:Patient = em.getRepository(Patient).find(1) as Patient;
			var p2:Patient = em.getRepository(Patient).find(2) as Patient;
			
			Assert.assertStrictlyEquals(d1, p1.doctor);
			Assert.assertStrictlyEquals(d1, p2.doctor);
			Assert.assertStrictlyEquals(p1, d1.patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, d1.patients.getItemAt(1));
		}
		
	}

}