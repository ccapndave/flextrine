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

namespace Flextrine\Internal;

use Doctrine\ORM\Events,
	Doctrine\ORM\Event\OnFlushEventArgs,
	Doctrine\ORM\Mapping\ClassMetadata;

class FlushExecutor {
	
	private $em;

	private $deserializationWalker;
	
	private $changeSets;
	
	private $temporaryUidMap;
	
	private $persistRemoteOperations = array();
	
	private $mergeRemoteOperations = array();
	
	private $removeRemoteOperations = array();
	
	private $originalCascades = array();
	
	function __construct($em, $flushSet, $deserializationWalker) {
		$this->em = $em;

		$this->deserializationWalker = $deserializationWalker;

		// Get the remote operations out of the flushset for each operation type
		foreach ($flushSet->persists as $persistRemoteOperation)
			$this->persistRemoteOperations[] = (object)$persistRemoteOperation;
			
		foreach ($flushSet->merges as $mergeRemoteOperation)
			$this->mergeRemoteOperations[] = (object)$mergeRemoteOperation;
			
		foreach ($flushSet->removes as $removeRemoteOperation)
			$this->removeRemoteOperations[] = (object)$removeRemoteOperation;
		
	}
	
	function __destruct() {
		
	}
	
	public function flush() {
		// Configure the cascade settings for Flextrine
		$this->configureCascadesForFlextrine();
		
		$this->temporaryUidMap = array();
		
		// Add an event listener to hook into the flush and retrieve the changesets
		$this->em->getEventManager()->addEventListener(array(Events::onFlush), $this);
		
		// Persist, merge and remove as required
		$this->doPersists();
		$this->doMerges();
		$this->doRemoves();
		
		try {
			// Perform the flush
			$this->em->flush();
		} catch (Exception $e) {
			throw $e;
		}
		
		// Add any auto-generated ids into the changeset
		$this->doAddPersistedIds();
		
		// Add any deleted ids back into the changeset
		$this->doAddRemovedIds();
		
		// Add the temporary uid map to the changeset so that Flextrine can match up the persisted object with the id-less object in the repository
		$this->changeSets["temporaryUidMap"] = $this->temporaryUidMap;
		
		return $this->changeSets;
	}
	
	private function doPersists() {
		foreach ($this->persistRemoteOperations as $persist) {
			$data = (object)$persist->data;
			
			$data->entity = $this->deserializationWalker->walk($data->entity);
			
			// Persist the entity
			$this->em->persist($data->entity);
			
			// Add a map from the object hash to the temporary uid of the object
			$this->temporaryUidMap[spl_object_hash($data->entity)] = $data->temporaryUid;
		}
	}
	
	private function doMerges() {
		foreach ($this->mergeRemoteOperations as $merge) {
			$data = (object)$merge->data;
			
			$data->entity = $this->deserializationWalker->walk($data->entity);
			
			// Merge the entity
			$this->em->merge($data->entity);
		}
	}
	
	private function doRemoves() {
		foreach ($this->removeRemoteOperations as $remove) {
			$data = (object)$remove->data;

			$data->entity = $this->deserializationWalker->walk($data->entity);

			// Remove the entity
			$this->em->remove($this->em->merge($data->entity));
		}
	}
	
	private function doAddPersistedIds() {
		// Update the changeset's entityInsertions objects with the ids (which may have just been created during the flush)
		if (isset($this->changeSets["entityInsertions"])) {
			foreach ($this->changeSets["entityInsertions"] as $oid => $entity) {
				$idObj = $this->em->getUnitOfWork()->getEntityIdentifier($entity);
				
				// TODO: Check that this does in fact work with composite ids
				foreach ($idObj as $id => $idValue)
					$entity->$id = $idValue;
			}
		}
	}
	
	private function doAddRemovedIds() {
		// Update the changeset's entityInsertions objects with the ids (which may have just been created during the flush)
		if (isset($this->changeSets["entityDeletions"])) {
			foreach ($this->changeSets["entityDeletions"] as $oid => $entity) {
				$idObj = $this->entityDeletionIdMap[$oid];
				
				// TODO: Check that this does in fact work with composite ids
				foreach ($idObj as $id => $idValue)
					$entity->$id = $idValue;
			}
		}
	}
	
	private $entityDeletionIdMap;
	
	public function onFlush(OnFlushEventArgs $eventArgs) {
		// Doctrine removes the ids from deleted entities at some point later in the chain, so we need to store them here so that we can inject the values
		// back into the changeset before returning to the client.
		$this->entityDeletionIdMap = array();
		foreach ($this->em->getUnitOfWork()->getScheduledEntityDeletions() as $oid => $entity)
			$this->entityDeletionIdMap[$oid] = $this->em->getUnitOfWork()->getEntityIdentifier($entity);
		
		// We don't use collectionUpdates and colectionDeletions so far, and they seem to make Doctrine do loads of SQL queries so leave them
		// out for the moment.
		$this->changeSets = array("entityInsertions" => $this->em->getUnitOfWork()->getScheduledEntityInsertions(),
								  "entityUpdates" => $this->em->getUnitOfWork()->getScheduledEntityUpdates(),
								  "entityDeletions" => $this->em->getUnitOfWork()->getScheduledEntityDeletions()/*,
								  "collectionUpdates" => $this->em->getUnitOfWork()->getScheduledCollectionUpdates(),
								  "collectionDeletions" => $this->em->getUnitOfWork()->getScheduledCollectionDeletions()*/);
		
	}

	/**
	 * There seems to be a bug in Doctrine merge - not exactly sure what or why, but this seems to fix it so far...
	 */
	private function configureCascadesForFlextrine() {
		foreach ($this->em->getMetadataFactory()->getAllMetadata() as $metadata)
			foreach ($metadata->associationMappings as $key => $associationMapping)
				if (!($associationMapping['type'] & ClassMetadata::ONE_TO_MANY))
					$metadata->associationMappings[$key]["isCascadeMerge"] = true;
	}
	
}