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

class Flextrine_Amf_Parse_Amf0_Deserializer extends Zend_Amf_Parse_Amf0_Deserializer {

	/**
     * AMF3 data type encountered load AMF3 Deserializer to handle
     * type markers.
     *
     * @return string
     */
    public function readAmf3TypeMarker() {
        $deserializer = new Flextrine_Amf_Parse_Amf3_Deserializer($this->_stream);
        $this->_objectEncoding = Zend_Amf_Constants::AMF3_OBJECT_ENCODING;
        return $deserializer->readTypeMarker();
    }
	
}