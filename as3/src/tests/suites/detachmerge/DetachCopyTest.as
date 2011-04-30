package tests.suites.detachmerge {
	import flexunit.framework.Assert;
	
	import mx.collections.errors.ItemPendingError;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
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
	public class DetachCopyTest extends AbstractTest {
		
		private var embed:Array = [ Doctor, Patient ];
		
		private var d1Copy:Doctor;
		private var d1:Doctor;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test basic detach copy")]
		public function detachCopyTest():void {
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 10000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			var d1:Doctor = e.result as Doctor;
			
			var d1Copy:Doctor = em.detachCopy(d1) as Doctor;
			
			Assert.assertFalse(d1 === d1Copy);
			Assert.assertEquals(EntityRepository.STATE_MANAGED, em.getRepository(Doctor).getEntityState(d1));
			Assert.assertEquals(EntityRepository.STATE_DETACHED, em.getRepository(Doctor).getEntityState(d1Copy));
		}
		
		[Test(async, description = "Test on demand loading with detach copy")]
		public function detachCopyOnDemandTest():void {
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 10000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			d1 = e.result as Doctor;
			
			d1Copy = em.detachCopy(d1) as Doctor;
			
			Assert.assertFalse(EntityUtil.isCollectionInitialized(d1Copy.patients));
			
			try {
				trace(d1Copy.patients.length);
				Assert.fail("Calling length on an uninitialized collection did not throw an ItemPendingError");
			} catch (e:ItemPendingError) {
				e.addResponder(Async.asyncResponder(this, new TestResponder(result2_2, remoteFault), 8000))
			}
		}
		
		private function result2_2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertTrue(EntityUtil.isCollectionInitialized(d1Copy.patients));
			Assert.assertFalse(EntityUtil.isCollectionInitialized(d1.patients));
			Assert.assertFalse(d1 === d1Copy);
			Assert.assertTrue(e.result === d1Copy);
			Assert.assertEquals(2, d1Copy.patients.length);
		}
		
	}

}