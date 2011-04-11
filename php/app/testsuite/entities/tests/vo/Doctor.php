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
    public function setName($name) { $this->name = $name; }
    public function getName() { return $this->name; }
	
    /**
     * @OneToMany(targetEntity="Appointment", mappedBy="doctor")
     */
	public $appointments;
	
	/**
     * @OneToMany(targetEntity="Patient", mappedBy="doctor")
     */
	public $patients;
	public function addPatient($patient) { $this->patients->add($patient); }
	public function getPatients() { return $this->patients; }
	
	public function __construct() {
		$this->appointments = new ArrayCollection();
		$this->patients = new ArrayCollection();
	}
	
}

?>