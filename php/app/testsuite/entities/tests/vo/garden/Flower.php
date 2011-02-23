<?php
namespace tests\vo\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Flower {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
	/**
     * @ManyToOne(targetEntity="Garden", inversedBy="flowers")
     */
	public $garden;
	
	public function __construct() {
		
	}
	
}

?>