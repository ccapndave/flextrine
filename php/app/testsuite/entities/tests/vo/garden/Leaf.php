<?php
namespace tests\vo\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Leaf {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
	/**
     * @ManyToOne(targetEntity="Branch", inversedBy="leaves")
     */
	public $branch;
	
	public function __construct() {
		
	}
	
}

?>