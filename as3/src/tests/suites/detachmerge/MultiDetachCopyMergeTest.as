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
	public class MultiDetachCopyMergeTest extends AbstractTest {
		
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
			var d1Copy:Doctor = em.detachCopy(d1) as Doctor;
			d1Copy.name = "Changed doctor name again";
			Assert.assertEquals(0, em.getUnitOfWork().size());
			
			var mergedD1:Doctor = em.merge(d1Copy) as Doctor;
			
			Assert.assertStrictlyEquals(d1, mergedD1);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1_3, remoteFault), 10000));
		}
		
		private function result1_3(e:ResultEvent, token:AsyncToken):void {
			em.clear();
			em.getRepository(Doctor).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1_4, remoteFault), 10000));
		}
		
		private function result1_4(e:ResultEvent, token:AsyncToken):void {
			d1 = e.result as Doctor;
			
			Assert.assertEquals("Changed doctor name again", d1.name);
		}
		
	}

}