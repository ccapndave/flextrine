<?php
/**
* Copyright 2010 Dave Keen
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

class Flextrine_Amf_Request_Http extends Zend_Amf_Request_Http {

	/**
	 * Override the constructor not to echo "Zend AMF Endpoint" as this breaks the manager
	 */
    public function __construct() {
        // php://input allows you to read raw POST data. It is a less memory
        // intensive alternative to $HTTP_RAW_POST_DATA and does not need any
        // special php.ini directives
        $amfRequest = file_get_contents('php://input');

        // Check to make sure that we have data on the input stream.
        if ($amfRequest != '') {
            $this->_rawRequest = $amfRequest;
            $this->initialize($amfRequest);
        }
    }

    /**
     * Prepare the AMF InputStream for parsing using our replacement deserializer.
     *
     * @param  string $request
     * @return Zend_Amf_Request
     */
    public function initialize($request) {
        $this->_inputStream  = new Zend_Amf_Parse_InputStream($request);
        $this->_deserializer = new Flextrine_Amf_Parse_Amf0_Deserializer($this->_inputStream);
        $this->readMessage($this->_inputStream);
        return $this;
    }

}
