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

namespace Flextrine\Tools;

use Doctrine\ORM\EntityManager,
 Doctrine\ORM\Mapping\ClassMetadata,
 Doctrine\ORM\Mapping\AssociationMapping,
 Doctrine\Common\Util\Inflector;

require_once('vlib/vlibTemplate.php');

class FlextrineAppGenerator {

	private $em;

	public function __construct(EntityManager $em) {
		$this->em = $em;
	}

	public function generate($projectName, $outputDirectory) {
		// To do this we simply copy the contents of templates/php/app (the blank app) into the newly created directory.
		self::smartCopy(dirname(__FILE__)."/templates/php/app", $outputDirectory);
	}

	/**
	 * Copy file or folder from source to destination, it can do
	 * recursive copy as well and is very smart
	 * It recursively creates the dest file or directory path if there weren't exists
	 * Situtaions :
	 * - Src:/home/test/file.txt ,Dst:/home/test/b ,Result:/home/test/b -> If source was file copy file.txt name with b as name to destination
	 * - Src:/home/test/file.txt ,Dst:/home/test/b/ ,Result:/home/test/b/file.txt -> If source was file Creates b directory if does not exsits and copy file.txt into it
	 * - Src:/home/test ,Dst:/home/ ,Result:/home/test/** -> If source was directory copy test directory and all of its content into dest
	 * - Src:/home/test/ ,Dst:/home/ ,Result:/home/**-> if source was direcotry copy its content to dest
	 * - Src:/home/test ,Dst:/home/test2 ,Result:/home/test2/** -> if source was directoy copy it and its content to dest with test2 as name
	 * - Src:/home/test/ ,Dst:/home/test2 ,Result:->/home/test2/** if source was directoy copy it and its content to dest with test2 as name
	 * @todo
	 *     - Should have rollback technique so it can undo the copy when it wasn't successful
	 *  - Auto destination technique should be possible to turn off
	 *  - Supporting callback function
	 *  - May prevent some issues on shared enviroments : http://us3.php.net/umask
	 * @param $source //file or folder
	 * @param $dest ///file or folder
	 * @param $options //folderPermission,filePermission
	 * @return boolean
	 */
	private static function smartCopy($source, $dest, $options = array('folderPermission' => 0755, 'filePermission' => 0755)) {
		$result = false;

		if (is_file($source)) {
			if ($dest[strlen($dest) - 1] == '/') {
				if (!file_exists($dest)) {
					cmfcDirectory::makeAll($dest, $options['folderPermission'], true);
				}
				$__dest = $dest . "/" . basename($source);
			} else {
				$__dest = $dest;
			}
			$result = copy($source, $__dest);
			chmod($__dest, $options['filePermission']);
		} elseif (is_dir($source)) {
			if ($dest[strlen($dest) - 1] == '/') {
				if ($source[strlen($source) - 1] == '/') {
					//Copy only contents
				} else {
					//Change parent itself and its contents
					$dest = $dest . basename($source);
					@mkdir($dest);
					chmod($dest, $options['filePermission']);
				}
			} else {
				if ($source[strlen($source) - 1] == '/') {
					//Copy parent directory with new name and all its content
					@mkdir($dest, $options['folderPermission']);
					chmod($dest, $options['filePermission']);
				} else {
					//Copy parent directory with new name and all its content
					@mkdir($dest, $options['folderPermission']);
					chmod($dest, $options['filePermission']);
				}
			}

			$dirHandle = opendir($source);
			while ($file = readdir($dirHandle)) {
				if ($file != "." && $file != "..") {
					if (!is_dir($source . "/" . $file)) {
						$__dest = $dest . "/" . $file;
					} else {
						$__dest = $dest . "/" . $file;
					}
					//echo "$source/$file ||| $__dest<br />";
					$result = self::smartCopy($source . "/" . $file, $__dest, $options);
				}
			}
			closedir($dirHandle);
		} else {
			$result = false;
		}
		return $result;
	}

}