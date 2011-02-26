package tests.suites.issues {
	import flash.events.Event;
	import flexunit.framework.Assert;
	import tests.vo.issues.DoctorIssue10;
	import mx.collections.ArrayCollection;
	import mx.rpc.AsyncResponder;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.utils.ObjectUtil;
	import org.davekeen.flextrine.orm.EntityRepository;
	import org.davekeen.flextrine.orm.FetchMode;
	import org.davekeen.flextrine.orm.FlextrineError;
	import org.davekeen.flextrine.util.EntityUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;
	import tests.AbstractTest;
	import tests.vo.garden.*
	import tests.vo.*
	
	/**
	 * ...
	 * @author Dave Keen
	 */
	public class Issue10Test extends AbstractTest {
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
		}
		
		[Test(async, description = "Test that id fields don't need to be named 'id'.")]
		public function idFieldNameTest():void {
			var doctorIssue10:DoctorIssue10 = new DoctorIssue10();
			doctorIssue10.name = "New doctor";
			em.persist(doctorIssue10);
			
			em.flush().addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			Assert.assertEquals(1, em.getRepository(DoctorIssue10).entities.length);
			Assert.assertEquals(1, em.getRepository(DoctorIssue10).entities.getItemAt(0).identifier);
		}
		
	}

}