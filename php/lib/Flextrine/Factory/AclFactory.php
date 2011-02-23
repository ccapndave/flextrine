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

namespace Flextrine\Factory;

use Zend_Registry;

class AclFactory {

	public static function create($options) {
		if (!Zend_Registry::isRegistered("em"))
			throw new \Exception("An EntityManager needs to be registered before the acl instance can be created");

		if (!isset($options['acl']['class']))
			throw new \Exception("The acl.class configuration setting is not defined.");
		
		if (isset($options['acl']['path']))
			include_once APP_PATH."/".$options['acl']['path']."/".$options['acl']['class'].".php";
		
		$em = Zend_Registry::get("em");
		$acl = new $options['acl']['class'];

		foreach ($em->getMetadataFactory()->getAllMetadata() as $metadata)
			$acl->addResource($metadata->name);
		
		$acl->init();
		
		return $acl;
	}

}