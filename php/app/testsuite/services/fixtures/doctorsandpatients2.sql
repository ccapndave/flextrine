INSERT INTO `doctor` (`id`,`name`) VALUES 
 (1,'Doctor 1'),
 (2,'Doctor 2');

INSERT INTO `patient` (`id`,`doctor_id`,`name`,`address`,`postcode`) VALUES 
 (1,1,'Patient 1',NULL,NULL),
 (2,1,'Patient 2',NULL,NULL),
 (3,1,'Patient 3',NULL,NULL),
 (4,1,'Patient 4',NULL,NULL);
