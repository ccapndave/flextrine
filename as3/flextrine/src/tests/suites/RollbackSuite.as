package tests.suites {
	import tests.suites.rollback.*;

	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class RollbackSuite {
		
		public var rollbackUpdateTest:RollbackUpdateTest;
		public var rollbackPersistTest:RollbackPersistTest;
		public var rollbackRemoveTest:RollbackRemoveTest;
		
	}

}