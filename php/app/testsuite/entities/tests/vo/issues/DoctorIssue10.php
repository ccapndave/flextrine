<?php
namespace tests\vo\issues;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class DoctorIssue10 {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $identifier;
	
    /** @Column(length=100, type="string") */
    public $name;
	
	public function __construct() {
		
	}
	
}

?>