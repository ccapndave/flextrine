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

namespace Flextrine\Internal\Walkers;

use Doctrine\ORM\EntityManager,
	Doctrine\ORM\PersistentCollection,
	Doctrine\ORM\Mapping\ClassMetadata,
	Doctrine\ORM\Proxy\Proxy;

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

		// If the entity is initialized then walk through the associations
		if (!($entity instanceof Proxy && !$entity->__isInitialized__)) {
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
		}

		$this->afterWalk($entity);
	}

	protected function beforeWalk($entity) { }
	protected function beforeCollectionWalk($collection) { }
	protected function replaceEntity($entity) { return $entity; }
	protected function afterWalk($entity) { }

}