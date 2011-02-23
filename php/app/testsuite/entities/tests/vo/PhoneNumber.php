<?php
namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class PhoneNumber {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(length=100, type="string") */
    public $phoneNumber;
	
	/**
	 * @OneToOne(targetEntity="Patient", inversedBy="phoneNumbers")
	 * @JoinColumn(name="patient_id", referencedColumnName="id")
	 */
	public $patient;
	
	public function __construct() {
		
	}
	
}

?>