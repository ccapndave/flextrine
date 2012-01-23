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

namespace Flextrine;

use Flextrine\Acl\FlextrineAcl;

class EntitiesAcl extends FlextrineAcl {
	
	/**
	 * Configure roles and ACL rules here.  By the time this method has been called all entities will already have been added to Zend_ACL as
	 * resource, with their id being their fully qualified class name.  Privileges are defined as constants in Flextrine\Acl\FlextrineAcl and
	 * are automatically triggered by Flextrine as operations take place.
	 */
	public function init() {
		
	}
	
}