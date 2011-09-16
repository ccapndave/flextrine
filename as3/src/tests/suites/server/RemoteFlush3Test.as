package tests.suites.server {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class RemoteFlush3Test extends AbstractTest {
		
		public var embed:Array = [ Garden, Tree, Branch, Leaf ];
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("garden1");
		}
		
		[Test(async, description = "Test remote references.")]
		public function remotePersistReferenceTest():void {
			em.callRemoteFlushMethod("persistReference").addResponder(Async.asyncResponder(this, new TestResponder(result3_1, remoteFault), 5000));
		}
		
		private function result3_1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Garden).entities.length);
			Assert.assertEquals(1, em.getRepository(Tree).entities.length);
			
			var g:Garden = em.getRepository(Garden).entities.getItemAt(0) as Garden;
			var t:Tree = em.getRepository(Tree).entities.getItemAt(0) as Tree;
			
			Assert.assertFalse(EntityUtil.isInitialized(g));
			Assert.assertStrictlyEquals(g, t.garden);
		}
		
	}

}