package tests.suites.manytoone {
	import flash.events.Event;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.Query;
	import org.davekeen.flextrine.util.QueryUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	
	import tests.AbstractTest;
	import tests.vo.*;
	import tests.vo.garden.*;
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class M2oLoadTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("countriesandstudents1");
		}
		
		[Test(async, description = "Basic test that checks loading uni-directional m2o associations.")]
		public function m2oLoadTest():void {
			em.select(new Query("SELECT s FROM " + QueryUtil.getDQLClass(Student) + " s WHERE s.id=1 OR s.id=2")).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			// Check that everything was loaded correctly.  This should only load one of the countries in the db.
			Assert.assertEquals(2, em.getRepository(Student).entities.length);
			Assert.assertEquals(1, em.getRepository(Country).entities.length);
			
			// Check the associations
			Assert.assertStrictlyEquals(em.getRepository(Country).find(1), em.getRepository(Student).find(1).country);
			Assert.assertStrictlyEquals(em.getRepository(Country).find(1), em.getRepository(Student).find(2).country);
			
			// Load all the countries.  This should *not* load the extra student as the association is uni-directional
			em.getRepository(Country).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result2, remoteFault), 5000));
		}
		
		private function result2(e:ResultEvent, token:AsyncToken):void {
			// The last load should just have loaded one country
			Assert.assertEquals(2, em.getRepository(Student).entities.length);
			Assert.assertEquals(2, em.getRepository(Country).entities.length);
			
			// Load all the countries.  This should *not* load the extra student as the association is uni-directional
			em.getRepository(Student).loadAll().addResponder(Async.asyncResponder(this, new TestResponder(result3, remoteFault), 5000));
		}
		
		private function result3(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(3, em.getRepository(Student).entities.length);
			Assert.assertEquals(2, em.getRepository(Country).entities.length);
		}
		
	}

}