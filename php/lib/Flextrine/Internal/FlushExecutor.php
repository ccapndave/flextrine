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

use Flextrine\Operations\CollectionChangeOperation;

use Doctrine\ORM\Events,
	Doctrine\ORM\Event\OnFlushEventArgs,
	Doctrine\ORM\Mapping\ClassMetadata;

class FlushExecutor {
	
	private $em;

	private $deserializationWalker;
	
	private $changeSets;
	
	private $temporaryUidMap;
	
	private $persistRemoteOperations = array();
	
	private $propertyChangeRemoteOperations = array();
	
	private $collectionChangeRemoteOperations = array();
	
	private $removeRemoteOperations = array();
	
	private $originalCascades = array();
	
	function __construct($em, $flushSet, $deserializationWalker) {
		$this->em = $em;

		$this->deserializationWalker = $deserializationWalker;

		if ($flushSet) {
			// Get the remote operations out of the flushset for each operation type
			foreach ($flushSet->persists as $persistRemoteOperation)
				$this->persistRemoteOperations[] = (object)$persistRemoteOperation;
			
			foreach ($flushSet->propertyChanges as $propertyChangeRemoteOperation)
				$this->propertyChangeRemoteOperations[] = (object)$propertyChangeRemoteOperation;
				
			foreach ($flushSet->collectionChanges as $collectionChangeRemoteOperation)
				$this->collectionChangeRemoteOperations[] = (object)$collectionChangeRemoteOperation;
				
			foreach ($flushSet->removes as $removeRemoteOperation)
				$this->removeRemoteOperations[] = (object)$removeRemoteOperation;
		}
		
	}
	
	function __destruct() {
		
	}
	
	public function flush() {
		$this->temporaryUidMap = array();
		
		// Add an event listener to hook into the flush and retrieve the changesets
		$this->em->getEventManager()->addEventListener(array(Events::onFlush), $this);
		
		// Persist, update and remove as required
		$this->doPersists();
		$this->doPropertyChanges();
		$this->doCollectionChanges();
		$this->doRemoves();
		
		try {
			// Perform the flush
			$this->em->flush();
		} catch (\Exception $e) {
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
		foreach ($this->persistRemoteOperations as $persistOperation) {
			$entity = $this->deserializationWalker->walk($persistOperation->entity);
			
			// Persist the entity
			$this->em->persist($entity);
			
			// Add a map from the object hash to the temporary uid of the object
			$this->temporaryUidMap[spl_object_hash($entity)] = $persistOperation->temporaryUid;
		}
	}
	
	private function doPropertyChanges() {
		foreach ($this->propertyChangeRemoteOperations as $propertyChangeOperation) {
			$class = $this->em->getClassMetadata(get_class($propertyChangeOperation->entity));
			
			$entity = $this->getManagedEntityById($propertyChangeOperation->entity);
			
			// Determine whether we are updating a field or a (single valued) association.
			if (array_key_exists($propertyChangeOperation->property, $class->fieldMappings)) {
				// Set the new value of the property (this should use reflection, but for now do it dynamically)
				$entity->{$propertyChangeOperation->property} = $propertyChangeOperation->value;
			} else if (array_key_exists($propertyChangeOperation->property, $class->associationMappings)) {
				if ($class->associationMappings[$propertyChangeOperation->property]['type'] & ClassMetadata::TO_MANY)
					throw new \Exception("Flextrine attempted to execute a propertyChange event against a many valued collection.  This should not happen!");
				
				// Set the new value of the property (this should use reflection, but for now do it dynamically)
				$newAssoc = $this->getManagedEntityById($propertyChangeOperation->value);
				$entity->{$propertyChangeOperation->property} = $newAssoc;
			}
			
			// This is horribly inefficient, but unfortunately (at least at present) it seems to be the only way to get certain property changes to hold
			$this->em->flush();
		}
	}
	
	private function doCollectionChanges() {
		foreach ($this->collectionChangeRemoteOperations as $collectionChangeOperation) {
			$class = $this->em->getClassMetadata(get_class($collectionChangeOperation->entity));
			
			if (!(array_key_exists($collectionChangeOperation->property, $class->associationMappings) && $class->associationMappings[$collectionChangeOperation->property]['type'] & ClassMetadata::TO_MANY))
				throw new \Exception("Flextrine attempted to execute a collectionChange event against a non-existant or single valued association.  This should not happen!");
			
			$entity = $this->getManagedEntityById($collectionChangeOperation->entity);
			
			foreach ($collectionChangeOperation->items as $item) {
				$newAssoc = $this->getManagedEntityById($item);
				
				switch ($collectionChangeOperation->type) {
					case CollectionChangeOperation::ADD:
						if (!($entity->{$collectionChangeOperation->property}->contains($newAssoc)))
							$entity->{$collectionChangeOperation->property}->add($newAssoc);
						break;
					case CollectionChangeOperation::REMOVE:
						if (($entity->{$collectionChangeOperation->property}->contains($newAssoc)))
							$entity->{$collectionChangeOperation->property}->removeElement($newAssoc);
						break;
				}
			}
		}
	}
	
	private function getManagedEntityById($detachedEntity) {
		if (is_null($detachedEntity))
			return null;
		
		$class = $this->em->getClassMetadata(get_class($detachedEntity));
		
		$idFields = $class->getIdentifier();
		
		$findBy = array();
		foreach ($idFields as $idField)
			$findBy[$idField] = $detachedEntity->$idField; // TODO: This should use reflection
		
		return $this->em->getRepository(get_class($detachedEntity))->findOneBy($findBy);
	}
	
	private function doRemoves() {
		foreach ($this->removeRemoteOperations as $removeOperation)
			$this->em->remove($this->getManagedEntityById($removeOperation->entity));
		
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
		//
		// TODO: Now that Flextrine uses change messenging collectionUpdates and collectionDeletions makes more sense again, especially as without then server-side M2N changes won't
		// get picked up by callRemoteFlushMethod.  For now these can stay commented, but this must be addressed at some point.
		$this->changeSets = array("entityInsertions" => $this->em->getUnitOfWork()->getScheduledEntityInsertions(),
								  "entityUpdates" => $this->em->getUnitOfWork()->getScheduledEntityUpdates(),
								  "entityDeletions" => $this->em->getUnitOfWork()->getScheduledEntityDeletions()/*,
								  "collectionUpdates" => $this->em->getUnitOfWork()->getScheduledCollectionUpdates(),
								  "collectionDeletions" => $this->em->getUnitOfWork()->getScheduledCollectionDeletions()*/);
		
	}
	
}