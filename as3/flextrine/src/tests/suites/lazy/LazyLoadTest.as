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
	public class LazyLoadTest extends AbstractTest {
		
		private var leaf:Leaf;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			em.getConfiguration().loadEntitiesOnDemand = false;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Basic test that checks persisting o2m associations.")]
		public function lazyLoadTest():void {
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Garden is the top level so we would expect only garden 1 to load and nothing else
			Assert.assertEquals(1, em.getRepository(Garden).entities.length);
			Assert.assertEquals(0, em.getRepository(Tree).entities.length);
			Assert.assertEquals(0, em.getRepository(Branch).entities.length);
			Assert.assertEquals(0, em.getRepository(Leaf).entities.length);
			
			// Check e.result is the same instance as in the repository
			Assert.assertStrictlyEquals(e.result, em.getRepository(Garden).entities.getItemAt(0));
			
			// Check that garden.trees is an uninitialized collection
			Assert.assertFalse(EntityUtil.isCollectionInitialized(e.result.trees));
			
			// Now load a leaf
			em.clear();
			em.getRepository(Leaf).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			leaf = e.result as Leaf;
			
			Assert.assertStrictlyEquals(leaf, em.getRepository(Leaf).entities.getItemAt(0));
			
			// Leaf is the bottom level, so the only thing that should load is the leaf and one branch (which will be a stub);
			Assert.assertEquals(0, em.getRepository(Garden).entities.length);
			Assert.assertEquals(0, em.getRepository(Tree).entities.length);
			Assert.assertEquals(1, em.getRepository(Branch).entities.length);
			Assert.assertEquals(1, em.getRepository(Leaf).entities.length);
			
			// Check that the branch is a stub
			Assert.assertFalse(EntityUtil.isInitialized(em.getRepository(Branch).entities.getItemAt(0)));
			Assert.assertStrictlyEquals(leaf.branch, em.getRepository(Branch).entities.getItemAt(0));
			
			// Now try to get a property of the branch - this should throw an exception
			// Unfortunately FlexUnit seems to balk when exceptions are throws as a result of an event and try {} catch {} doesn't work, so can't test this
			/*var gotError:Boolean = false;
			try {
				trace(leaf.branch.length);
			} catch (e:FlextrineError) {
				if (e.errorID == FlextrineError.ACCESSED_UNITIALIZED_ENTITY)
					gotError = true;
			}
			if (!gotError) Assert.fail("Did not get an exception when trying to access property of a stub");*/
		}
		
	}

}