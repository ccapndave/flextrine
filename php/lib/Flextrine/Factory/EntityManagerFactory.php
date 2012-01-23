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