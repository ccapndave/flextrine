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

use Doctrine\Common\DataFixtures\Purger\ORMPurger;

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
	}
	
}