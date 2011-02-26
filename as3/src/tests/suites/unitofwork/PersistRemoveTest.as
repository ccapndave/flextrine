package tests.suites.unitofwork {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class PersistRemoveTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture("doctors1");
		}
		
		[Test(async, description = "Test what happens when changed objects are persisted and then removed.")]
		public function persistRemoveTest():void {
			var d1:Doctor = new Doctor();
			
			em.persist(d1);
			em.remove(d1);
			
			Assert.assertEquals(0, em.getUnitOfWork().size());
		}
		
	}
}