<?php
namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/** 
 * @Entity 
 */
class Photo {
	
	/**
     * @Id @Column(type="integer")
     * @GeneratedValue(strategy="AUTO")
     */
	public $id;
	
	/** 
	 * @Column(type="string", length=255) 
	 */
	public $url;
	
    public function __construct() {
    	
    }
	
}