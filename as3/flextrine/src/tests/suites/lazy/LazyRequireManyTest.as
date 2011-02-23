package tests.suites.lazy {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.FlextrineError;
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
	public class LazyRequireManyTest extends AbstractTest {
		
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
		public function lazyRequireManyTest():void {
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			g = e.result as Garden;
			
			// Check that the trees is an uninitialized collection
			Assert.assertTrue(g.trees is PersistentCollection);
			//Assert.assertEquals(0, g.trees.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.trees));
			
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
			
			// Check that we can't call requireMany on a non collection
			var gotError:Boolean = false;
			try {
				em.requireMany(g.trees.getItemAt(0), "garden");
			} catch (e:FlextrineError) {
				if (e.errorID == FlextrineError.ILLEGAL_REQUIRE)
					gotError = true;
			}
			if (!gotError) Assert.fail("Did not get an exception when trying to call requireMany on a single valued association");
			
			// Check that requireMany returns syncronously since the trees are already initialized
			var gotResult:Boolean = false;
			em.requireMany(g, "trees", function():void {
				gotResult = true;
			} );
			
			if (!gotResult) Assert.fail("requireMany did not return instantly even though the required collection has already been loaded");
			
		}
		
	}

}