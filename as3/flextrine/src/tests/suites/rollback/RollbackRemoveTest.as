package tests.suites.rollback {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class RollbackRemoveTest extends AbstractTest {
		
		private static var embedClass:Array = [ Patient ];
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture("doctorsandpatients1");
			
			em.getConfiguration().enabledRollback = true;
		}
		
		[Test(async, description = "Test that removed entities can be rolled back.")]
		public function removeRollbackTest():void {
			em.getRepository(Doctor).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(removeRollbackTestResult1, remoteFault), 10000));
		}
		
		public function removeRollbackTestResult1(e:ResultEvent, token:AsyncToken):void {
			var d1:Doctor = em.getRepository(Doctor).find(1) as Doctor;
			
			em.remove(d1);
			
			em.rollback();
			
			Assert.assertEquals(2, em.getRepository(Doctor).entities.length);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
	}
}