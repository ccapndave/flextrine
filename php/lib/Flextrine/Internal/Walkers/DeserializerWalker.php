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