<?php
namespace tests;

use Doctrine\Common\ClassLoader;

$_ENV["FLEXTRINE_ENV"] = "test";

include __DIR__."/../../bootstrap.php";

$loader->registerNamespace("tests", APP_PATH);