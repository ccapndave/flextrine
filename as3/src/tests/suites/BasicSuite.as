package tests.suites {
	import tests.suites.basic.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class BasicSuite {
		
		public var entityStateTest:EntityStateTest;
		public var clearTest:ClearTest;
		public var persistTest:PersistTest;
		public var removeTest:RemoveTest;
		public var remove2Test:Remove2Test;
		public var updateTest:UpdateTest;
		public var updateChangeTest:UpdateChangeTest;
		
	}

}