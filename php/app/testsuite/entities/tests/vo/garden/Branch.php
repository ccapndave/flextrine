<?php
namespace tests\vo\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Branch {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(type="integer") */
    public $length;
	
    /**
     * @OneToMany(targetEntity="Leaf", mappedBy="branch")
     */
	public $leaves;
	
	/**
     * @ManyToOne(targetEntity="Tree", inversedBy="branches")
     */
	public $tree;
	
	public function __construct() {
		$this->leaves = new ArrayCollection();
	}
	
}

?>