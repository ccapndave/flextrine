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
	public class PersistPersistTest extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			useFixture(null);
		}
		
		[Test(async, description = "Persisting multiple times should only leave 1 operation in the unit of work.")]
		public function persistPersistTest():void {
			var d1:Doctor = new Doctor();
			
			em.persist(d1);
			em.persist(d1);
			em.persist(d1);
			em.persist(d1);
			
			Assert.assertEquals(1, em.getUnitOfWork().size());
		}
		
	}
}