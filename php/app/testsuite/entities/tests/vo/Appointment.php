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
     * @ManyToOne(targetEntity="Doctor", inversedBy="appointments")
	 * @JoinColumn(name="doctor_id", referencedColumnName="id")
     */
	public $doctor;
	
	/**
     * @ManyToOne(targetEntity="Patient", inversedBy="appointments")
	 * @JoinColumn(name="patient_id", referencedColumnName="id")
     */
	public $patient;
	
}

?>