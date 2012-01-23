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
