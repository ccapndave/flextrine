<?php
namespace tests;

use Doctrine\ORM\EntityManager,
	Doctrine\Common\DataFixtures\Executor\ORMExecutor,
	Doctrine\Common\DataFixtures\Purger\ORMPurger,
	Doctrine\Common\DataFixtures\Loader;

class FlextrineTestCase extends \PHPUnit_Framework_TestCase {
	
	/**
	 * @var EntityManager
	 */
	protected $em;
	
	public function setUp() {
		// This is super slow
		/*$tool = new \Doctrine\ORM\Tools\SchemaTool($this->em);
		$tool->dropSchema($this->em->getMetadataFactory()->getAllMetadata());
		$tool->createSchema($this->em->getMetadataFactory()->getAllMetadata());*/
		
		/*$conn = $this->em->getConnection();

		foreach ($conn->getSchemaManager()->listTableNames() as $tableName)
			$conn->executeUpdate("DELETE FROM $tableName;");*/

		/*if ($fixture)
			$conn->exec(file_get_contents(dirname(__FILE__)."/fixtures/$fixture.sql"));*/
		
		$loader = new Loader();
		$loader->loadFromDirectory(APP_PATH.DIRECTORY_SEPARATOR."fixtures");

		$purger = new ORMPurger();
		$executor = new ORMExecutor($this->em, $purger);
		$executor->execute($loader->getFixtures());
	}
	
	protected function getService($service) {
		$options = \Zend_Registry::get("appConfig");
		require_once(APP_PATH."/".$options['directories']['services']."/".$service.".php");
		return new $service();
	}
	
	protected function getPersonByEmail($email) {
		$user = $this->em->getRepository('uk\co\multime\vo\User')->findBy(array("email" => $email));
		return $user->getPerson();
	}
	
	public function __construct() {
		$this->em = \Zend_Registry::get("em");
	}
	
}