package tests.suites {
	import tests.suites.onetomany.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class OneToManySuite {
		
		public var o2mPersistTest:O2mPersistTest;
		public var o2mUpdateTest:O2mUpdateTest;
		public var o2mRemoveTest:O2mRemoveTest;
		
	}

}