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

class Flextrine_Amf_Parse_Amf3_Deserializer extends Zend_Amf_Parse_Amf3_Deserializer {
	
	/**
     * Read an object from the AMF stream and convert it into a PHP object
     *
     * @todo   Rather than using an array of traitsInfo create Zend_Amf_Value_TraitsInfo
     * @return object|array
     */
    public function readObject() {
		$returnObject = parent::readObject();
		
		/*if ($returnObject instanceof \Doctrine\Common\Collections\ArrayCollection) {
			// If the object we are deserializing is an ArrayCollection we need to set its contents to externalizedData
			$returnObject->__construct($returnObject->externalizedData);
		}*/
		
    	/*if ($returnObject instanceof \Flextrine\Collections\FlextrinePersistentCollection) {
			// If the object we are deserializing is an FlextrinePersistentCollection we need to set its contents to source
			// TODO: This could maybe be done in __set instead...
			$returnObject->__construct($returnObject->source);
		}*/
		
		return $returnObject;
	}
	
	/**
     * Doctrine needs dates to be deserialized as DateTime objects instead of Zend_Date
     */
    public function readDate()
    {
        $dateReference = $this->readInteger();
        if (($dateReference & 0x01) == 0) {
            $dateReference = $dateReference >> 1;
            if ($dateReference>=count($this->_referenceObjects)) {
                require_once 'Zend/Amf/Exception.php';
                throw new Zend_Amf_Exception('Undefined date reference: ' . $dateReference);
            }
            return $this->_referenceObjects[$dateReference];
        }

        $timestamp = floor($this->_stream->readDouble() / 1000);
		
		$dateTime = new DateTime();
		$dateTime->setTimestamp($timestamp);
		
        $this->_referenceObjects[] = &$dateTime;
		
		return $dateTime;
    }
	
}