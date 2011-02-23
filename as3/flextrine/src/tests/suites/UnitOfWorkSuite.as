package tests.suites {
	import tests.suites.unitofwork.*;
	/**
	 * ...
	 * @author Dave Keen
	 */
	
	[Suite]
	[RunWith("org.flexunit.runners.Suite")]
	public class UnitOfWorkSuite {
		
		public var removeUpdateTest:RemoveUpdateTest;
		public var updateRemoveTest:UpdateRemoveTest;
		public var persistRemoveTest:PersistRemoveTest;
		public var persistPersistTest:PersistPersistTest;
		public var removeRemoveTest:RemoveRemoveTest;
		public var existingPersistTest:ExistingPersistTest;
		
	}

}