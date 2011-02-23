<?php

namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/**
 * @Entity
 */

class Movie {
	
	/** @Id @Column(type="integer") @GeneratedValue(strategy="IDENTITY") */
	public $id;
	
	/** @Column(length=50, type="string") */
	public $title;
	
	/** 
	 * @ManyToMany(targetEntity="Artist", inversedBy="movies")
	 */
	public $artists;
	
	public function __construct() {
		$this->artists = new ArrayCollection();
	}
	
}

?>