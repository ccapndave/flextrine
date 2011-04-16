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