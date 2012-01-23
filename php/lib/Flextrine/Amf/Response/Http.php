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
