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

class Flextrine_Amf_Parse_Amf3_Serializer extends Zend_Amf_Parse_Amf3_Serializer {
	
    /**
     * Write object to ouput stream
     *
     * @param  mixed $data
     * @return Zend_Amf_Parse_Amf3_Serializer
     */
	public function writeObject($object) {
		if ($object instanceof \Doctrine\Common\Collections\ArrayCollection || $object instanceof \Doctrine\ORM\PersistentCollection) {
			$this->writeCollection($object);
		} /*else if ($object instanceof \vo\Doctor || $object instanceof \vo\Patient) {
			$this->writeEntity($object);
		}*/ else {
			parent::writeObject($object);
		}
	}
	
	public function writeEntity(&$object) {
		// Although not in right now, this is where we could use Doctrine 2 reflection to serialize private properties for entities.
		parent::writeObject($object);
	}
	
	public function writeCollection(&$object) {
		// In order to get around the problems with ZendAMF and Iterator/foreach we create a vanilla object and use _explicitType to
		// map it on the client.  The source property maps to mx.collections.ArrayCollection::source.  We also need to add whether
		// or not the collection is initialized.
		$wrappedObject = new \stdClass();
		$wrappedObject->_explicitType = "org.davekeen.flextrine.orm.collections.PersistentCollection";
		
		if ($object instanceof \Doctrine\ORM\PersistentCollection) {
			$wrappedObject->source = $object->unwrap()->toArray();
			$wrappedObject->isInitialized__ = $object->isInitialized();
		} else {
			$wrappedObject->source = $object->toArray();
			$wrappedObject->isInitialized__ = true;
		}
		
		parent::writeObject($wrappedObject);
	}
	
	/**
     * Manually applying Mark Reidenbach's performance patch from ZF-7493 as it doesn't seem to be in the Zend release
     */
    public function writeString(&$string)
    {
        $len = strlen($string);
        if(!$len){
            $this->writeInteger(0x01);
            return $this;
        }

        $ref = array_key_exists($string, $this->_referenceStrings) ? $this->_referenceStrings[$string] : false;
        if($ref === false){
            $this->_referenceStrings[$string] = count($this->_referenceStrings);
            $this->writeBinaryString($string);
        } else {
            $ref <<= 1;
            $this->writeInteger($ref);
        }

        return $this;
    }
	
}