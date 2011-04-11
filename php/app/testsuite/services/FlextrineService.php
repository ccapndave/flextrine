<?php
/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 *
 * This file is part of Flextrine.
 *
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the Lesser GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * Lesser GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 *
 */

use Doctrine\Common\DataFixtures\Purger\ORMPurger,
	tests\vo;

class FlextrineService extends \Flextrine\AbstractFlextrineService {
	
	/** Add custom functions that you want to call remotely from Flextrine using EntityManager.callRemoteMethod here.
	 *  See http://code.google.com/p/flextrine2/wiki/CustomPHPFunctions for details.
	 */
	
	public function useFixture($fixture) {
		/*$purger = new ORMPurger($this->em);
		$purger->purge();

		$conn = $this->em->getConnection();
		foreach ($conn->getSchemaManager()->listTableNames() as $tableName)
			$conn->executeUpdate("ALTER TABLE $tableName AUTO_INCREMENT = 1");

		if ($fixture)
			$conn->exec(file_get_contents(dirname(__FILE__)."/fixtures/$fixture.sql"));*/
		
		// TODO: Very occasionally this doesn't clear the database, I'm not totally sure why.  M2oLoadTest specifically seems to have this problem.
		$conn = $this->em->getConnection();

		$conn->executeUpdate("SET FOREIGN_KEY_CHECKS=0");

		foreach ($conn->getSchemaManager()->listTableNames() as $tableName)
			$conn->executeUpdate("ALTER TABLE $tableName DISABLE KEYS;
								  TRUNCATE $tableName;
								  ALTER TABLE $tableName AUTO_INCREMENT = 1;");

		if ($fixture)
			$conn->exec(file_get_contents(dirname(__FILE__)."/fixtures/$fixture.sql"));

		$conn->executeUpdate("SET FOREIGN_KEY_CHECKS=1");
		
		/*$conn = $this->em->getConnection();
		
		$tempFile = tempnam(sys_get_temp_dir(), 'flextrine');
		
		$passwordOption = ($conn->getPassword() == "") ? "" : "-p".$conn->getPassword();
		
		exec("mysqldump -u".$conn->getUsername()." ".$passwordOption." --databases ".$conn->getDatabase()." -d > ".$tempFile);
		exec("mysql -u".$conn->getUsername()." ".$passwordOption." -e DROP DATABASE ".$conn->getDatabase());
		exec("mysql -u".$conn->getUsername()." ".$passwordOption." < ".$tempFile);
		
		if ($fixture)
			exec("mysql -u".$conn->getUsername()." ".$passwordOption." < ".dirname(__FILE__)."/fixtures/$fixture.sql");*/
		
		/*$tool = new \Doctrine\ORM\Tools\SchemaTool($this->em);
		$tool->dropSchema($this->em->getMetadataFactory()->getAllMetadata());
		$tool->createSchema($this->em->getMetadataFactory()->getAllMetadata());
		$conn = $this->em->getConnection();
		if ($fixture)
			$conn->exec(file_get_contents(dirname(__FILE__)."/fixtures/$fixture.sql"));*/
	}
	
	public function persistDoctors() {
		$d1 = new vo\Doctor();
		$d1->setName("Doctor 1");
		$this->em->persist($d1);
		
		return $this->flush();
	}
	
	public function persistDoctorsAndPatients() {
		$d1 = new vo\Doctor();
		$d1->setName("Doctor 1");
		
		$p1 = new vo\Patient();
		$p1->setName("Patient 1");
		
		$p2 = new vo\Patient();
		$p2->setName("Patient 2");
		
		$d1->addPatient($p1); $p1->setDoctor($d1);
		$d1->addPatient($p2); $p2->setDoctor($d1);
		
		$this->em->persist($d1);
		$this->em->persist($p1);
		$this->em->persist($p2);
		
		return $this->flush();
	}
	
	public function persistPatientsWithLoad() {
		$d1 = $this->em->getReference('tests\vo\Doctor', 1);
		
		$p1 = new vo\Patient();
		$p1->setName("Patient 1");
		$d1->addPatient($p1); $p1->setDoctor($d1);
		
		$p2 = new vo\Patient();
		$p2->setName("Patient 2");
		$d1->addPatient($p2); $p2->setDoctor($d1);
		
		$this->em->persist($p1);
		$this->em->persist($p2);
		
		return $this->flush();
	}
	
	public function persistDoctorWithLoad() {
		$p1 = $this->em->getReference('tests\vo\Patient', 1);
		$p2 = $this->em->getReference('tests\vo\Patient', 2);
		
		$d1 = new vo\Doctor();
		$d1->setName("Doctor 1");
		
		$d1->addPatient($p1); $p1->setDoctor($d1);
		$d1->addPatient($p2); $p2->setDoctor($d1);
		
		$this->em->persist($d1);
		
		return $this->flush();
	}
	
	public function persistReference() {
		$tree1 = $this->em->getReference('tests\vo\garden\Tree', 1);
		
		$newTree = new tests\vo\garden\Tree();
		$newTree->setType("NewTree");
		$newTree->setGarden($tree1->getGarden());
		
		$this->em->persist($newTree);
		
		return $this->flush();
	}
	
	public function remoteRemove() {
		$p1 = $this->em->getReference('tests\vo\Patient', 1);
		
		$this->em->remove($p1);
		
		return $this->flush();
	}
	
}