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

use Flextrine;

use Flextrine\Internal\Walkers\AbstractWalker,
	Flextrine\FlextrineException,
	Flextrine\Acl\FlextrineAcl,
	Doctrine\ORM\Proxy\Proxy,
	Doctrine\ORM\EntityManager;

/**
 * The SerializerWalker prepares Doctrine entities to be sent to Flex.
 */
class SerializerWalker extends AbstractWalker {

	protected $acl;
	
	protected $role;
	
	public function __construct(EntityManager $em, \Zend_Acl $acl = null, \Zend_Acl_Role_Interface $role = null) {
		parent::__construct($em);
		
		$this->acl = $acl;
		$this->role = $role;
	}
	
	protected function beforeWalk($entity) {
		if ($entity instanceof Proxy) {
			$entity->isInitialized__ = $entity->__isInitialized__;
		} else {
			$entity->isInitialized__ = true;
			
			// If the entity is initialized and we are using authentication then make an ACL check against the LOAD privilege
			if ($this->acl)
				if (!$this->acl->isAllowed($this->role, $entity, FlextrineAcl::PRIVILEGE_LOAD))
					throw new FlextrineException("Unauthorized 'load' access to ".get_class($entity));
		}
	}
	
	/**
	 * If the received entity is a Proxy fill in the id
	 * 
	 * @param unknown_type $entity
	 */
	protected function replaceEntity($entity) {
		if ($entity instanceof Proxy && !$entity->__isInitialized__) {
			// TODO: This ReflectionClass is actually already inside the reflFields of ClassMetadata - use that instead as it will be more efficient
			$reflectionClass = new \ReflectionClass($entity);

			$identifierProperty = $reflectionClass->getProperty("_identifier");
			$identifierProperty->setAccessible(true);
			$identifier = $identifierProperty->getValue($entity);

			foreach ($identifier as $idAttribute => $id)
				$entity->$idAttribute = $id;

		}
		
		return $entity;
	}

	protected function afterWalk($entity) {
		$entity->isUnserialized__ = true;
	}

}