package tests.suites {
	import tests.suites.lazy.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class LazySuite {
		
		public var lazyLoadTest:LazyLoadTest;
		public var lazyLoadLinkTest:LazyLoadLinkTest;
		public var lazyRequireOneTest:LazyRequireOneTest;
		public var lazyRequireManyManyTest:LazyRequireManyManyTest;
		public var lazyRequireManyMultipleTest:LazyRequireManyMultipleTest;
		public var lazyCollectionTest:LazyCollectionTest;
		public var lazyEntityTest:LazyEntityTest;
		
	}

}