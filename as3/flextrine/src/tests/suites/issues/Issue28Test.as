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
	public class Issue28Test extends AbstractTest {
		
		private var m:Movie;
		private var a:Artist;
		
		[Before(async)]
		override public function setUp():void {
			super.setUp();
			
			useFixture(null);
		}
		
		[Test(async, description = "Test that lazy loading empty many/many associations does not throw an error")]
		public function nullManyManyTest():void {
			em.getRepository(Movie).load(1).addResponder(Async.asyncResponder(this, new TestResponder(result1, remoteFault), 5000));
		}
		
		private function result1(e:ResultEvent, token:AsyncToken):void {
			
		}
		
	}

}