package tests.suites.manytomany {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class M2mUpdateTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("moviesandartists1");
		}
		
		[Test(async, description = "Basic test that checks updating m2m associations.")]
		public function m2mUpdateTest():void {
			em.getRepository(Movie).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			em.getRepository(Artist).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// Check we loaded the expected number of entities
			Assert.assertEquals(3, em.getRepository(Artist).entities.length);
			Assert.assertEquals(2, em.getRepository(Movie).entities.length);
			
			// Add artist 3 to movie 1
			var m1:Movie = em.getRepository(Movie).entities.getItemAt(0) as Movie;
			var a3:Artist = em.getRepository(Artist).entities.getItemAt(2) as Artist;
			
			Assert.assertEquals(2, m1.artists.length);
			Assert.assertEquals(0, a3.movies.length);
			
			// We only need to set one side of the relationship as Flextrine will take care of the symmetry
			m1.artists.addItem(a3);
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			var m1:Movie = em.getRepository(Movie).entities.getItemAt(0) as Movie;
			var a3:Artist = em.getRepository(Artist).entities.getItemAt(2) as Artist;
			
			Assert.assertEquals(3, m1.artists.length);
			Assert.assertEquals(1, a3.movies.length);
			
			Assert.assertStrictlyEquals(a3, m1.artists.getItemAt(2));
			Assert.assertStrictlyEquals(m1, a3.movies.getItemAt(0));
			
			em.clear();
			em.getRepository(Movie).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result4, remoteFault), 5000));
		}
		
		private function result4(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(2, em.getRepository(Movie).entities.length);
			Assert.assertEquals(3, em.getRepository(Artist).entities.length);
			
			var m1:Movie = em.getRepository(Movie).entities.getItemAt(0) as Movie;
			var a3:Artist = em.getRepository(Artist).entities.getItemAt(2) as Artist;
			
			Assert.assertEquals(3, m1.artists.length);
			Assert.assertEquals(1, a3.movies.length);
			
			Assert.assertStrictlyEquals(a3, m1.artists.getItemAt(2));
			Assert.assertStrictlyEquals(m1, a3.movies.getItemAt(0));
		}
		
	}

}