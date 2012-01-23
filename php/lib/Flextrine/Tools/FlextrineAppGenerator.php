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

namespace Flextrine\Tools;

use Doctrine\ORM\EntityManager,
 Doctrine\ORM\Mapping\ClassMetadata,
 Doctrine\ORM\Mapping\AssociationMapping,
 Doctrine\Common\Util\Inflector;

require_once('vlib/vlibTemplate.php');

class FlextrineAppGenerator {

	public function __construct() {
		
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