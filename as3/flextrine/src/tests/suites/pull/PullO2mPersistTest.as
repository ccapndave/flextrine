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
	public class PullO2mPersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
			
			em.getConfiguration().writeMode = WriteMode.PULL;
		}
		
		private var d1:Doctor;
		private var p1:Patient;
		private var p2:Patient;
		
		[Test(async, description = "Very basic test that checks that one to many persists work in pull mode.")]
		public function persistO2mTest():void {
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
			
			// Check that this hasn't added anything to the repository
			Assert.assertEquals(0, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(0, em.getRepository(Patient).entities.length);
			
			// Flush
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			// Check that the association exists between the patients and the doctor
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(0).doctor);
			Assert.assertStrictlyEquals(d1, em.getRepository(Patient).entities.getItemAt(1).doctor);
			
			// And the other way around
			Assert.assertStrictlyEquals(p1, em.getRepository(Doctor).entities.getItemAt(0).patients.getItemAt(0));
			Assert.assertStrictlyEquals(p2, em.getRepository(Doctor).entities.getItemAt(0).patients.getItemAt(1));
		}
		
	}
}