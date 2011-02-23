<?php
namespace tests\vo\cookbook\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 * @Table(name="cookbook_garden")
 */
class Garden {
	
	/** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
	public $id;
	
	/** @Column(length=50, type="string") */
	public $name;
	
	/** @Column(type="integer") */
	public $area;
	
	/** @Column(type="date", nullable=true) */
	public $grassLastCutDate;
	
	/**
	 * @OneToMany(targetEntity="Tree", mappedBy="garden")
	 */
	public $trees;
	
	public function __construct() {
		$this->trees = new ArrayCollection();
	}
	
}
?>