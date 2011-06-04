package tests.suites {
	import tests.suites.manytomany.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ManyToManySuite {
		
		public var m2mMultiLoadTest:M2mMultiLoadTest;
		public var m2mPersistTest:M2mPersistTest;
		public var m2mUpdateTest:M2mUpdateTest;
		public var m2mAddRemoveTest:M2mAddRemoveTest;
		
	}

}