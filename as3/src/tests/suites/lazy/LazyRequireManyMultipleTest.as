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
	public class LazyRequireManyMultipleTest extends AbstractTest {
		
		private var l:Leaf;
		private var b:Branch;
		private var tree:Tree;
		private var g:Garden;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test requiring of lazy collections.")]
		public function lazyRequireManyMultipleTest():void {
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			g = e.result as Garden;
			
			// Check that the branches is an uninitialized collection
			Assert.assertTrue(g.trees is PersistentCollection);
			//Assert.assertEquals(0, g.trees.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.trees));
			
			// Check that the flowers is an uninitialized collection
			Assert.assertTrue(g.flowers is PersistentCollection);
			//Assert.assertEquals(0, g.flowers.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.flowers));
			
			// Now requireMany on the trees
			em.requireMany(g, "trees").addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(g, e.result);
			
			// At this point we would expect garden.trees to be initialized and there to be 5 elements in the tree repository
			Assert.assertTrue(EntityUtil.isCollectionInitialized(g.trees));
			Assert.assertEquals(5, g.trees.length);
			
			// And they should all be the same objects as in the repository
			Assert.assertStrictlyEquals(g, em.getRepository(Garden).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.trees.getItemAt(0), em.getRepository(Tree).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.trees.getItemAt(1), em.getRepository(Tree).entities.getItemAt(1));
			Assert.assertStrictlyEquals(g.trees.getItemAt(2), em.getRepository(Tree).entities.getItemAt(2));
			Assert.assertStrictlyEquals(g.trees.getItemAt(3), em.getRepository(Tree).entities.getItemAt(3));
			Assert.assertStrictlyEquals(g.trees.getItemAt(4), em.getRepository(Tree).entities.getItemAt(4));
			
			// ... but there should still be no flowers
			Assert.assertTrue(g.flowers is PersistentCollection);
			//Assert.assertEquals(0, g.flowers.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.flowers));
			
			// Now requireMany on the flowers
			em.requireMany(g, "flowers").addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(g, e.result);
			
			// At this point we would expect garden.trees to still be initialized with 5 elements in the tree repository
			Assert.assertTrue(EntityUtil.isCollectionInitialized(g.trees));
			Assert.assertEquals(5, g.trees.length);
			
			// And they should all be the same objects as in the repository
			Assert.assertStrictlyEquals(g, em.getRepository(Garden).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.trees.getItemAt(0), em.getRepository(Tree).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.trees.getItemAt(1), em.getRepository(Tree).entities.getItemAt(1));
			Assert.assertStrictlyEquals(g.trees.getItemAt(2), em.getRepository(Tree).entities.getItemAt(2));
			Assert.assertStrictlyEquals(g.trees.getItemAt(3), em.getRepository(Tree).entities.getItemAt(3));
			Assert.assertStrictlyEquals(g.trees.getItemAt(4), em.getRepository(Tree).entities.getItemAt(4));
			
			Assert.assertStrictlyEquals(g, e.result);
			
			// This time garden.flowers should be initialized too and there to be 5 elements in the flower repository
			Assert.assertTrue(EntityUtil.isCollectionInitialized(g.flowers));
			Assert.assertEquals(5, g.flowers.length);
			
			// And they should all be the same objects as in the repository
			Assert.assertStrictlyEquals(g, em.getRepository(Garden).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.flowers.getItemAt(0), em.getRepository(Flower).entities.getItemAt(0));
			Assert.assertStrictlyEquals(g.flowers.getItemAt(1), em.getRepository(Flower).entities.getItemAt(1));
			Assert.assertStrictlyEquals(g.flowers.getItemAt(2), em.getRepository(Flower).entities.getItemAt(2));
			Assert.assertStrictlyEquals(g.flowers.getItemAt(3), em.getRepository(Flower).entities.getItemAt(3));
			Assert.assertStrictlyEquals(g.flowers.getItemAt(4), em.getRepository(Flower).entities.getItemAt(4));
		}
	}

}