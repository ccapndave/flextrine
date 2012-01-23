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