package tests.suites.lazy {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.collections.PersistentCollection;
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
	public class LazyFlushTest extends AbstractTest {
		
		private var leaf:Leaf;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test that flushing entities with lazy collections works.")]
		public function lazyFlushTest():void {
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			var g:Garden = e.result as Garden;
			
			g.name = "New garden name";
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			var g:Garden = em.getRepository(Garden).find(1) as Garden;
			
			Assert.assertEquals("New garden name", g.name);
			
			// TODO: This fails because Doctrine initializes collection when there is a cascade merge (because of DDC-758)
			
			// Check that this hasn't caused the associations to load
			Assert.assertTrue(g.trees is PersistentCollection);
			//Assert.assertEquals(0, g.trees.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.trees));
			
			Assert.assertTrue(g.flowers is PersistentCollection);
			//Assert.assertEquals(0, g.flowers.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.flowers));
		}
	}

}