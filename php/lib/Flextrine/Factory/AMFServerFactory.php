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
		
		$server->setClassMap('org.davekeen.flextrine.orm.operations.PersistOperation', '\Flextrine\Operations\PersistOperation');
		$server->setClassMap('org.davekeen.flextrine.orm.operations.RemoveOperation', '\Flextrine\Operations\RemoveOperation');
		$server->setClassMap('org.davekeen.flextrine.orm.operations.PropertyChangeOperation', '\Flextrine\Operations\PropertyChangeOperation');
		$server->setClassMap('org.davekeen.flextrine.orm.operations.CollectionChangeOperation', '\Flextrine\Operations\CollectionChangeOperation');

		$server->setClassMap('org.davekeen.flextrine.orm.operations.MergeOperation', '\Flextrine\Operations\MergeOperation'); // This operation will be depreciated
		
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