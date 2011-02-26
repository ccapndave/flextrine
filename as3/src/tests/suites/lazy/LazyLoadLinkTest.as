package tests.suites.lazy {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.FlextrineError;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class LazyLoadLinkTest extends AbstractTest {
		
		private var tree:Tree;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test that seperately loading associated entities link themselves up.")]
		public function lazyLoadLinkTest():void {
			em.getRepository(Tree).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			tree = e.result as Tree;
			
			// Check that garden is a stub
			Assert.assertFalse(EntityUtil.isInitialized(tree.garden));
			
			// We know that in the fixture tree 1 is in garden 1.  Load garden 1 seperately
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			var g:Garden = e.result as Garden;
			
			// Check that the tree's garden is now initialized and is this result
			Assert.assertTrue(EntityUtil.isInitialized(g));
			Assert.assertStrictlyEquals(g, tree.garden);
			
			// Since the garden was lazy loaded we would expect its trees collection to be empty as it doesn't know that tree 1 belongs to it
			//Assert.assertEquals(0, g.trees.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(g.trees));
		}
		
	}

}