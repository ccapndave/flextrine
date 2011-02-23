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