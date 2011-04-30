<?php
namespace tests\vo;

use Doctrine\Common\Collections\ArrayCollection;

/** 
 * @Entity 
 */
class Student {
	
	/**
     * @Id @Column(type="integer")
     * @GeneratedValue(strategy="AUTO")
     */
	public $id;
	
	/** 
	 * @Column(type="string", length=255) 
	 */
	public $name;

	/**
     * @ManyToOne(targetEntity="Country")
     */
    public $country;
	
	/**
	 * @OneToMany(targetEntity="Mark", mappedBy="student")
	 */
	public $marks;
	
	/**
	 * @OneToOne(targetEntity="Photo")
	 */
	public $photo;
    
    public function __construct() {
    	$this->marks = new ArrayCollection();
    }
	
}