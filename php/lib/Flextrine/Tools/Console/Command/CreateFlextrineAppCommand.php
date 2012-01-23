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

namespace Flextrine\Tools\Console\Command;

use Symfony\Component\Console\Input\InputArgument,
	Symfony\Component\Console\Input\InputOption,
	Symfony\Component\Console,
	Flextrine\Tools\AS3EntityGenerator,
	Flextrine\Tools\FlextrineAppGenerator,
	Doctrine\ORM\Tools\Console\MetadataFilter,
	Doctrine\ORM\Tools\DisconnectedClassMetadataFactory;

class CreateFlextrineAppCommand extends Console\Command\Command {

	/**
	 * @see Console\Command\Command
	 */
	protected function configure() {
		$this
		->setName("app:create")
		->setDescription('Create a new Flextrine application in the app directory')
		->setDefinition(array(
			new InputArgument(
				'app-name', InputArgument::REQUIRED, 'The name of the new app.'
			),
		))
		->setHelp(<<<EOT
			Generate a new Flextrine app in the app directory ready for use.  If the app already exists it must be
			deleted manually.
EOT
		);
	}

	/**
	 * @see Console\Command\Command
	 */
	protected function execute(Console\Input\InputInterface $input, Console\Output\OutputInterface $output) {
		$appName = $input->getArgument('app-name');

		$destPath = ROOT_PATH.DIRECTORY_SEPARATOR."app".DIRECTORY_SEPARATOR.basename($appName);
		
		if (file_exists($destPath)) {
			$output->write("This app already exists.  You must delete it manually if you want to regenerate it.");
		} else {
			$flextrineAppGenerator = new FlextrineAppGenerator();
			$flextrineAppGenerator->generate($appName, $destPath);

			$output->write("New Flextrine application created successfully in $destPath.", true);
			$output->write("", true);
			$output->write("To get started edit config/development.yml with your database details and create some entities.", true);
			
			// Update the default application in the main config.yml file to the application we just created
			$configContents = file_get_contents(ROOT_PATH.DIRECTORY_SEPARATOR."config/config.yml");
			$configContents = preg_replace("/default_app: (.*)/", "default_app: $appName", $configContents);
			file_put_contents(ROOT_PATH.DIRECTORY_SEPARATOR."config/config.yml", $configContents);
		}
	}

}