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
	public class M2mPersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		private var m1:Movie;
		private var m2:Movie;
		private var a1:Artist;
		private var a2:Artist;
		
		[Test(async, description = "Basic test that checks persisting m2m associations.")]
		public function m2mPersistTest():void {
			m1 = new Movie();
			m1.title = "Movie 1";
			
			m2 = new Movie();
			m2.title = "Movie 2";
			
			a1 = new Artist();
			a1.name = "Artist 1";
			
			a2 = new Artist();
			a2.name = "Artist 2";
			
			// We just need to set one side of the many-many relationship (either side is fine) as Flextrine will take care of the symmetry
			m1.artists.addItem(a1);
			m1.artists.addItem(a2);
			
			m2.artists.addItem(a1);
			m2.artists.addItem(a2);
			
			em.persist(m1);
			em.persist(m2);
			em.persist(a1);
			em.persist(a2);
			
			// Now flush
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Check that we still have 2 movies and 2 artists
			Assert.assertEquals(2, em.getRepository(Movie).entities.length);
			Assert.assertEquals(2, em.getRepository(Artist).entities.length);
			
			// Check that the association exists between the movies and artists
			Assert.assertStrictlyEquals(a1, em.getRepository(Movie).entities.getItemAt(0).artists.getItemAt(0));
			Assert.assertStrictlyEquals(a2, em.getRepository(Movie).entities.getItemAt(0).artists.getItemAt(1));
			
			// And the other way around
			Assert.assertStrictlyEquals(m1, em.getRepository(Artist).entities.getItemAt(0).movies.getItemAt(0));
			Assert.assertStrictlyEquals(m2, em.getRepository(Artist).entities.getItemAt(0).movies.getItemAt(1));
			
			// Now clear the repository and reload the movies (this will pull in the artists too)
			em.clear();
			em.getRepository(Movie).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// Check that we still have 2 movies and 2 artists
			Assert.assertEquals(2, em.getRepository(Movie).entities.length);
			Assert.assertEquals(2, em.getRepository(Artist).entities.length);
			
			m1 = em.getRepository(Movie).entities.getItemAt(0) as Movie;
			m2 = em.getRepository(Movie).entities.getItemAt(1) as Movie;
			a1 = em.getRepository(Artist).entities.getItemAt(0) as Artist;
			a2 = em.getRepository(Artist).entities.getItemAt(1) as Artist;
			
			// Check that the association exists between the movies and artists
			Assert.assertStrictlyEquals(a1, em.getRepository(Movie).entities.getItemAt(0).artists.getItemAt(0));
			Assert.assertStrictlyEquals(a2, em.getRepository(Movie).entities.getItemAt(0).artists.getItemAt(1));
			
			// And the other way around
			Assert.assertStrictlyEquals(m1, em.getRepository(Artist).entities.getItemAt(0).movies.getItemAt(0));
			Assert.assertStrictlyEquals(m2, em.getRepository(Artist).entities.getItemAt(0).movies.getItemAt(1));
		}
		
	}

}