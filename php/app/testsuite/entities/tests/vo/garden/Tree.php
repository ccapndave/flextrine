<?php
namespace tests\vo\garden;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Tree {
	
    /** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
    public $id;
	
    /** @Column(length=100, type="string") */
    public $type;
    public function getType() { return $this->type; }
    public function setType($type) { $this->type = $type; }
	
    /**
     * @OneToMany(targetEntity="Branch", mappedBy="tree")
     */
	public $branches;
	
	/**
     * @ManyToOne(targetEntity="Garden", inversedBy="trees")
     */
	public $garden;
	public function getGarden() { return $this->garden; }
	public function setGarden($garden) { $this->garden = $garden; }
	
	public function __construct() {
		$this->branches = new ArrayCollection();
	}
	
}

?>