<?php
namespace tests\vo;

/** 
 * @Entity 
 */
class Course {
	
	/**
     * @Id @Column(type="integer")
     * @GeneratedValue(strategy="AUTO")
     */
	public $id;
	
	/** 
	 * @Column(type="string", length=255) 
	 */
	public $name;
	
}