package tests.suites.detachmerge {
	import flexunit.framework.Assert;
	
	import mx.collections.errors.ItemPendingError;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class DetachCopyOnDemandMergeTest extends AbstractTest {
		
		private var embed:Array = [ Doctor, Patient ];
		
		private var d1:Doctor;
		private var d1Copy:Doctor;
		private var p1:Patient;
		private var p1Copy:Patient;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().entityTimeToLive = 5000;
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test detach copy with on demand collection loading followed by a merge")]
		public function detachCopyOnDemandCollectionMergeTest():void {
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 10000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			d1 = e.result as Doctor;
			
			// Make a detached copy
			d1Copy = em.detachCopy(d1) as Doctor;
			
			// Trigger on demand loading on the detached copy
			try {
				trace(d1Copy.patients.length);
				Assert.fail("Calling length on an uninitialized detached copy collection did not throw an ItemPendingError");
			} catch (ipe:ItemPendingError) {
				ipe.addResponder(Async.asyncResponder(this, new TestResponder(result1_2, remoteFault), 8000))
			}
		}
		
		private function result1_2(e:ResultEvent, token:AsyncToken):void {
			// Merge the copy back into the repository; nothing should have changed!
			em.merge(d1Copy);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
		[Test(async, description = "Test detach copy with on demand entity loading followed by a merge")]
		public function detachCopyOnDemandEntityMergeTest():void {
			em.getRepository(Patient).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 10000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			p1 = e.result as Patient;
			
			// Make a detached copy
			p1Copy = em.detachCopy(p1) as Patient;
			
			// Fake on demand loading of the name (as we can't attach a listener to it)
			em.requireOne(p1Copy.doctor).addResponder(Async.asyncResponder(this, new TestResponder(result2_2, remoteFault), 8000))
		}
		
		private function result2_2(e:ResultEvent, token:AsyncToken):void {
			p1Copy.name = "THIS IS THE DETACHED PATIENT!";
			
			// Merge the copy back into the repository; nothing should have changed!
			em.merge(p1Copy);
			
			Assert.assertEquals(1, em.getUnitOfWork().size());
			
			// Save it
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2_3, remoteFault), 8000))
		}
		
		private function result2_3(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Patient).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2_4, remoteFault), 10000));
		}
		
		private function result2_4(e:ResultEvent, token:AsyncToken):void {
			p1 = e.result as Patient;
			Assert.assertEquals("THIS IS THE DETACHED PATIENT!", p1.name);
		}
		
	}

}