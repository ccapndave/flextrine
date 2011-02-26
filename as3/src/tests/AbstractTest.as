package tests {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flexunit.framework.Assert;
	
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	
	import org.davekeen.flextrine.orm.Configuration;
	import org.davekeen.flextrine.orm.EntityManager;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;

	/**
	 * ...
	 * @author Dave Keen
	 */
	public class AbstractTest extends EventDispatcher {
		
		protected var em:EntityManager;
		
		public function setUp():void {
			var configuration:Configuration = new Configuration();
			//configuration.gateway = "http://localhost./testsuite/gateway.php";
			configuration.gateway = "http://multime.localhost/gateway.php?app=testsuite";
			configuration.service = "FlextrineService";
			
			em = EntityManager.getInstance();
			em.setConfiguration(configuration);
			em.clear();
			
			trace("********" + ClassUtil.getClassAsString(this) + "********");
		}
		
		protected function useFixture(fixture:String, timeout:uint = 10000):void {
			em.callRemoteMethod("useFixture", fixture).addResponder(Async.asyncResponder(this, new TestResponder(function():void { dispatchEvent(new Event(Event.COMPLETE)) }, remoteFault), timeout));;
		}
		
		/**
		 * The fault handler for everything in the test.
		 * 
		 * @param	e
		 * @param	token
		 */
		protected function remoteFault(e:FaultEvent = null, token:AsyncToken = null):void {
			Assert.fail("Fault: " + e.message);
		}
		
	}

}