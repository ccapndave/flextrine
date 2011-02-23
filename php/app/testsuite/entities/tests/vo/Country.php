<?php
namespace tests\vo; 

use Doctrine\Common\Collections\ArrayCollection;

/** 
 * @Entity 
 */
class Country {
	
	/**
     * @Id @Column(type="integer")
     * @GeneratedValue(strategy="AUTO")
     */
	public $id;
	
	/** 
	 * @Column(type="string", length=45) 
	 */
	public $name;

}