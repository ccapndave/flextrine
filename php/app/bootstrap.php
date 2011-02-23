<?php
/**
 * Copyright 2011 Dave Keen
 * http://www.actionscriptdeveloper.co.uk
 *
 * This file is part of Flextrine.
 *
 * Flextrine is free software: you can redistribute it and/or modify
 * it under the terms of the Lesser GNU General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * Lesser GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * and the Lesser GNU General Public License along with this program.
 * If not, see <http://www.gnu.org/licenses/>.
 *
 */

use Symfony\Component\HttpFoundation\UniversalClassLoader,
	Symfony\Component\Yaml\Yaml,
	Doctrine\Common\ClassLoader,
	Flextrine\Config;

// Define a constant pointing to the root of the application
define('ROOT_PATH', dirname(dirname(__FILE__)));

// Set the include path to the lib folder included in the framework
set_include_path(get_include_path().PATH_SEPARATOR.ROOT_PATH."/lib");

// Include and configure the classloader - use Symfony's UniversalClassLoader as it supports both
// PHP 5.3 and PEAR style namespaces
require_once "Symfony/Component/HttpFoundation/UniversalClassLoader.php";

$loader = new UniversalClassLoader();
$loader->registerNamespaces(array(
	'Flextrine'					 => __DIR__."/../lib",
	'Doctrine'                   => __DIR__.'/../lib',
	'Symfony'                    => __DIR__.'/../lib/Doctrine',
));
$loader->registerPrefixes(array(
	'Zend_'						 => __DIR__."/../lib",
	'Flextrine_'				 => __DIR__."/../lib",
));
$loader->register();

// Load the main configuration file
$mainConfig = Yaml::load(ROOT_PATH."/config/config.yml");
Zend_Registry::set("mainConfig", $mainConfig);

// Now we need to decide which application we are supposed to be running.  The logic goes like this:
//  - If there is a GET parameter called 'app' this takes precedence (e.g. gateway.php?app=myflextrineproject)
//  - Otherwise use default_app in the main config.yml
//  - Otherwise throw an error

if (isset($_GET['app'])) {
	$appName = $_GET['app'];
} else if (isset($mainConfig['default_app'])) {
	$appName = $mainConfig['default_app'];
} else {
	throw new \Exception("bootstrap.php was invoked without specifying an application name (\$appName)");
}

define('APP_PATH', ROOT_PATH.DIRECTORY_SEPARATOR."app".DIRECTORY_SEPARATOR.$appName);

if (!file_exists(APP_PATH))
	throw new \Exception("The application '$appName' does not exist.  Generate it using the flextrine console tool (flextrine app:create <app_name>)");

// Load the application specific configuration file
$appConfig =  Yaml::load(APP_PATH."/config/config.yml");
Zend_Registry::set("appConfig", $appConfig);

// We need an extra class loader for the entities and services directory themselves; use empty namespace as there could be anything in here
$entityClassLoader = new ClassLoader(null, APP_PATH.DIRECTORY_SEPARATOR.$appConfig["directories"]["entities"]);
$entityClassLoader->register();

// Create the Doctrine EntityManager
Zend_Registry::set("em", Flextrine\Factory\EntityManagerFactory::create(Zend_Registry::get("appConfig")));

// If acls are enabled create the Acl instance
if ($appConfig["acl"]["enable"])
	Zend_Registry::set("acl", Flextrine\Factory\AclFactory::create(Zend_Registry::get("appConfig")));