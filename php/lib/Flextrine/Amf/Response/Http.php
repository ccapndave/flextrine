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

class Flextrine_Amf_Response_Http extends Zend_Amf_Response_Http {

	/**
	 * Override writeMessage to use our extended serializer instead of the standard ZendAMF one.
     *
     * @param  Zend_Amf_Parse_OutputStream $stream
     * @return Zend_Amf_Response
     */
    public function writeMessage(Zend_Amf_Parse_OutputStream $stream)
    {
        $objectEncoding = $this->_objectEncoding;

        //Write encoding to start of stream. Preamble byte is written of two byte Unsigned Short
        $stream->writeByte(0x00);
        $stream->writeByte($objectEncoding);

        // Loop through the AMF Headers that need to be returned.
        $headerCount = count($this->_headers);
        $stream->writeInt($headerCount);
        foreach ($this->getAmfHeaders() as $header) {
		
            //$serializer = new Zend_Amf_Parse_Amf0_Serializer($stream);
            $serializer = new Flextrine_Amf_Parse_Amf0_Serializer($stream);
			
            $stream->writeUTF($header->name);
            $stream->writeByte($header->mustRead);
            $stream->writeLong(Zend_Amf_Constants::UNKNOWN_CONTENT_LENGTH);
            if (is_object($header->data)) {
                // Workaround for PHP5 with E_STRICT enabled complaining about 
                // "Only variables should be passed by reference"
                $placeholder = null;
                $serializer->writeTypeMarker($placeholder, null, $header->data);
            } else {
                $serializer->writeTypeMarker($header->data);
            }
        }

        // loop through the AMF bodies that need to be returned.
        $bodyCount = count($this->_bodies);
        $stream->writeInt($bodyCount);
        foreach ($this->_bodies as $body) {
            
			//$serializer = new Zend_Amf_Parse_Amf0_Serializer($stream);
			$serializer = new Flextrine_Amf_Parse_Amf0_Serializer($stream);
			
            $stream->writeUTF($body->getTargetURI());
            $stream->writeUTF($body->getResponseURI());
            $stream->writeLong(Zend_Amf_Constants::UNKNOWN_CONTENT_LENGTH);
            $bodyData = $body->getData();
            $markerType = ($this->_objectEncoding == Zend_Amf_Constants::AMF0_OBJECT_ENCODING) ? null : Zend_Amf_Constants::AMF0_AMF3;
            if (is_object($bodyData)) {
                // Workaround for PHP5 with E_STRICT enabled complaining about 
                // "Only variables should be passed by reference"
                $placeholder = null;
                $serializer->writeTypeMarker($placeholder, $markerType, $bodyData);
            } else {
                $serializer->writeTypeMarker($bodyData, $markerType);
            }
        }

        return $this;
    }

}
