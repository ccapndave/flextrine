package tests.suites {
	import tests.suites.detachmerge.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class DetachMergeSuite {
		
		public var test1:DetachMergeTest;
		public var test2:O2mDetachMergeTest;
		public var test3:DetachCopyTest;
		public var test4:DetachCopyMergeTest;
		public var test5:O2oDetachMergeTest;
		public var test6:MultiDetachCopyMergeTest;
		public var test7:DetachCopyOnDemandMergeTest;
		
	}

}