<?php
/**
 * Copyright (C) 2012 Dave Keen http://www.actionscriptdeveloper.co.uk
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
 * of the Software, and to permit persons to whom the Software is furnished to do
 * so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
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
	
	protected $serializationWalker;
	
	protected $deserializationWalker;
	
	const EAGER = "eager";
	const LAZY = "lazy";
	
	function __construct() {
		// Each time the constructor is called we create a new EntityManager (a cheap operation) otherwise we run into problems with concurrent AMF requests.
		$this->em = Zend_Registry::get("entityManagerFactory")->create();
		Zend_Registry::set("em", $this->em);
		
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
	protected function flextrinize($entityOrArray) {
		return $this->serializationWalker->walk($entityOrArray, $this->em);
	}
	
	private function setFetchMode($fetchMode) {
		foreach ($this->em->getMetadataFactory()->getAllMetadata() as $metadata) {
			foreach ($metadata->associationMappings as $key => $associationMapping)
				if ($fetchMode == self::EAGER)
					$metadata->associationMappings[$key]["fetch"] = ClassMetadataInfo::FETCH_EAGER;
			
			$this->em->getMetadataFactory()->setMetaDataFor($metadata->name, clone $metadata);
		}
	}
	
	public function load($entityClass, $id, $fetchMode) {
		$this->setFetchMode($fetchMode);

		return $this->flextrinize($this->em->getRepository($entityClass)->find($id));
	}
	
	public function loadAll($entityClass, $fetchMode) {
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findAll());
	}
	
	public function loadBy($entityClass, $criteria, $fetchMode) {
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findBy((array)$criteria));
	}
	
	public function loadOneBy($entityClass, $criteria, $fetchMode) {
		$this->setFetchMode($fetchMode);
		
		return $this->flextrinize($this->em->getRepository($entityClass)->findOneBy((array)$criteria));
	}
	
	public function select($flextrineQuery, $firstIdx, $lastIdx, $fetchMode) {
		$this->setFetchMode($fetchMode);
		
		$usePaging = ($lastIdx > 0);
		
		$query = $this->createFlextrineQuery($flextrineQuery);
		
		if ($usePaging) {
			$query->setFirstResult($firstIdx);
			$query->setMaxResults($lastIdx - $firstIdx);
		}
		
		$result = $query->getResult($flextrineQuery->hydrationMode);
		
		if ($usePaging) {
			// Use a regular expression to make a new COUNT query in order to get the total number of rows (without paging)
			$countDQL = preg_replace('/SELECT (DISTINCT )?.*? FROM (\S*) (\S*)(.*)/i', "SELECT COUNT(\${1}\${3}) FROM \${2} \${3} \${4}", $query->getDQL());
			$countQuery = $this->em->createQuery($countDQL);
			$countQuery->setParameters($query->getParameters());
			$count = $countQuery->getSingleScalarResult();
			
			// When using paging we need to return both the result and the total number of rows.
			return array("results" => ($flextrineQuery->hydrationMode == \Doctrine\ORM\Query::HYDRATE_OBJECT) ? $this->flextrinize($result) : $result, "count" => $count);
		} else {
			return ($flextrineQuery->hydrationMode == \Doctrine\ORM\Query::HYDRATE_OBJECT) ? $this->flextrinize($result) : $result;
		}
	}
	
	public function selectOne($query, $fetchMode) {
		$this->setFetchMode($fetchMode);
		
		$result = $this->createFlextrineQuery($query)->getResult();
		
		return (sizeof($result) > 0) ? $this->flextrinize($result[0]) : null;
	}
	
	private function createFlextrineQuery($flextrineQuery) {
		if (preg_match('/^\S*$/', $flextrineQuery->dql)) {
			// This is a remote method, with the query generated by a PHP method in the service
			$methodName = "query_".$flextrineQuery->dql;
			$query = $this->$methodName($flextrineQuery->params);
		} else {
			// The DQL was passed from the client
			$query = $this->em->createQuery($flextrineQuery->dql);
			
			// Insert any parameters
			if ($flextrineQuery->params) {
				$paramsArray = (array)$flextrineQuery->params;
				foreach ($paramsArray as $name => $value) {
					$query->setParameter($name, $value);
				}
			}
		}
		
		// Only SELECT queries are allowed
		if (substr(strtoupper($query->getDQL()), 0, 7) != "SELECT ")
			throw new \Exception("You may only use the SELECT operator ".$query->getDQL());
		
		return $query;
	}
	
	public function flush($remoteOperations = null, $fetchMode = null) {
		// Start the transaction
		$this->em->getConnection()->beginTransaction();
		try {
			// Perform the flush
			$flushExecutor = new FlushExecutor($this->em, $remoteOperations, $this->deserializationWalker);
			$changeSets = $flushExecutor->flush();
			
			// Go through the elements in the change sets making the entities Flextrine ready (apart from temporaryUidMap and entityDeletionIdMap which are not entities)
			if ($fetchMode) $this->setFetchMode($fetchMode);
			foreach ($changeSets as $changeSetType => $changeSet)
				if ($changeSetType != "temporaryUidMap" && $changeSetType != "entityDeletionIdMap")
					foreach ($changeSet as $oid => $entity)
						$changeSet[$oid] = $this->flextrinize($entity);
			
			// Commit the transaction
			$this->em->getConnection()->commit();
			
			// Return the change sets so they can be replicated in Flextrine
			return $changeSets;
		} catch (\Exception $e) {
    		$this->em->getConnection()->rollback();
			$this->em->close();
			throw $e;
		}
	}
	
	protected function runCustomOperation($operation, $data) {
		
	}
	
}