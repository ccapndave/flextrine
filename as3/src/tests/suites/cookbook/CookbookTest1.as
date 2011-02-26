package tests.suites.cookbook {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.collections.ArrayCollection;
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
	import tests.vo.cookbook.garden.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class CookbookTest1 extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
		}
		
		private var garden1:Garden;
		private var garden2:Garden;
		private var tree1:Tree;
		private var tree2:Tree;
		
		[Test(async, description = "Test the cookboox examples")]
		public function cookbookTest1():void {
			garden1 = new Garden();
			garden1.name = "My front lawn";
			garden1.area = 20;

			/*garden2 = new Garden();
			garden2.name = "My back lawn";
			garden2.area = 40;*/
			
			em.persist(garden1);
			//em.persist(garden2);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			tree1 = new Tree();
			tree1.name = "Pine";
			tree1.age = 75;
			tree1.isFlowering = true;
			
			tree2 = new Tree();
			tree2.name = "Oak";
			tree2.age = 30;
			tree2.isFlowering = false;

			// Add the trees to the garden.  Flextrine will take care of maintaining the bi-directional relationship
			garden1.trees.addItem(tree1);
			garden1.trees.addItem(tree2);
			
			em.persist(tree1);
			em.persist(tree2);

			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			
		}
		
	}

}