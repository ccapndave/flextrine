<?php
namespace tests\vo;

/**
 * @Entity
 */

class Appointment {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;

    /** @Column(type="date", nullable=true) */
    public $date;
	
	/**
     * @OneToOne(targetEntity="Doctor", inversedBy="appointment")
	 * @JoinColumn(name="doctor_id", referencedColumnName="id")
     */
	public $doctor;
	
	/**
     * @OneToOne(targetEntity="Patient", inversedBy="appointment")
	 * @JoinColumn(name="patient_id", referencedColumnName="id")
     */
	public $patient;
	
}

?>