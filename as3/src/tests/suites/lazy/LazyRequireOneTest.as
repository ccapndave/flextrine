package tests.suites.lazy {
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
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
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class LazyRequireOneTest extends AbstractTest {
		
		private var leaf:Leaf;
		private var b:Branch;
		private var t:Tree;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			em.getConfiguration().loadEntitiesOnDemand = false;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test requiring of lazy entities.")]
		public function lazyRequireOneTest():void {
			em.getRepository(Leaf).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			leaf = e.result as Leaf;
			
			// Check that the branch is a stub
			Assert.assertEquals(1, em.getRepository(Branch).entities.length);
			Assert.assertFalse(EntityUtil.isInitialized(em.getRepository(Branch).entities.getItemAt(0)));
			Assert.assertStrictlyEquals(e.result.branch, em.getRepository(Branch).entities.getItemAt(0));
			
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
			
			// Load the stub using require
			em.requireOne(leaf.branch).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// There should still be the same number of branches in the repository
			Assert.assertEquals(1, em.getRepository(Branch).entities.length);
			
			// This time we should be able to access length
			Assert.assertEquals(5000, leaf.branch.length);
			
			// Also check that no new instances have been created (i.e. that the new data has merged into the stuff)
			Assert.assertStrictlyEquals(leaf.branch, em.getRepository(Branch).entities.getItemAt(0));
			
			// The result returned in e.result should be the same instance as that in the repository
			Assert.assertStrictlyEquals(e.result, leaf.branch);
			
			Assert.assertTrue(EntityUtil.isInitialized(em.getRepository(Branch).entities.getItemAt(0)));
			
			// Check that we can't call requireOne on a collection
			var gotError:Boolean = false;
			try {
				em.requireOne(leaf.branch.leaves);
			} catch (e:FlextrineError) {
				if (e.errorID == FlextrineError.ILLEGAL_REQUIRE)
					gotError = true;
			}
			if (!gotError) Assert.fail("Did not get an exception when trying to call requireOne on a many valued association");
			
			// Check that requireOne returns syncronously since the branch is already initialized
			var gotResult:Boolean = false;
			em.requireOne(leaf.branch, function():void {
				gotResult = true;
			} );
			
			if (!gotResult) Assert.fail("requireOne did not return instantly even though the required entity has already been loaded");
		}
		
	}

}