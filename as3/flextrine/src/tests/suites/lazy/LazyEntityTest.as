package tests.suites.lazy {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.events.EntityEvent;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class LazyEntityTest extends AbstractTest {
		
		private var g:Garden;
		private var t:Tree;
		
		private var entityEvent:EntityEvent;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("garden1");
		}
		
		[Test(async, description = "Test that automatic lazy loading of entities works.")]
		public function lazyEntityTest():void {
			em.getRepository(Tree).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			t = e.result as Tree;
			
			Assert.assertFalse(EntityUtil.isInitialized(t.garden));
			
			t.garden.addEventListener(EntityEvent.INITIALIZE_ENTITY, Async.asyncHandler(this, result2, 500, null, remoteFault));
			t.garden.name;
		}
		
		private function result2(e:EntityEvent, passThroughData:Object):void {
			// Keep a reference to the EntityEvent otherwise it gets garbage collected and the test ends here
			entityEvent = e;
			
			e.itemPendingError.addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}

		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertTrue(EntityUtil.isInitialized(t.garden));
		}
		
	}

}