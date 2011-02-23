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