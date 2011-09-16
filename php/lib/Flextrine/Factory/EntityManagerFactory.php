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

use Doctrine\ORM\EntityManager,
	Doctrine\ORM\Configuration,
	Doctrine\Common\Cache\ApcCache,
	Doctrine\Common\Cache\ArrayCache,
	Doctrine\Common\Annotations\AnnotationReader,
	\Zend_Registry;

class EntityManagerFactory implements IEntityManagerFactory {

	private $options;
	
	public function __construct($options) {
		$this->options = $options;
	}
	
	public function create() {
		if (!isset($this->options['connection_options']))
			throw new \Exception("The connection_options configuration setting is not defined.");

		if (!isset($this->options['metadata']['driver']))
			throw new \Exception("The metadata.driver configuration setting is not defined.");

		if (!isset($this->options['metadata']['paths']))
			throw new \Exception("The metadata.paths configuration setting is not defined.");

		if (!isset($this->options['directories']['proxies']))
			throw new \Exception("The directories.proxies configuration setting is not defined.");

		$config = new Configuration();

		// Setup the caches
		if (extension_loaded("apc")) {
			$cache = new ApcCache();
		} else {
			$cache = new ArrayCache();
		}

		$config->setMetadataCacheImpl($cache);
		$config->setQueryCacheImpl($cache);

		// Setup the proxies
		$config->setProxyDir(APP_PATH."/".$this->options['directories']['proxies']);
		$config->setProxyNamespace("Proxies");
		$config->setAutoGenerateProxyClasses(isset($this->options['autoGenerateProxies']) && $this->options['autoGenerateProxies']);
		
		// Get the paths from the metadata.paths configuration entry.  This can either be a single item (paths: entities), or a
		// list of paths (paths: [path1, path2]).  The code below deals with both cases, and prepends the APP_PATH to them.
		$paths = is_array($this->options['metadata']['paths']) ? $this->options['metadata']['paths'] : array($this->options['metadata']['paths']);
		array_walk($paths, function(&$item, $key) { $item = APP_PATH.DIRECTORY_SEPARATOR.$item; });
		
		// Set the metadata driver implementation based on the metadata.driver configuration entry.  Note that Annotations are
		// slightly different to the others implementations so are dealt with seperately.
		switch ($this->options['metadata']['driver']) {
			case 'Doctrine\ORM\Mapping\Driver\AnnotationDriver':
				$reader = new AnnotationReader();
				$reader->setDefaultAnnotationNamespace('Doctrine\ORM\Mapping\\');
				//$driverImpl = new $this->options['metadata']['driver']($reader, $paths);
				$driverImpl = $config->newDefaultAnnotationDriver($paths);
				break;
			default:
				$driverImpl = new $this->options['metadata']['driver']($paths);
				break;
		}

		// Set the metadata driver implementation
		$config->setMetadataDriverImpl($driverImpl);

		// Finally create and return the EntityManager.  If a $connectionOptions variable is set in the registry this takes precedence over
		// config.yml, which allows us to override database setting for test suites
		return EntityManager::create(Zend_Registry::isRegistered("connectionOptions") ? Zend_Registry::get("connectionOptions") : $this->options['connection_options'], $config);
	}

}