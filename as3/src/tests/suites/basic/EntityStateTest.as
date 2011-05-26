package tests.suites.basic {
	import flash.events.Event;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class EntityStateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		private var doctorRepository:EntityRepository;
		private var d1:Doctor;
		
		[Test(description = "Tests isEntity works (based of metadata).")]
		public function entityTest():void {
			Assert.assertTrue(EntityUtil.isEntity(new Doctor()));
			Assert.assertTrue(EntityUtil.isEntity(new Patient()));
			Assert.assertFalse(EntityUtil.isEntity(new Object()));
			Assert.assertFalse(EntityUtil.isEntity("6"));
			Assert.assertFalse(EntityUtil.isEntity(1002));
		}
		
		[Test(async, description = "Tests entity states are correct for a variety of local and remote operations.")]
		public function entityStateTest():void {
			doctorRepository = em.getRepository(Doctor) as EntityRepository;
			
			d1 = new Doctor();
			d1.name = "Doctor Robert";
			
			Assert.assertEquals(EntityRepository.STATE_NEW, doctorRepository.getEntityState(d1));
			
			em.persist(d1);
			
			Assert.assertEquals(EntityRepository.STATE_MANAGED, doctorRepository.getEntityState(d1));
			
			em.remove(d1);
			
			Assert.assertEquals(EntityRepository.STATE_NEW, doctorRepository.getEntityState(d1));
			
			em.persist(d1);
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 10000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(doctorRepository.entities.getItemAt(0), d1);
			
			Assert.assertEquals(EntityRepository.STATE_MANAGED, doctorRepository.getEntityState(d1));
			
			var doctor:Doctor = doctorRepository.entities.getItemAt(0) as Doctor;
			em.detach(doctor);
			Assert.assertEquals(EntityRepository.STATE_DETACHED, doctorRepository.getEntityState(doctor));
			
			var mergedDoctor:Doctor = em.merge(doctor) as Doctor;
			Assert.assertEquals(EntityRepository.STATE_MANAGED, doctorRepository.getEntityState(mergedDoctor));
			
			em.remove(d1);
			
			Assert.assertEquals(EntityRepository.STATE_REMOVED, doctorRepository.getEntityState(d1));
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 10000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(0, doctorRepository.entities.length);
			
			Assert.assertEquals(EntityRepository.STATE_DETACHED, doctorRepository.getEntityState(d1));
		}
		
	}

}