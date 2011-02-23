<?php
namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Doctor {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(length=100, type="string") */
    public $name;
	
    /**
     * @OneToMany(targetEntity="Appointment", mappedBy="doctor")
     */
	public $appointments;
	
	/**
     * @OneToMany(targetEntity="Patient", mappedBy="doctor")
     */
	public $patients;
	
	public function __construct() {
		$this->appointments = new ArrayCollection();
		$this->patients = new ArrayCollection();
	}
	
}

?>