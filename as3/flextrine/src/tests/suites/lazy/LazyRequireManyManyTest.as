package tests.suites.lazy {
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.FetchMode;
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
	public class LazyRequireManyManyTest extends AbstractTest {
		
		private var m:Movie;
		private var a:Artist;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			em.getConfiguration().fetchMode = FetchMode.LAZY;
			
			useFixture("moviesandartists1");
		}
		
		[Test(async, description = "Test requiring of lazy many to many collections.")]
		public function lazyRequireManyManyTest():void {
			em.getRepository(Movie).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			m = e.result as Movie;
			
			// Check that the artists is an uninitialized collection
			Assert.assertTrue(m.artists is PersistentCollection);
			//Assert.assertEquals(0, m.artists.length);
			Assert.assertFalse(EntityUtil.isCollectionInitialized(m.artists));
			
			// Now requireMany on the artists
			em.requireMany(m, "artists").addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			Assert.assertStrictlyEquals(m, e.result);
			
			// At this point we would expect m.artists to be initialized and there to be 2 elements in the artists repository
			Assert.assertTrue(EntityUtil.isCollectionInitialized(m.artists));
			Assert.assertEquals(2, m.artists.length);
			
			// And they should all be the same objects as in the repository
			Assert.assertStrictlyEquals(m, em.getRepository(Movie).entities.getItemAt(0));
			Assert.assertStrictlyEquals(m.artists.getItemAt(0), em.getRepository(Artist).entities.getItemAt(0));
			Assert.assertStrictlyEquals(m.artists.getItemAt(1), em.getRepository(Artist).entities.getItemAt(1));
			
			// Check that requireMany returns syncronously since the artists are already initialized
			var gotResult:Boolean = false;
			em.requireMany(m, "artists", function():void {
				gotResult = true;
			} );
			
			if (!gotResult) Assert.fail("requireMany did not return instantly even though the required collection has already been loaded");
		}
		
	}

}