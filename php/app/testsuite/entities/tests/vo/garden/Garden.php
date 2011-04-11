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
	public function getTrees() { return $this->trees; }
	public function addTree($tree) { $this->trees->add($tree); }
	
	/**
     * @OneToMany(targetEntity="Flower", mappedBy="garden")
     */
	public $flowers;
	
	public function __construct() {
		$this->trees = new ArrayCollection();
	}
	
}