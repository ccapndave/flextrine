package tests.suites.server {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.Doctor;
	import tests.vo.Patient;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class RemoteFlush4Test extends AbstractTest {
		
		public var embed:Array = [ Doctor, Patient ];
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctorsandpatients1");
		}
		
		[Test(async, description = "Test remote removals.")]
		public function remoteRemovalTest():void {
			em.callRemoteFlushMethod("remoteRemove").addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 5000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(0, em.getRepository(Patient).entities.length);
		}
		
		[Test(async, description = "Test that remote removes also remove entities from the local repository.")]
		public function remoteRemovalRepositoryTest():void {
			// First load stuff
			em.load(Doctor, 1, FetchMode.EAGER).addResponder(Async.asyncResponder(this, new TestResponder(result2_1, remoteFault), 5000));
		}
		
		private function result2_1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(2, em.getRepository(Patient).entities.length);
			
			em.callRemoteFlushMethod("remoteRemove").addResponder(Async.asyncResponder(this, new TestResponder(result2_2, remoteFault), 5000));
		}
		
		private function result2_2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Doctor).entities.length);
			Assert.assertEquals(1, em.getRepository(Patient).entities.length);
			
			// Check that only patient 2 is left
			Assert.assertEquals(2, em.getRepository(Patient).entities.getItemAt(0).id);
		}
		
	}

}