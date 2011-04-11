<?php
namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Patient {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(length=100, type="string") */
    public $name;
    public function setName($name) { $this->name = $name; }
    public function getName() { return $this->name; }
	
	/** @Column(length=100, type="string", nullable=true) */
    public $address;
	
	/** @Column(length=100, type="string", nullable=true) */
    public $postcode;
	
	/**
     * @OneToMany(targetEntity="Appointment", mappedBy="patient")
     */
	public $appointments;
	
	/**
     * @OneToMany(targetEntity="PhoneNumber", mappedBy="patient")
     */
	public $phoneNumbers;
	
	/**
     * @ManyToOne(targetEntity="Doctor", inversedBy="patients")
     */
	public $doctor;
    public function setDoctor($doctor) { $this->doctor = $doctor; }
    public function getDoctor() { return $this->doctor; }
	
	public function __construct() {
		$this->appointments = new ArrayCollection();
		$this->phoneNumbers = new ArrayCollection();
	}
	
}

?>