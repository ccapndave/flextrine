<?php
namespace tests\vo\cookbook\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 * @Table(name="cookbook_tree")
 */
class Tree {
	
	/** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
	public $id;
	
	/** @Column(length=50, type="string") */
	public $name;
	
	/** @Column(type="integer") */
	public $age;
	
	/** @Column(type="boolean") */
	public $isFlowering;
	
	/**
	 * @ManyToOne(targetEntity="Garden", inversedBy="trees")
	 */
	public $garden;
	
	public function __construct() {
		
	}
	
}
