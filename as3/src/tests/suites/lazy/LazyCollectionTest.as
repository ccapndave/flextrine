package tests.suites.lazy {
	import flexunit.framework.Assert;
	
	import mx.collections.errors.ItemPendingError;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class LazyCollectionTest extends AbstractTest {
		
		private var g:Garden;
		private var t:Tree;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test that automatic lazy loading of collections works.")]
		public function lazyCollectionTest():void {
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			g = e.result as Garden;
			
			try {
				trace(g.trees.length);
				Assert.fail("Calling length on an uninitialized collection did not throw an ItemPendingError");
			} catch (e:ItemPendingError) {
				e.addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 8000))
			}
			
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertTrue(EntityUtil.isCollectionInitialized(g.trees));
			Assert.assertEquals(5, g.trees.length);
		}
		
	}

}