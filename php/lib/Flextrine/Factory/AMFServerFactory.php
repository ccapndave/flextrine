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

use Zend_Registry,
	Zend_Amf_Server,
	Flextrine_Amf_Response_Http,
	Flextrine_Amf_Request_Http;

class AMFServerFactory {

	public static function create($options) {
		if (!Zend_Registry::isRegistered("em"))
			throw new \Exception("An EntityManager needs to be registered before the server can be created");

		if (!isset($options['directories']['services']))
			throw new \Exception("The directories.services configuration setting is not defined.");

		$server = new Zend_Amf_Server();
		$server->addDirectory(APP_PATH."/".$options['directories']['services']);

		// TODO: This should be a configuration option
		$server->setProduction(false);

		$server->setClassMap('org.davekeen.flextrine.orm.Query', '\Flextrine\Query');
		$server->setClassMap('org.davekeen.flextrine.orm.collections.PersistentCollection', '\Flextrine\Collections\FlextrinePersistentCollection');

		$proxyNamespace = Zend_Registry::get("em")->getConfiguration()->getProxyNamespace();
		foreach (Zend_Registry::get("em")->getMetadataFactory()->getAllMetadata() as $metadata) {
			$phpClassName = $metadata->name;
			$as3ClassName = str_replace("\\", ".", $metadata->name);

			$server->setClassMap($phpClassName, $as3ClassName);
			$server->setClassMap($as3ClassName, $proxyNamespace."\\".str_replace("\\", "", $metadata->name)."Proxy");
		}

		$server->setResponse(new Flextrine_Amf_Response_Http());
		$server->setRequest(new Flextrine_Amf_Request_Http());

		return $server;
	}

}