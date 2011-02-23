<?php
/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 * 
 * This file is part of Flextrine.
 * 
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 * 
 */

namespace Flextrine;

use Doctrine\ORM\Events,
	Flextrine\Internal\FlushExecutor,
	Flextrine\Internal\AS3EntityGenerator,
	Doctrine\ORM\Mapping\ClassMetadataInfo,
	Doctrine\ORM\Query\ResultSetMapping,
	Zend_Registry,
	Zend_Acl;

abstract class AbstractFlextrineService {

	/**
	 * @var Doctrine\ORM\EntityManager
	 */
	protected $em;
	
	protected $acl;

	protected $flextrineManagerEnabled = true;

	protected $serializationWalker;
	
	protected $deserializationWalker;
	
	const EAGER = "eager";
	const LAZY = "lazy";
	
	function __construct() {
		// Retrieve the EntityManager from the Zend_Registry.  This will have been already set in bootstrap.php
		$this->em = Zend_Registry::get("em");
		
		// Construct the Acl instance if it has been registered
		if (Zend_Registry::isRegistered("acl"))
			$this->acl = Zend_Registry::get("acl");
		
		// Construct the serialization and deserialization walkers
		$this->serializationWalker = new Internal\Walkers\SerializerWalker($this->em, $this->acl, $this->getLoggedInRole());
		$this->deserializationWalker = new Internal\Walkers\DeserializerWalker($this->em, $this->acl, $this->getLoggedInRole());
	}
	
	protected function getLoggedInRole() {
		return null;
	}

	/**
	 * All Doctrine entities or array of entities need to be run through this method before anything is returned to Flextrine.
	 *
	 * @param <type> $entityOrArray
	 * @return <type>
	 */
	private function flextrinize($entityOrArray) {
		return $this->serializationWalker->walk($entityOrArray, $this->em);
	}

	private function setFetchMode($fetchMode) {
		foreach ($this->em->getMetadataFactory()->getAllMetadata() as $metadata) {
			foreach ($metadata->associationMappings as $key => $associationMapping) {
				if ($fetchMode == self::EAGER) {
					$metadata->associationMappings[$key]["fetch"] = ClassMetadataInfo::FETCH_EAGER;
				}
			}
		}
	}
	
	/**
	 * At present I need to call em->clear() before each request, because if AMFPHP queues up multiple requests at once for some reason having something
	 * in the em breaks the next request's class mapping.
	 */
	
	public function load($entityClass, $id, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);

		return $this->flextrinize($this->em->getRepository($entityClass)->find($id));
	}
	
	public function loadAll($entityClass, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findAll());
	}
	
	public function loadBy($entityClass, $criteria, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findBy((array)$criteria));
	}
	
	public function loadOneBy($entityClass, $criteria, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findOneBy((array)$criteria));
	}
	
	public function select($flextrineQuery, $firstIdx, $lastIdx, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);
		
		$usePaging = ($lastIdx > 0);
		
		$query = $flextrineQuery->createQuery($this->em);
		
		if ($usePaging) {
			$query->setFirstResult($firstIdx);
			$query->setMaxResults($lastIdx - $firstIdx);
		}
		
		$result = $query->getResult();
		
		if ($usePaging) {
			// Use a regular expression to turn the query into a COUNT query in order to get the total number of rows without the paging
			$flextrineQuery->dql = preg_replace('/SELECT .*? FROM (\S*) (\S*)(.*)/i', "SELECT COUNT(\${2}) FROM \${1} \${2} \${3}", $flextrineQuery->dql);
			$query = $flextrineQuery->createQuery($this->em);
			$count = $query->getSingleScalarResult();
			
			// When using paging we need to return both the result and the total number of rows.
			return array("results" => $this->flextrinize($result), "count" => $count);
		} else {
			return $this->flextrinize($result);
		}
	}
	
	public function selectOne($query, $fetchMode) {
		$this->em->clear();
		$this->setFetchMode($fetchMode);
		
		$result = $query->createQuery($this->em)->getResult();
		
		return (sizeof($result) > 0) ? $this->flextrinize($result[0]) : null;
	}
	
	public function flush($remoteOperations, $fetchMode) {
		$this->em->clear();
		
		// Perform the flush
		$flushExecutor = new FlushExecutor($this->em, $remoteOperations, $this->deserializationWalker);
		$changeSets = $flushExecutor->flush();
		
		// Go through the elements in the change sets making the entities Flextrine ready (apart from temporaryUidMap and entityDeletionIdMap which are not entities)
		$this->setFetchMode($fetchMode);
		foreach ($changeSets as $changeSetType => $changeSet)
			if ($changeSetType != "temporaryUidMap" && $changeSetType != "entityDeletionIdMap")
				foreach ($changeSet as $oid => $entity)
					$this->flextrinize($entity);
		
		// Return the change sets so they can be replicated in Flextrine
		return $changeSets;
	}
	
	protected function runCustomOperation($operation, $data) {
		
	}
	
	/**
	 * The following functions are for use by the Flextrine Manager.  They are only accessible if $flextrineManagerEnabled is true.
	 */
	public function getFlextrineManagerData() {
		if (!$this->isFlextrineManagerEnabled())
			throw new \Exception("Flextrine manager access is not enabled");
			
		return array("dbname" => $this->em->getConnection()->getDatabase(),
					 "entities" => $this->getSchemaEntities());
	}
	
	public function generateAS3Entities() {
		if (!$this->isFlextrineManagerEnabled())
			throw new \Exception("Flextrine manager access is not enabled");
		
		$as3EntityGenerator = new AS3EntityGenerator($this->em);
		return $as3EntityGenerator->generate($this->getEntityClassesMetaData());
	}
	
	public function createSchema() {
		if (!$this->isFlextrineManagerEnabled())
			throw new \Exception("Flextrine manager access is not enabled");
			
		$tool = new \Doctrine\ORM\Tools\SchemaTool($this->em);
		$tool->createSchema($this->getEntityClassesMetaData());
	}
	
	public function updateSchema() {
		if (!$this->isFlextrineManagerEnabled())
			throw new \Exception("Flextrine manager access is not enabled");
			
		$tool = new \Doctrine\ORM\Tools\SchemaTool($this->em);
		$tool->updateSchema($this->getEntityClassesMetaData());
	}
	
	public function dropSchema() {
		if (!$this->isFlextrineManagerEnabled())
			throw new \Exception("Flextrine manager access is not enabled");
			
		$tool = new \Doctrine\ORM\Tools\SchemaTool($this->em);
		$tool->dropSchema($this->getEntityClassesMetaData());
	}
	
	/**
	 * This function returns an array of strings with the fully qualified class of each entity.  The $entitiesPath parameter is no longer used
	 * but will be left in for a little while to maintain backwards compatibility with projects created in Flextrine 0.6.1 and earlier.
	 */
	protected function getSchemaEntities($entitiesPath = null) {
		$entities = array();
		
		foreach ($this->em->getMetadataFactory()->getAllMetadata() as $metadata)
			$entities[] = $metadata->name;
		
		return $entities;
	}
	 
	private function getEntityClassesMetaData() {
		return $this->em->getMetadataFactory()->getAllMetadata();
	}

	private function isFlextrineManagerEnabled() {
		if (Zend_Registry::isRegistered("appConfig")) {
			$appConfig = Zend_Registry::get("appConfig");
			return (isset($appConfig["flextrineManagerEnabled"]) && $appConfig["flextrineManagerEnabled"] == true);
		} else {
			return false;
		}
	}
	
}