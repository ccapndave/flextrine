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

namespace Flextrine\Internal\Walkers;

use Flextrine\Internal\Walkers\AbstractWalker,
	Doctrine\ORM\Proxy\Proxy,
	Doctrine\ORM\EntityManager;

/**
 * The DeserializerWalker prepares entities received from Flex to be used with Doctrine.
 */
class DeserializerWalker extends AbstractWalker {
	
	protected $acl;
	
	protected $role;
	
	public function __construct(EntityManager $em, \Zend_Acl $acl = null, \Zend_Acl_Role_Interface $role = null) {
		parent::__construct($em);
		
		$this->acl = $acl;
		$this->role = $role;
	}
	
	/**
	 * If the received entity is uninitialized replace it with a Proxy
	 * 
	 * @param unknown_type $entity
	 */
	protected function replaceEntity($entity) {
		if ($entity && !$entity instanceof Proxy && isset($entity->isInitialized__) && !$entity->isInitialized__) {
			// TODO: This assumes the identifier column is called id - instead this should use $this->em->getClassMetaData to determine the identifier column
			return $this->em->getReference(get_class($entity), $entity->id);
		} else {
			return $entity;
		}
	}

}