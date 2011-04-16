package tests.suites {
	import tests.suites.server.*;
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ServerSuite {
		public var test1:RemoteFlushTest;
		public var test2:RemoteFlush2Test;
		public var test3:RemoteFlush3Test;
		public var test4:RemoteFlush4Test;
	}
}