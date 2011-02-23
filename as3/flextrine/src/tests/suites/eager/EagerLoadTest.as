package tests.suites.eager {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.garden.Branch;
	import tests.vo.garden.Flower;
	import tests.vo.garden.Garden;
	import tests.vo.garden.Leaf;
	import tests.vo.garden.Tree;

	public class EagerLoadTest extends AbstractTest {		
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("garden1");
		}
		
		[Test(async, description = "Test eager loading of associations.")]
		public function eagerLoadTest():void {
			// This should load everything in garden 1
			em.getConfiguration().fetchMode = FetchMode.EAGER;
			em.getRepository(Garden).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Garden).entities.length);
			Assert.assertEquals(5, em.getRepository(Flower).entities.length);
			Assert.assertEquals(5, em.getRepository(Tree).entities.length);
			Assert.assertEquals(25, em.getRepository(Branch).entities.length);
			Assert.assertEquals(125, em.getRepository(Leaf).entities.length);
			
			em.clear();
			
			// This time load tree 1.  Eager loading should have the same effect.
			em.getRepository(Tree).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Garden).entities.length);
			Assert.assertEquals(5, em.getRepository(Flower).entities.length);
			Assert.assertEquals(5, em.getRepository(Tree).entities.length);
			Assert.assertEquals(25, em.getRepository(Branch).entities.length);
			Assert.assertEquals(125, em.getRepository(Leaf).entities.length);
			
			em.clear();
			
			// Finally load leaf 1.  Eager loading should once again have the same effect.
			em.getRepository(Leaf).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 5000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(Garden).entities.length);
			Assert.assertEquals(5, em.getRepository(Flower).entities.length);
			Assert.assertEquals(5, em.getRepository(Tree).entities.length);
			Assert.assertEquals(25, em.getRepository(Branch).entities.length);
			Assert.assertEquals(125, em.getRepository(Leaf).entities.length);
		}
		
	}
}