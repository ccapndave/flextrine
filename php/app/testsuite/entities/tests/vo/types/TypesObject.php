<?php
namespace tests\vo\types;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class TypesObject {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(type="integer", nullable=true) */
    public $integerField;
	
	/** @Column(type="smallint", nullable=true) */
    public $smallIntField;
	
	/** @Column(type="bigint", nullable=true) */
    public $bigIntField;
	
	/** @Column(type="decimal", nullable=true) */
    public $decimalField;
	
	/** @Column(type="boolean", nullable=true) */
    public $booleanField;
	
	/** @Column(type="text", nullable=true) */
    public $textField;
	
	/** @Column(length=100, type="string", nullable=true) */
    public $stringField;
	
	/** @Column(type="date", nullable=true) */
    public $dateField;
	
	/** @Column(type="datetime", nullable=true) */
    public $dateTimeField;
	
	public function __construct() {
		
	}
	
}

?>