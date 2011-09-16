package tests.suites {
	import tests.suites.pull.*;
	import tests.suites.pull.PullUpdateTest;

	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class PullSuite {
		public var pullUpdateTest:PullUpdateTest;
		public var pullPersistTest:PullPersistTest;
		public var pullRemoveTest:PullRemoveTest;
		public var pullO2mPersistTest:PullO2mPersistTest;
		public var pullO2mUpdateTest:PullO2mUpdateTest;
		
	}

}