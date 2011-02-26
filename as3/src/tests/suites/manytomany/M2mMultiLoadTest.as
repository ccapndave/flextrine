package tests.suites.manytomany {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class M2mMultiLoadTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("moviesandartists1");
		}
		
		[Test(async, description = "Basic test that checks loading two sets of m2m merges them into the repositories correctly.")]
		public function m2mMultiLoadTest():void {
			// First do a multiload test
			em.getRepository(Movie).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			em.getRepository(Artist).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// Check that all the entities and associations are correct
			Assert.assertEquals(2, em.getRepository(Movie).find(1).artists.length);
			Assert.assertEquals(2, em.getRepository(Movie).find(2).artists.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(1).movies.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(2).movies.length);
			
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(1), em.getRepository(Movie).find(1).artists.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(2), em.getRepository(Movie).find(1).artists.getItemAt(1));
			
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(1), em.getRepository(Artist).find(1).movies.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(2), em.getRepository(Artist).find(1).movies.getItemAt(1));
			
			em.clear();
			em.getRepository(Artist).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			// Check that all the entities and associations are correct
			Assert.assertEquals(2, em.getRepository(Movie).find(1).artists.length);
			Assert.assertEquals(2, em.getRepository(Movie).find(2).artists.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(1).movies.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(2).movies.length);
			
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(1), em.getRepository(Movie).find(1).artists.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(2), em.getRepository(Movie).find(1).artists.getItemAt(1));
			
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(1), em.getRepository(Artist).find(1).movies.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(2), em.getRepository(Artist).find(1).movies.getItemAt(1));
			
			em.clear();
			em.getRepository(Movie).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 5000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			// Check that all the entities and associations are correct
			Assert.assertEquals(2, em.getRepository(Movie).find(1).artists.length);
			Assert.assertEquals(2, em.getRepository(Movie).find(2).artists.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(1).movies.length);
			Assert.assertEquals(2, em.getRepository(Artist).find(2).movies.length);
			
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(1), em.getRepository(Movie).find(1).artists.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Artist).find(2), em.getRepository(Movie).find(1).artists.getItemAt(1));
			
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(1), em.getRepository(Artist).find(1).movies.getItemAt(0));
			Assert.assertStrictlyEquals(em.getRepository(Movie).find(2), em.getRepository(Artist).find(1).movies.getItemAt(1));
		}
		
	}

}