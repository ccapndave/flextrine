package tests {
	import flash.events.Event;
	import flash.events.EventDispatcher;
	
	import flexunit.framework.Assert;
	
	import mx.logging.ILogger;
	import mx.logging.Log;
	import mx.rpc.AsyncToken;
	import mx.rpc.events.FaultEvent;
	
	import org.davekeen.flextrine.orm.Configuration;
	import org.davekeen.flextrine.orm.EntityManager;
	import org.davekeen.flextrine.orm.WriteMode;
	import org.davekeen.flextrine.util.ClassUtil;
	import org.flexunit.async.Async;
	import org.flexunit.async.TestResponder;

	/**
	 * ...
	 * @author Dave Keen
	 */
	public class AbstractTest extends EventDispatcher {
		
		protected var em:EntityManager;
		
		/**
		 * Standard flex logger
		 */
		private var log:ILogger = Log.getLogger(ClassUtil.getQualifiedClassNameAsString(this));
		
		public function setUp():void {
			var configuration:Configuration = new Configuration();
			configuration.gateway = "http://multime.localhost/gateway.php?app=testsuite&env=test";
			//configuration.gateway = "http://69.73.131.38/gateway.php?app=testsuite&env=test";
			configuration.service = "FlextrineService";
			configuration.writeMode = WriteMode.PUSH;
			configuration.entityTimeToLive = -1;
			
			em = EntityManager.getInstance();
			em.setConfiguration(configuration);
			
			trace("********" + ClassUtil.getClassAsString(this) + "********");
		}
		
		[After]
		public function tearDown():void {
			em.clear();
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