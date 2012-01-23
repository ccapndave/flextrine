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
			$wrappedObject->isInitialized__ = $object->isInitialized() || (sizeof($wrappedObject->source) > 0);
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