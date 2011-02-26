<?php
include "../app/bootstrap.php";

if (Zend_Registry::isRegistered("em")) {
	$helperSet = new \Symfony\Component\Console\Helper\HelperSet(array(
	    'db' => new \Doctrine\DBAL\Tools\Console\Helper\ConnectionHelper(Zend_Registry::get("em")->getConnection()),
	    'em' => new \Doctrine\ORM\Tools\Console\Helper\EntityManagerHelper(Zend_Registry::get("em")),
	));
}