<?php

namespace Flextrine\Tools\Console\Command;

use Symfony\Component\Console\Input\InputArgument,
	Symfony\Component\Console\Input\InputOption,
	Symfony\Component\Console,
	Flextrine\Tools\AS3EntityGenerator,
	Flextrine\Tools\FlextrineProjectGenerator,
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
		$em = $this->getHelper('em')->getEntityManager();

		$projectName = $input->getArgument('project-name');

		$destPath = ROOT_PATH.DIRECTORY_SEPARATOR."app".DIRECTORY_SEPARATOR.basename($projectName);
		
		if (file_exists($destPath)) {
			$output->write("This app already exists.  You must delete it manually if you want to regenerate it.");
		} else {
			$flextrineProjectGenerator = new FlextrineProjectGenerator($em);
			$flextrineProjectGenerator->generate($projectName, $destPath);

			$output->write("New Flextrine application created successfully in $destPath.", true);
			$output->write("", true);
			$output->write("To get started edit config/config.yml with your database details and create some entities.", true);
		}
	}

}