package tests.suites.detachmerge {
	import flexunit.framework.Assert;
	
	import mx.collections.errors.ItemPendingError;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
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
	public class DetachCopyMergeTest extends AbstractTest {
		
		private var embed:Array = [ Doctor, Patient ];
		
		private var d1:Doctor;
		private var d1Copy:Doctor;
		private var d2:Doctor;
		private var d2Copy:Doctor;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test detach copy with merge")]
		public function detachCopyMergeTest():void {
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 10000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			d1 = e.result as Doctor;
			
			var d1Copy:Doctor = em.detachCopy(d1) as Doctor;
			
			d1Copy.name = "Changed doctor name";
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
			
			var mergedD1:Doctor = em.merge(d1Copy) as Doctor;
			
			Assert.assertStrictlyEquals(d1, mergedD1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1_2, remoteFault), 10000));
		}
		
		private function result1_2(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1_3, remoteFault), 10000));
		}
		
		private function result1_3(e:ResultEvent, token:AsyncToken):void {
			d1 = e.result as Doctor;
			
			Assert.assertEquals("Changed doctor name", d1.name);
		}
		
		[Test(async, description = "Test on demand loading plus association change merging")]
		public function detachCopyOnDemandMergeTest():void {
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 10000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).find(1) as Doctor;
			d2 = em.getRepository(Doctor).find(2) as Doctor;
			
			d1Copy = em.detachCopy(d1) as Doctor;
			d2Copy = em.detachCopy(d2) as Doctor;
			
			Assert.assertFalse(EntityUtil.isCollectionInitialized(d1Copy.patients));
			
			try {
				trace(d1Copy.patients.length);
				Assert.fail("Calling length on an uninitialized collection did not throw an ItemPendingError");
			} catch (e:ItemPendingError) {
				e.addResponder(Async.asyncResponder(this, new TestResponder(result2_2, remoteFault), 8000))
			}
		}
		
		private function result2_2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertFalse(EntityUtil.isCollectionInitialized(d2Copy.patients));
			
			try {
				trace(d2Copy.patients.length);
				Assert.fail("Calling length on an uninitialized collection did not throw an ItemPendingError");
			} catch (e:ItemPendingError) {
				e.addResponder(Async.asyncResponder(this, new TestResponder(result2_3, remoteFault), 8000))
			}
		}
		
		private function result2_3(e:ResultEvent, token:AsyncToken):void {
			// Move patient 3 from doctor 2 to doctor 1
			var patient3:Patient = d2Copy.patients.getItemAt(0) as Patient;
			d2Copy.patients.removeItem(patient3)
			d1Copy.patients.addItem(patient3);
			
			em.merge(d1Copy);
			em.merge(d2Copy);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2_4, remoteFault), 10000));
		}
		
		private function result2_4(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).loadAll(FetchMode.EAGER).addResponder(Async.asyncResponder(this, new TestResponder(result2_5, remoteFault), 10000));
		}
		
		private function result2_5(e:ResultEvent, token:AsyncToken):void {
			d1 = em.getRepository(Doctor).find(1) as Doctor;
			d2 = em.getRepository(Doctor).find(2) as Doctor;
			
			Assert.assertEquals(3, d1.patients.length);
			Assert.assertEquals(1, d2.patients.length);
		}
		
	}

}