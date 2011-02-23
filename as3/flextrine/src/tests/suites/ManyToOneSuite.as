package tests.suites {
	import tests.suites.manytoone.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class ManyToOneSuite {
		
		public var m2oLoadTest:M2oLoadTest;
		public var m2oMultiLoadTest:M2oMultiLoadTest;
		
	}

}