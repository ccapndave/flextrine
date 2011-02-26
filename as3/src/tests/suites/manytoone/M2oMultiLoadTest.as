package tests.suites.manytoone {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.util.QueryUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class M2oMultiLoadTest extends AbstractTest {
		
		private var mark:Mark;
		private var course:Course;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("complexstudents1");
		}
		
		[Test(async, description = "Basic test that checks loading uni-directional m2o associations.")]
		public function m2oMultiLoadTest():void {
			em.getRepository(Student).loadAll();
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			
		}
		
	}

}