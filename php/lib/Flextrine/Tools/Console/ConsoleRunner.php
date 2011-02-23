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

namespace Flextrine\Tools\Console;

use Symfony\Component\Console\Helper\HelperSet,
	Symfony\Component\Console\Application;

class ConsoleRunner extends \Doctrine\ORM\Tools\Console\ConsoleRunner {

	/**
     * Run console with the given helperset.  Use the in-built Doctrine commands, plus Flextrine specific ones.
     *
     * @param \Symfony\Component\Console\Helper\HelperSet $helperSet
     * @return void
     */
    static public function run(HelperSet $helperSet) {
        $cli = new Application('Doctrine Command Line Interface', \Doctrine\ORM\Version::VERSION);
        $cli->setCatchExceptions(true);
        $cli->setHelperSet($helperSet);

		parent::addCommands($cli);
        self::addCommands($cli);

		$cli->run();
    }

	/**
     * @param Application $cli
     */
    static public function addCommands(Application $cli) {
		$cli->addCommands(array(
            // Flextrine Commands
            new \Flextrine\Tools\Console\Command\GenerateAS3EntitiesCommand(),
            new \Flextrine\Tools\Console\Command\CreateFlextrineAppCommand(),
		));
	}

}