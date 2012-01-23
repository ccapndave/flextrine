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
	Doctrine\ORM\Tools\Console\MetadataFilter;

class GenerateAS3EntitiesCommand extends Console\Command\Command {

	/**
	 * @see Console\Command\Command
	 */
	protected function configure() {
		$this
		->setName("as3:generate-entities")
		->setDescription('Generate AS3 entity classes and method stubs from your mapping information.')
		->setDefinition(array(
			new InputOption(
					'filter', null, InputOption::VALUE_REQUIRED | InputOption::VALUE_IS_ARRAY,
					'A string pattern used to match entities that should be processed.'
			),
			new InputArgument(
					'dest-path', InputArgument::REQUIRED, 'The path to generate your entity classes.'
			),
			new InputOption(
					'generate-helper-methods', null, InputOption::VALUE_OPTIONAL,
					'Flag to define if generator should generate association helper methods on entities.', true
			),
			new InputOption(
					'regenerate-entities', null, InputOption::VALUE_OPTIONAL,
					'Flag to define if generator should regenerate entity if it exists.', false
			),
			new InputOption(
					'update-entities', null, InputOption::VALUE_OPTIONAL,
					'Flag to define if generator should only update entity if it exists.', true
			),
		))
		->setHelp(<<<EOT
			Generate AS3 entity classes and method stubs from your mapping information.
EOT
		);
	}

	/**
	 * @see Console\Command\Command
	 */
	protected function execute(Console\Input\InputInterface $input, Console\Output\OutputInterface $output) {
		$em = $this->getHelper('em')->getEntityManager();

		$metadatas = $em->getMetadataFactory()->getAllMetadata();
		$metadatas = MetadataFilter::filter($metadatas, $input->getOption('filter'));

		 // Process destination directory
        $destPath = realpath($input->getArgument('dest-path'));

        if ( ! file_exists($destPath)) {
            throw new \InvalidArgumentException(
                sprintf("Entities destination directory '<info>%s</info>' does not exist.", $destPath)
            );
        } else if ( ! is_writable($destPath)) {
            throw new \InvalidArgumentException(
                sprintf("Entities destination directory '<info>%s</info>' does not have write permissions.", $destPath)
            );
        }

		if (count($metadatas)) {
            // Create EntityGenerator
            $entityGenerator = new AS3EntityGenerator($em);

            $entityGenerator->setGenerateAssociationHelperMethods($input->getOption('generate-helper-methods'));
            $entityGenerator->setRegenerateEntityIfExists($input->getOption('regenerate-entities'));
            $entityGenerator->setUpdateEntityIfExists($input->getOption('update-entities'));

            foreach ($metadatas as $metadata) {
                $output->write(
                    sprintf('Processing entity "<info>%s</info>"', $metadata->name) . PHP_EOL
                );
            }

            // Generating Entities
            $entityGenerator->generate($metadatas, $destPath);

            // Outputting information message
            $output->write(PHP_EOL . sprintf('AS3 entity classes generated to "<info>%s</INFO>"', $destPath) . PHP_EOL);
        } else {
            $output->write('No Metadata Classes to process.' . PHP_EOL);
        }
	}

}