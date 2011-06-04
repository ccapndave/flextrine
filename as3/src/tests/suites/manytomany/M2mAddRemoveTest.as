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
	public class M2mAddRemoveTest extends AbstractTest {
		
		private var m:Movie;
		private var a1:Artist;
		private var a2:Artist;
		private var a3:Artist;
		private var a4:Artist;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("moviesandartists2");
		}
		
		[Test(async, description = "Basic test that checks updating m2m associations.")]
		public function m2mAddRemoveTest():void {
			em.load(Movie, 1).addResponder(Async.asyncResponder(this, new TestResponder(result1_1, remoteFault), 5000));
		}
		
		private function result1_1(e:ResultEvent, token:AsyncToken):void {
			m = e.result as Movie;
			
			em.getRepository(Artist).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result1_2, remoteFault), 5000));
		}
		
		private function result1_2(e:ResultEvent, token:AsyncToken):void {
			a1 = e.result[0] as Artist;
			a2 = e.result[1] as Artist;
			a3 = e.result[2] as Artist;
			a4 = e.result[3] as Artist;
		}
		
	}

}