<?php

namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Artist {
	
	/** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
	public $id;
	
	/** @Column(length=50, type="string") */
	public $name;
	
	/** @ManyToMany(targetEntity="Movie", mappedBy="artists") */
	public $movies;
	
	public function __construct() {
		$this->movies = new ArrayCollection();
	}
	
}

?>