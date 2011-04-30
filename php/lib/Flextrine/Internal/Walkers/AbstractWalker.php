<?php
namespace Flextrine\Internal\Walkers;

use Doctrine\ORM\EntityManager,
	Doctrine\ORM\PersistentCollection,
	Doctrine\ORM\Mapping\ClassMetadata;

abstract class AbstractWalker {

	protected $em;

	public function __construct(EntityManager $em) {
		$this->em = $em;
	}

	public function walk($entityOrArray) {
		if (is_array($entityOrArray)) {
			foreach ($entityOrArray as $entity)
				$this->doWalk($entity);
		} else {
			$this->doWalk($entityOrArray);
		}

		return $entityOrArray;
	}

	private function doWalk($entity, &$visited = array()) {
		if (!$entity)
			return;

		$oid = spl_object_hash($entity);
		if (isset($visited[$oid]))
			return;

		$visited[$oid] = true;

		// Get the class metadata
		$class = $this->em->getClassMetadata(get_class($entity));

		$this->beforeWalk($entity);

		// Walk through the associations
		foreach ($class->associationMappings as $assoc) {
			$assocField = $assoc['fieldName'];
			$assocProp = $class->reflFields[$assocField];

			if ($assoc['type'] & ClassMetadata::TO_ONE) {
				$other = $this->replaceEntity($assocProp->getValue($entity));
				
				$assocProp->setValue($entity, $other);

				$this->doWalk($other, $visited);
			} else if ($assoc['type'] & ClassMetadata::TO_MANY) {
				$collection = $assocProp->getValue($entity);
				
				if ($collection) {
					$this->beforeCollectionWalk($collection);

					if ($collection->isInitialized()) {						
						for ($n = 0; $n < $collection->count(); $n++) {
							$relatedEntity = $collection->get($n);
							
							$collection->set($n, $this->replaceEntity($relatedEntity));
							
							$this->doWalk($relatedEntity, $visited);
						}
					}
				}
				
			}
		}

		$this->afterWalk($entity);
	}

	protected function beforeWalk($entity) { }
	protected function beforeCollectionWalk($collection) { }
	protected function replaceEntity($entity) { return $entity; }
	protected function afterWalk($entity) { }

}