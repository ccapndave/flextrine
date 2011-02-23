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
	Doctrine\Common\Annotations\AnnotationReader;

class EntityManagerFactory {

	public static function create($options) {
		if (!isset($options['connection_options']))
			throw new \Exception("The connection_options configuration setting is not defined.");

		if (!isset($options['metadata']['driver']))
			throw new \Exception("The metadata.driver configuration setting is not defined.");

		if (!isset($options['metadata']['paths']))
			throw new \Exception("The metadata.paths configuration setting is not defined.");

		if (!isset($options['directories']['proxies']))
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
		$config->setProxyDir(APP_PATH."/".$options['directories']['proxies']);
		$config->setProxyNamespace("Proxies");
		$config->setAutoGenerateProxyClasses(true); // TODO: This should be in config.yml

		// Get the paths from the metadata.paths configuration entry.  This can either be a single item (paths: entities), or a
		// list of paths (paths: [path1, path2]).  The code below deals with both cases, and prepends the APP_PATH to them.
		$paths = is_array($options['metadata']['paths']) ? $options['metadata']['paths'] : array($options['metadata']['paths']);
		array_walk($paths, function(&$item, $key) { $item = APP_PATH.DIRECTORY_SEPARATOR.$item; });
		
		// Set the metadata driver implementation based on the metadata.driver configuration entry.  Note that Annotations are
		// slightly different to the others implementations so are dealt with seperately.
		switch ($options['metadata']['driver']) {
			case 'Doctrine\ORM\Mapping\Driver\AnnotationDriver':
				$reader = new AnnotationReader();
				$reader->setDefaultAnnotationNamespace('Doctrine\ORM\Mapping\\');
				$driverImpl = new $options['metadata']['driver']($reader, $paths);
				break;
			default:
				$driverImpl = new $options['metadata']['driver']($paths);
				break;
		}

		// Set the metadata driver implementation
		$config->setMetadataDriverImpl($driverImpl);

		// Finally create and return the EntityManager
		return EntityManager::create($options['connection_options'], $config);
	}

}