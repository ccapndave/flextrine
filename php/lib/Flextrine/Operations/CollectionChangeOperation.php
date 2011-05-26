<?php
namespace Flextrine\Operations;

class CollectionChangeOperation extends RemoteOperation {
	
	const ADD = "add";
	const REMOVE = "remove";
	//const RESET = "reset";
	
	var $type;
	var $entity;
	var $property;
	var $items;
	
}