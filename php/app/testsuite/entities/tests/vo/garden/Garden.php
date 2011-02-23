<?php
namespace tests\vo\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Garden {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(length=100, type="string") */
    public $name;
	
    /**
     * @OneToMany(targetEntity="Tree", mappedBy="garden")
     */
	public $trees;
	
	/**
     * @OneToMany(targetEntity="Flower", mappedBy="garden")
     */
	public $flowers;
	
	public function __construct() {
		$this->trees = new ArrayCollection();
	}
	
}

?>