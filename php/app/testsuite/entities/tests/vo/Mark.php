<?php
namespace tests\vo;

/** 
 * @Entity 
 * @Table(name="mark", uniqueConstraints={@UniqueConstraint(columns={"student_id", "course_id"})}))
 */
class Mark {
	
	/**
     * @Id @Column(type="integer")
     * @GeneratedValue(strategy="AUTO")
     */
	public $id;
	
	 /**
     * @ManyToOne(targetEntity="Student", inversedBy="marks")
     */
	public $student;
	
	/**
     * @ManyToOne(targetEntity="Course")
     */
	public $course;
	
	/** 
	 * @Column(type="decimal") 
	 */
	public $mark;
	
}